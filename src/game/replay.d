module game.replay;

import std.algorithm; // isSorted
import std.file : mkdirRecurse;
import std.c.string : memmove;
import std.stdio;
import std.string;

import basics.help; // array.len of type int
import basics.globals;
import basics.globconf;
import basics.help;
import basics.nettypes;
import basics.versioning;
import file.date;
import file.filename;
import file.io;
import file.log;
import level.level;
import level.metadata;
import lix.enums;

class Replay {

    static struct Player {
        PlNr   number;
        Style  style;
        string name;
    }

private:

    private bool _fileNotFound;

    Version  _gameVersionRequired;

    Player[] _players;
    Permu    _permu;

    ReplayData[] _data;

public:

    Date     levelBuiltRequired;
    Filename levelFilename;

    PlNr     playerLocal;

    @property fileNotFound() const        { return _fileNotFound;        }
    @property gameVersionRequired() const { return _gameVersionRequired; }

    @property const(Player)[] players() const  { return _players;      }
    @property const(Permu)    permu()   const  { return _permu;        }
    @property       Permu     permu(Permu p)   { _permu = p; return p; }

    @property int latestUpdate() const
    {
        return (_data.length > 0) ? _data[$-1].update : 0;
    }

    @property string playerLocalName()
    {
        foreach (pl; _players)
            if (pl.number == playerLocal)
                return pl.name;
        return null;
    }

