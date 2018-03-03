module game.replay.io;

import std.algorithm;
import std.stdio; // save file, and needed for unittest

import basics.globconf : userName; // for filename during saving
import basics.help;
import net.repdata;
import basics.globals;
import net.permu;
import net.versioning;
import file.date;
import file.filename;
import file.io;
import file.log;
import game.replay.replay;
import level.level;

package:

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

auto implLoadFromFile(Replay replay, Filename fn) { with (replay)
{
    struct Return {
        MutFilename levelFilename;
        MutableDate levelBuiltRequired;
    }
    auto ret = Return(MutFilename(null),
                      MutableDate(new Date("0")));
    IoLine[] lines;
    try {
        lines = fillVectorFromFile(fn);
    }
    catch (Exception e) {
        log(e.msg);
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
            ret.levelFilename = new VfsFilename(dirLevels.dirRootless ~ i.text2);
        break;
    case '+':
        // For back-compat, we accept the FRIEND directive, even though
        // since March 2018, we only write PLAYER directives.
        if (i.text1 == replayPlayer || i.text1 == replayFriend)
            addPlayer(PlNr(i.nr1 & 0xFF), stringToStyle(i.text2), i.text3);
        break;
    case '!': {
        // replays contain ASSIGN=BASHER or ASSIGN_RIGHT=BUILDER.
        auto iSplit = std.algorithm.splitter(i.text1, '=');
        if (iSplit.empty)
            break;
        string assign = iSplit.front;
        iSplit.popFront;
        string skill = iSplit.empty ? "" : iSplit.front;

        ReplayData d;
        d.update     = i.nr1;
        d.player     = i.nr2 & 0xFF;
        d.toWhichLix = i.nr3;
        d.action = assign == replayAssignAny   ? RepAc.ASSIGN
                 : assign == replayAssignLeft  ? RepAc.ASSIGN_LEFT
                 : assign == replayAssignRight ? RepAc.ASSIGN_RIGHT
                 : assign == replayNuke        ? RepAc.NUKE
                 : RepAc.NOTHING;
        d.skill = skill.stringToAc;
        if (d.action != RepAc.NOTHING
            && (d.skill != Ac.max || ! d.isSomeAssignment))
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
    foreach (plNr, pl; _players)
        file.writeln(IoLine.Plus(basics.globals.replayPlayer,
             plNr, styleToString(pl.style), pl.name));
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
        return lev !is null && ! lev.errorFileNotFound && ! lev.errorEmpty;
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
    if (replay.levelFilename is null
        || dirLevels.rootless.length >= replay.levelFilename.rootless.length)
        return null;
    return replay.levelFilename.rootless[dirLevels.rootless.length .. $];
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
        assert (r._data.len == 5);
        assert (r._data[0].update == 125);
        assert (r._data[0].skill == Ac.climber);
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
