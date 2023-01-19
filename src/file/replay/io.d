module file.replay.io;

/*
 * Replay writing/loading.
 * Don't import this module during interactive or noninteractive program runs.
 * Import file.replay instead.
 * Import file.replay.io only during unittests in other modules.
 */

import std.algorithm;
import std.stdio; // save file, and needed for unittest
import optional;

import basics.help;
import basics.globals;
import file.date;
import file.filename;
import file.io;
import file.log;
import file.option : userName; // for filename during saving
import file.replay.playerio;
import file.replay.replay;
import file.replay.tweakimp;
import level.level;
import net.permu;
import net.profile;
import net.repdata;
import net.versioning;

public: // public only to unittest. Should be package outside of that.

nothrow void implSaveToFile(
    in Replay replay,
    in Filename fn,
    in Level lev
) {
    try {
        std.stdio.File file = fn.openForWriting();
        saveToStdioFile(replay, file, lev);
    }
    catch (Exception e)
        log(e.msg);
}

package:

VfsFilename saveFilenameCustomBase(
    in Replay replay,
    in Filename treebase
) {
    import std.format;
    return replay.levelFilename.match!(
        (fn) => new VfsFilename(format!"%s%s%s-%s-%s%s"(
            treebase.rootless,
            mimickLevelPath(fn),
            fn.fileNoExtNoPre,
            userName.escapeStringForFilename(),
            Date.now().toStringForFilename(),
            basics.globals.filenameExtReplay)),
        () => new VfsFilename(format!"%s%s-%s-%dp%s"(
            treebase.rootless,
            Date.now().toStringForFilename(),
            userName.escapeStringForFilename(),
            replay._players.length,
            basics.globals.filenameExtReplay)));
}

// Input: Filename to a level.
// Output: Filename to a subdirectory of the replays.
string mimickLevelPath(in Filename fn)
out (result) {
    assert (result == "" || result[0]   != '/');
    assert (result == "" || result[$-1] == '/');
}
do {
    // DTODOFHS: Is this still good? See comment in mangledLevelFilename, too.
    void cutFront(ref string str, in string front)
    {
        if (str.length >= front.length && str[0 .. front.length] == front)
            str = str[front.length .. $];
    }
    string path = fn.dirRootless;
    [   dirLevelsSingle, dirLevelsNetwork, dirLevels,
        dirReplayAutoSolutions, dirReplayAutoMulti, dirReplayManual, dirReplays
        ].each!(dir => cutFront(path, dir.dirRootless));
    return path;
}

void implLoadFromFile(Replay replay, Filename fn) { with (replay)
{
    IoLine[] lines;
    try {
        lines = fillVectorFromFile(fn);
    }
    catch (Exception e) {
        log(e.msg);
        return;
    }

    ProfileImporter importer;
    foreach (i; lines) switch (i.type) {
    case '$':
        if (i.text1 == replayLevelBuiltRequired)
            _levelBuiltRequired = new Date(i.text2);
        else if (i.text1 == replayPermu)
            _permu = new Permu(i.text2);
        else if (i.text1 == replayGameVersionRequired)
            _gameVersionRequired = Version(i.text2);
        else if (i.text1 == replayLevelFilename)
            levelFilename = new VfsFilename(dirLevels.dirRootless ~ i.text2);
        break;
    case '+':
        importer.parse(i);
        break;
    case '!': {
        // replays contain ASSIGN=BASHER or ASSIGN_RIGHT=BUILDER.
        auto iSplit = std.algorithm.splitter(i.text1, '=');
        if (iSplit.empty)
            break;
        string assign = iSplit.front;
        iSplit.popFront;
        string skill = iSplit.empty ? "" : iSplit.front;

        Ply d;
        d.when = i.nr1;
        d.by = i.nr2 & 0xFF;
        d.toWhichLix = i.nr3;
        d.fromRepAc(assign == replayAssignAny  ? RepAc.ASSIGN
                 : assign == replayAssignLeft  ? RepAc.ASSIGN_LEFT
                 : assign == replayAssignRight ? RepAc.ASSIGN_RIGHT
                 : assign == replayNuke        ? RepAc.NUKE
                 : RepAc.NOTHING);
        d.skill = skill.stringToAc;
        if (d.skill != Ac.max || d.isNuke) {
            replay.addWithoutTouching(d);
        }
        break; }
    default:
        break;
    }
    _players = importer.loseOwnershipOfProfileArray();
}}