    @property string canonicalSaveFilename()
    {
        string base = levelFilename.fileNoExtNoPre;
        string plna = this.playerLocalName;
        return plna.length ? base ~ "-" ~ plna : base;
    }



this(Filename loadFrom = null)
{
    touch();
    levelBuiltRequired = new Date("0");
    levelFilename      = loadFrom ? loadFrom : new Filename("");
    _permu             = new Permu(1);

    if (loadFrom)
        this.loadFromFile(loadFrom);
}



pure Replay clone() const
{
    return new Replay(this);
}

pure this(in Replay rhs)
{
    _fileNotFound        = rhs._fileNotFound;
    _gameVersionRequired = rhs._gameVersionRequired;

    levelBuiltRequired   = rhs.levelBuiltRequired.clone();
    levelFilename        = rhs.levelFilename.clone();
    playerLocal          = rhs.playerLocal;

    _players             = rhs._players.dup;
    _permu               = rhs._permu.clone();
    _data                = rhs._data.dup;
}



void touch()
{
    _gameVersionRequired = gameVersion();
    _fileNotFound = false;
}



void
addPlayer(PlNr nr, Style s, string name)
{
    _players ~= Player(nr, s, name);
}



private inout(ReplayData)[]
dataSliceBeforeUpdate(in int upd) inout
{
    // The binary search algo works also for the cases we're checking in this
    // if. But we add mostly to the end of the data, so check here for speed.
    if (_data.length == 0 || _data[$-1].update < upd)
        return _data;

    int bot = 0;         // first too-large is at a higher position than this
    int top = _data.len; // first too-large is here _or_ at a lower position

    while (top != bot) {
        int bisect = (top + bot) / 2;
        assert (bisect >= 0   && bisect < _data.len);
        assert (bisect >= bot && bisect < top);
        if (_data[bisect].update < upd)
            bot = bisect + 1;
        if (_data[bisect].update >= upd)
            top = bisect;
    }
    return _data[0 .. bot];
}



bool
equalBefore(in typeof(this) rhs, in int upd) const
{
    // We don't check whether the metadata/general data is the same.
    // We assume the gameplay class only uses for replays of the same level
    // with the same players.
    return this.dataSliceBeforeUpdate(upd)
        ==  rhs.dataSliceBeforeUpdate(upd);
}



// this function is necessary to keep old replays working in new versions
// that skip the first 30 or so updates, to get into the action faster.
// The first spawn is still at update 60.
void
increaseEarlyDataToUpdate(in int upd)
{
    foreach (d; _data) {
        if (d.update < upd)
            d.update = upd;
        else break;
    }
    // This doesn't call touch().
}



void
deleteOnAndAfterUpdate(in int upd)
{
    assert (upd >= 0);
    _data = _data[0 .. dataSliceBeforeUpdate(upd).length];
    touch();
}



const(ReplayData)[]
getDataForUpdate(in int upd) const
{
    auto slice = dataSliceBeforeUpdate(upd + 1);
    int firstGood = slice.len;
    while (firstGood > 0 && slice[firstGood - 1].update == upd)
        --firstGood;
    assert (firstGood >= 0);
    assert (firstGood <= slice.length);
    return _data[firstGood .. slice.length];
}



bool
getOnUpdateLixClicked(in int upd, in int lix_id, in Ac ac) const
{
    auto vec = getDataForUpdate(upd);
    foreach (const ref d; vec)
        if (d.isSomeAssignment && d.toWhichLix == lix_id && d.skill == ac)
            return true;
    return false;
}



void
add(in ReplayData d)
{
    touch();
    addWithoutTouching(d);
}



private void
addWithoutTouching(in ReplayData d)
{
    // Add after the latest record that's smaller than or equal to d
    // Equivalently, add before the earliest record that's greater than d.
    // dataSliceBeforeUpdate doesn't do exactly that, it ignores players.
    // DTODO: I believe the C++ version had a bug in the choice of
    // comparison. I have fixed that here. Test to see if it's good now.
    auto slice = dataSliceBeforeUpdate(d.update + 1);
    while (slice.length && slice[$-1] > d)
        slice = slice[0 .. $-1];

    if (slice.length < _data.length) {
        _data.length += 1;
        memmove(&_data[slice.length + 1], &_data[slice.length],
                ReplayData.sizeof * (_data.length - slice.length - 1));
        _data[slice.length] = d;
    }
    else {
        _data ~= d;
    }

    assert (_data.isSorted);
}



// ############################################################################
// ################################################################# Replay I/O
// ############################################################################



public nothrow void
saveToFile(in Filename fn, in Level lev)
{
    try {
        std.file.mkdirRecurse(fn.dirRootful);
        std.stdio.File file = File(fn.rootful, "w");
        scope (exit)
            file.close();
        saveToFile(file, lev);
    }
    catch (Exception e) {
        log(e.msg);
    }
}



private string
mangledLevelFilename()
{
    // Write the path to the level, but omit the leading (dir-levels)/
    // DTODOFHS: we chop off a constant length, we shouldn't do that
    // anymore once we don't know where it's saved
    if (dirLevels.rootless.length >= levelFilename.rootless.length)
        return null;
    return levelFilename.rootless[dirLevels.rootless.length .. $];
}



private void
saveToFile(std.stdio.File file, in Level lev)
{
    file.writeln(IoLine.Dollar(basics.globals.replayLevelFilename,
        mangledLevelFilename));
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
            = d.action == RepAc.SPAWNINT     ? replaySpawnint
            : d.action == RepAc.NUKE         ? replayNuke
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
}



public void
saveAsAutoReplay(in Level lev, bool isSolution)
{
    immutable bool multi = (_players.length > 1);
    if (     multi &&                 ! basics.user.replayAutoMulti
        || ! multi && ! isSolution && ! basics.user.replayAutoSingleFailures
        || ! multi &&   isSolution && ! basics.user.replayAutoSingleSolutions
    )
        return;

    string outfile
        = multi      ? basics.globals.dirReplayAutoMulti.rootful
        : isSolution ? basics.globals.dirReplayAutoSingleSolutions.rootful
                     : basics.globals.dirReplayAutoSingleFailures.rootful;
    outfile ~= lev.name.escapeStringForFilename()
        ~ "-" ~ playerLocalName.escapeStringForFilename()
        ~ "-" ~ Date.now().toStringForFilename()
        ~ basics.globals.filenameExtReplay;
    saveToFile(new Filename(outfile), lev);
}



private void
loadFromFile(Filename fn)
{
    IoLine[] lines;
    try {
        lines = fillVectorFromFile(fn);
    }
    catch (Exception e) {
        log(e.msg);
        _fileNotFound = true;
        return;
    }

    foreach (i; lines) switch (i.type) {
    case '$':
        if (i.text1 == replayLevelBuiltRequired) {
            levelBuiltRequired = new Date(i.text2);
        }
        else if (i.text1 == replayPermu) {
            _permu = new Permu(i.text2);
        }
        else if (i.text1 == replayGameVersionRequired) {
            _gameVersionRequired = Version(i.text2);
        }
        else if (i.text1 == replayLevelFilename) {
            levelFilename = new Filename(dirLevels.dirRootless ~ i.text2);
        }
        break;

    case '+':
        if (   i.text1 == replayPlayer
            || i.text1 == replayFriend
        ) {
            addPlayer(i.nr1 & 0xFF, stringToStyle(i.text2), i.text3);
            if (i.text1 == replayPlayer)
                playerLocal = i.nr1 & 0xFF;
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
        d.update       = i.nr1;
        d.player       = i.nr2 & 0xFF;
        d.toWhichLix = i.nr3;
        d.action = part1 == replaySpawnint    ? RepAc.SPAWNINT
                 : part1 == replayAssignAny   ? RepAc.ASSIGN
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
    // end switch and foreach
}

}
// end class Replay



unittest
{
    Filename fn0 = new Filename("./replays/unittest-input.txt");
    Filename fn1 = new Filename("./replays/unittest-output-1.txt");
    Filename fn2 = new Filename("./replays/unittest-output-2.txt");
    Filename fnl = new Filename("./replays/unittest-output-level.txt");

    Level lev = new Level(fn0);
    lev.saveToFile(fnl);

    Replay r = new Replay(fn0);
    const int data_len = r._data.len;

    r.saveToFile(fn1, lev);
    r = new Replay(fn1);
    assert (data_len == r._data.len);

    r.saveToFile(fn2, lev);
}
