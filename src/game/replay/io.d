module game.replay.io;

import std.algorithm;
import std.file; // mkdirRecurse
import std.stdio; // save file, and needed for unittest
import std.string;

import basics.help;
import basics.nettypes;
import basics.globals;
import basics.versioning;
import file.date;
import file.filename;
import file.io;
import file.log;
import game.replay.replay;
import level.level;
import lix.enums;

static import basics.user;

package:

nothrow void implSaveToFile(
    in Replay replay,
    in Filename fn,
    in Level lev
) {
    try {
        std.file.mkdirRecurse(fn.dirRootful);
        std.stdio.File file = File(fn.rootful, "w");
        saveToStdioFile(replay, file, lev);
    }
    catch (Exception e) {
        log(e.msg);
    }
}

void implSaveAsAutoReplay(
    in Replay replay,
    in Level lev,
    bool solves
) {
    immutable bool multi = (replay._players.length > 1);
    if (multi && basics.user.replayAutoMulti.value)
        replay.saveToTree(basics.globals.dirReplayAutoMulti, lev);
    if (! multi && solves && basics.user.replayAutoSolutions.value)
        replay.saveToTree(basics.globals.dirReplayAutoSolutions, lev);
}

void implSaveManually(in Replay replay, in Level lev)
{
    replay.saveToTree(basics.globals.dirReplayManual, lev);
}

auto implLoadFromFile(Replay replay, Filename fn) { with (replay)
{
    struct Return {
        MutFilename levelFilename;
        MutableDate levelBuiltRequired;
    }
    auto ret = Return(MutFilename(nullFilename),
                      MutableDate(new Date("0")));
    IoLine[] lines;
    try {
        lines = fillVectorFromFile(fn);
    }
    catch (Exception e) {
        log(e.msg);
        _fileNotFound = true;
        return ret;
    }
    foreach (i; lines) switch (i.type) {
    case '$':
        if (i.text1 == replayLevelBuiltRequired)
            ret.levelBuiltRequired = new Date(i.text2);
        else if (i.text1 == replayPermu)
            _permu = new Permu(i.text2);
        else if (i.text1 == replayGameVersionRequired)
            _gameVersionRequired = Version(i.text2);
        else if (i.text1 == replayLevelFilename)
            ret.levelFilename = new Filename(dirLevels.dirRootless ~ i.text2);
        break;
    case '+':
        if (i.text1 == replayPlayer || i.text1 == replayFriend) {
            addPlayer(PlNr(i.nr1 & 0xFF), stringToStyle(i.text2), i.text3);
            if (i.text1 == replayPlayer)
                playerLocal = PlNr(i.nr1 & 0xFF);
        }
        break;
    case '!': {
        // replays contain ASSIGN=BASHER or ASSIGN_RIGHT=BUILDER.
        // cut these strings into a left and right part, none contains '='.
        string part1 = "";
        string part2 = i.text1;
        while (part2.length && part2[0] != '=')
            part2 = part2[1 .. $];
        part1 = i.text1[0 .. i.text1.length - part2.length];
        if (part2.length > 0)
            // remove '='
            part2 = part2[1 .. $];

        ReplayData d;
        d.update     = i.nr1;
        d.player     = i.nr2 & 0xFF;
        d.toWhichLix = i.nr3;
        d.action = part1 == replayAssignAny   ? RepAc.ASSIGN
                 : part1 == replayAssignLeft  ? RepAc.ASSIGN_LEFT
                 : part1 == replayAssignRight ? RepAc.ASSIGN_RIGHT
                 : part1 == replayNuke        ? RepAc.NUKE
                 : RepAc.NOTHING;
        if (part2.length > 0)
            d.skill = stringToAc(part2);
        if (d.action != RepAc.NOTHING)
            addWithoutTouching(d);
        break; }
    default:
        break;
    }
    return ret;
}}

// ############################################################################

private:

void saveToStdioFile(
    in Replay replay,
    std.stdio.File file,
    in Level lev) { with (replay)
{
    file.writeln(IoLine.Dollar(basics.globals.replayLevelFilename,
        replay.mangledLevelFilename));
    if (levelBuiltRequired !is null)
        file.writeln(IoLine.Dollar(replayLevelBuiltRequired,
            levelBuiltRequired.toString));
    file.writeln(IoLine.Dollar(replayGameVersionRequired,
        _gameVersionRequired.toString));

    if (_players.length)
        file.writeln();
    foreach (pl; _players)
        file.writeln(IoLine.Plus(pl.number == playerLocal
             ? basics.globals.replayPlayer : basics.globals.replayFriend,
             pl.number, styleToString(pl.style), pl.name));
    if (_players.length > 1)
        file.writeln(IoLine.Dollar(replayPermu, permu.toString));

    if (_data.length)
        file.writeln();
    foreach (d; _data) {
        string word
            = d.action == RepAc.NUKE         ? replayNuke
            : d.action == RepAc.ASSIGN       ? replayAssignAny
            : d.action == RepAc.ASSIGN_LEFT  ? replayAssignLeft
            : d.action == RepAc.ASSIGN_RIGHT ? replayAssignRight : "";
        if (word == "")
            throw new Exception("bad replay data written to file");
        if (d.isSomeAssignment) {
            word ~= "=";
            word ~= acToString(cast (Ac) d.skill);
        }
        file.writeln(IoLine.Bang(d.update, d.player, word, d.toWhichLix));
    }

    bool okToSave(in Level lev)
    {
        return lev !is null && lev.nonempty;
    }

    const(Level) levToSave = okToSave(lev) ? lev
                             : new Level(levelFilename);
    if (okToSave(levToSave)) {
        file.writeln();
        level.level.saveToFile(levToSave, file);
    }
}}

string mangledLevelFilename(in Replay replay)
{
    // Write the path to the level, but omit the leading (dir-levels)/
    // DTODOFHS: we chop off a constant length, we shouldn't do that
    // anymore once we don't know where it's saved
    if (dirLevels.rootless.length >= replay.levelFilename.rootless.length)
        return null;
    return replay.levelFilename.rootless[dirLevels.rootless.length .. $];
}

void saveToTree(
    in Replay   replay,
    in Filename treebase,
    in Level lev
) {
    string outfile = "%s%s%s-%s-%s%s".format(
        treebase.rootful,
        replay.mimickLevelPath(),
        replay.levelFilename ? replay.levelFilename.fileNoExtNoPre : "unknown",
        replay.playerLocalName.escapeStringForFilename(),
        Date.now().toStringForFilename(),
        basics.globals.filenameExtReplay);
    replay.implSaveToFile(new Filename(outfile), lev);
}

string mimickLevelPath(in Replay replay)
out (result) {
    assert (result == "" || result[0]   != '/');
    assert (result == "" || result[$-1] == '/');
}
body {
    // DTODOFHS: Is this still good? See comment in mangledLevelFilename, too.
    void cutFront(ref string str, in string front)
    {
        if (str.length >= front.length && str[0 .. front.length] == front)
            str = str[front.length .. $];
    }
    if (! replay || ! replay.levelFilename)
        return "";
    string path = replay.levelFilename.dirRootless;
    [   dirLevelsSingle, dirLevelsNetwork, dirLevels,
        dirReplayAutoSolutions, dirReplayAutoMulti, dirReplayManual, dirReplays
        ].each!(dir => cutFront(path, dir.dirRootless));
    return path;
}

unittest
{
    Filename fn0 = new Filename("./replays/unittest-input.txt");
    Filename fn1 = new Filename("./replays/unittest-output-1.txt");
    Filename fn2 = new Filename("./replays/unittest-output-2.txt");
    Filename fnl = new Filename("./replays/unittest-output-level.txt");

    try {
        auto file = std.stdio.File(fn0.rootful, "w");
        file.write(
            "! 387 0 ASSIGN=JUMPER 0\n"
            "! 268 0 ASSIGN=JUMPER 0\n"
            "! 125 0 ASSIGN=CLIMBER 0\n"
            "! 506 0 ASSIGN=BLOCKER 0\n"
            "! 489 0 ASSIGN=BASHER 0\n");
    }
    catch (Exception)
        return;

    Level lev = new Level(fn0);
    lev.saveToFile(fnl);

    Replay r = Replay.loadFromFile(fn0);
    const int data_len = r._data.len;

    implSaveToFile(r, fn1, lev);
    r = Replay.loadFromFile(fn1);
    assert (data_len == r._data.len);

    implSaveToFile(r, fn2, lev);
    [fn0, fn1, fn2, fnl].map!(f => f.rootful).each!(std.file.remove);
}