// ############################################################################

private:

void saveToStdioFile(
    in Replay replay,
    std.stdio.File file,
    in Level lev) { with (replay)
{
    foreach (lfn; replay.levelFilename)
        file.writeln(IoLine.Dollar(basics.globals.replayLevelFilename,
            mangledLevelFilename(lfn)));
    file.writeln(IoLine.Dollar(replayLevelBuiltRequired,
        _levelBuiltRequired.toString));
    file.writeln(IoLine.Dollar(replayGameVersionRequired,
        _gameVersionRequired.toString));

    if (_players.length) {
        file.writeln();
        foreach (ioLine; ProfileExporter(_players)) {
            file.writeln(ioLine);
        }
        if (_players.length > 1)
            file.writeln(IoLine.Dollar(replayPermu, permu.toString));
    }

    if (_plies.length)
        file.writeln();
    foreach (d; _plies) {
        immutable RepAc action = d.toRepAc;
        string word
            = action == RepAc.NUKE         ? replayNuke
            : action == RepAc.ASSIGN       ? replayAssignAny
            : action == RepAc.ASSIGN_LEFT  ? replayAssignLeft
            : action == RepAc.ASSIGN_RIGHT ? replayAssignRight : "";
        if (word == "")
            throw new Exception("bad replay data written to file");
        if (d.isAssignment) {
            word = word ~ "=" ~ acToString(d.skill);
        }
        file.writeln(IoLine.Bang(d.when, d.by, word, d.toWhichLix));
    }

    bool okToSave(in Level l)
    {
        return ! l.errorFileNotFound && ! l.errorEmpty;
    }
    Optional!(const Level) levToSave
        = lev ? some(lev) // lev should always be non-null. ?:?: guards legacy.
        : levelFilename.match!(
            (fn) => some!(const Level)(new Level(fn)),
            () => no!(const Level));
    levToSave.filter!okToSave.each!((lev) {
        file.writeln();
        assert (! levToSave.empty);
        level.level.saveToFile(levToSave.front, file);
    });
}}

// Input: A replay's level filename
// Output: The path to the level with (dir-levels)/ trimmed from front
string mangledLevelFilename(in Filename fn)
{
    if (dirLevels.rootless.length >= fn.rootless.length)
        return "";
    return fn.rootless[dirLevels.rootless.length .. $];
}

unittest
{
    file.filename.vfsfile.initialize();
    Filename fn0 = new VfsFilename("./replays/unittest-input.txt");
    Filename fn1 = new VfsFilename("./replays/unittest-output-1.txt");
    Filename fn2 = new VfsFilename("./replays/unittest-output-2.txt");
    Filename fnl = new VfsFilename("./replays/unittest-output-level.txt");

    try {
        auto file = fn0.openForWriting();
        // Write 5 lines into the file, we'll assert later that there are 5.
        file.write(
            "! 387 0 ASSIGN=JUMPER 0\n",
            "! 268 0 ASSIGN=JUMPER 0\n",
            "! 125 0 ASSIGN=CLIMBER 0\n",
            "! 506 0 NUKE 0\n",
            "+PLAYER 0 Yellow TestName\n",
            "! 489 0 ASSIGN=BASHER 0\n");
    }
    catch (Exception)
        return;

    Level lev = new Level(fn0);
    lev.saveToFile(fnl);

    void assertReplay(in Replay r)
    {
        assert (r._plies.len == 5);
        assert (r._plies[0].when == 125);
        assert (r._plies[0].skill == Ac.climber);
        assert (r.players.length == 1);
        assert (r.players[PlNr(0)].name == "TestName");
        assert (r.players[PlNr(0)].style == Style.yellow);
    }

    Replay loaded = Replay.loadFromFile(fn0);
    assertReplay(loaded);

    implSaveToFile(loaded, fn1, lev);
    loaded = Replay.loadFromFile(fn1);
    assertReplay(loaded);

    implSaveToFile(loaded, fn2, lev);
    [fn0, fn1, fn2, fnl].each!(f => f.deleteFile);
}
