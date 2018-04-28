module game.replay.replay;

/* Replay: Holds all history for a game, but not the physical map.
 *
 * The game relies on the players in the replay to map PlNrs to Styles.
 * The game or the game's Nurse uses the Style to look up the Tribe.
 * The Tribe is a team, and the game thinks in terms of Tribes, not PlNrs.
 */

import core.stdc.string; // memmove
import std.array;
import std.algorithm; // isSorted
import std.range;
import optional;

public import net.ac;
public import net.style;
public import net.repdata;

import basics.help; // array.len of type int
import basics.globals;
import basics.globconf : userName;
import basics.user;
import net.permu;
import net.versioning;
import game.replay.io;
import file.date;
import file.filename;
import level.level;
import level.metadata;

class Replay {
    static struct Player {
        Style style;
        string name;
    }

package:
    Version _gameVersionRequired;
    Player[PlNr] _players;
    Permu _permu; // contains natural numbers [0 .. #players[, not the plNrs
    ReplayData[] _data;

public:
    Date levelBuiltRequired;
    Optional!Filename levelFilename; // null always legal, usually multiplayer

    static newForLevel(Filename levFn, Date levBuilt)
    {
        return new this(levFn, levBuilt, null);
    }

    static loadFromFile(Filename loadFrom)
    {
        return new this(null, null, loadFrom);
    }

    auto clone() const { return new Replay(this); }
    this(in typeof(this) rhs)
    {
        _gameVersionRequired = rhs._gameVersionRequired;
        levelBuiltRequired   = rhs.levelBuiltRequired;
        levelFilename        = rhs.levelFilename;
        _permu               = rhs._permu.clone();
        _data                = rhs._data.dup;

        assert (! _players.length);
        rhs._players.byKeyValue.each!(a => _players[a.key] = a.value);
    }

private:
    // DTODONULLABLE: Take Optional!Filename levFn
    this(Filename levFn, Date levBuilt, Filename loadFrom)
    {
        touch();
        _permu = new Permu("0");
        if (loadFrom) {
            auto loaded = this.implLoadFromFile(loadFrom);
            levelFilename = loaded.levelFilename;
            levelBuiltRequired = loaded.levelBuiltRequired;
        }
        else {
            levelFilename = levFn ? some(levFn) : Optional!Filename();
            levelBuiltRequired = levBuilt;
        }
    }

public:
    // == ignores levelBuiltRequired and _gameVersionRequired.
    // I'm not sure how good that decision is. The idea is that replays
    // will behave identically anyway even when those differ.
    override bool opEquals(Object rhsObj)
    {
        if (const rhs = cast(const(Replay)) rhsObj)
            return _data == rhs._data
                && cast(const(Player[PlNr])) _players == rhs._players
                && _permu == rhs._permu
                && levelFilename == rhs.levelFilename;
        else
            return false;
    }

    @property const @nogc nothrow {
        Version gameVersionRequired() { return _gameVersionRequired; }
        int numPlayers() { return _players.length & 0x7FFF_FFFF; }
        const(Player[PlNr]) players() { return _players; }
        const(Permu) permu() { return _permu; }
        bool empty() { return _data.length == 0; }
        int latestPhyu() { return (_data.length > 0) ? _data[$-1].update : 0; }
    }

    @property Permu permu(Permu p) { _permu = p; return p; }

    @property string styleToNames(in Style st) const
    {
        auto range = _players.byValue.filter!(p => p.style == st)
                                     .map!(p => p.name);
        switch (range.walkLength) {
            case 0: return "";
            case 1: return range.front;
            default: return range.join(", ");
        }
    }

    Style plNrToStyle(in PlNr plNr) const
    {
        if (auto pl = plNr in _players)
            return pl.style;
        return Style.garden;
    }

    // Allocates and returns a new array with the report
    Style[] stylesInUse() const
    {
        Style[] ret;
        foreach (style; _players.byValue.map!(pl => pl.style))
            if (! ret.canFind(style))
                ret ~= style;
        ret.sort();
        return ret;
    }

    void touch()
    {
        _gameVersionRequired = gameVersion();
        if (_players.length == 1) {
            foreach (ref Player pl; _players)
                pl.name = userName;
        }
    }

    void addPlayer(PlNr nr, Style st, string name)
    {
        _players[nr] = Player(st, name);
    }

    // This doesn't check whether the metadata/general data is the same.
    // We assume that Game only calls this on replays of the same level.
    // "Before" is exclusive, you might want to pass Phyu(now + 1).
    bool equalBefore(in Replay rhs, in Phyu before) const @nogc nothrow
    in {
        assert (rhs !is null);
    }
    body {
        return dataSliceBeforePhyu(before) == rhs.dataSliceBeforePhyu(before);
    }

    void eraseEarlySingleplayerNukes()
    {
        // Game updates nukes, then spawns, then lix perform.
        enum beforePhyu = 61; // Not 60, only nuke if it kills lix.
        if (_players.length > 1)
            return;
        for (int i = 0; i < _data.length; ++i) {
            if (_data[i].update >= beforePhyu)
                break;
            else if (_data[i].action == RepAc.NUKE) {
                _data = _data[0 .. i] ~ _data[i+1 .. $];
                --i;
            }
        }
        // doesn't call touch(), because it's housekeeping
    }

    /*
     * Multiplayer: Accidental drops should ideally send nukes for those
     * players, but that's not handled here. That should be implemented
     * by the server.
     * Singleplayer: Call this function on exiting with ESC during play
     * to ensure, for style, that all replays end with a nuke.
     * Existing nukes in the replay take priority
     */
    void terminateSingleplayerWithNukeAfter(in Phyu lastActionsToKeep)
    {
        if (_players.length != 1
            || _data.canFind!(rd => rd.action == RepAc.NUKE))
            return;
        deleteAfterPhyu(lastActionsToKeep);

        ReplayData termNuke = ReplayData();
        termNuke.player = _players.byKey.front;
        termNuke.update = Phyu(lastActionsToKeep + 1);
        termNuke.action = RepAc.NUKE;
        add(termNuke);
    }

    void deleteAfterPhyu(in Phyu upd)
    {
        assert (upd >= 0);
        _data = _data[0 .. dataSliceBeforePhyu(Phyu(upd + 1)).length];
        touch();
    }

    const(ReplayData)[] getDataForPhyu(in Phyu upd) const
    {
        auto slice = dataSliceBeforePhyu(Phyu(upd + 1));
        int firstGood = slice.len;
        while (firstGood > 0 && slice[firstGood - 1].update == upd)
            --firstGood;
        assert (firstGood >= 0);
        assert (firstGood <= slice.length);
        return _data[firstGood .. slice.length];
    }

    bool getOnPhyuLixClicked(in Phyu upd, in int lix_id, in Ac ac) const
    {
        auto vec = getDataForPhyu(upd);
        foreach (const ref d; vec)
            if (d.isSomeAssignment && d.toWhichLix == lix_id && d.skill == ac)
                return true;
        return false;
    }

    void add(in ReplayData d)
    {
        touch();
        this.addWithoutTouching(d);
    }

    void saveManually(in Level lev) const
    {
        this.implSaveToFile(manualSaveFilename(), lev);
    }

    bool shouldWeAutoSave() const
    {
        return _players.length > 1
            ? replayAutoMulti.value
            : replayAutoSolutions.value;
    }

    void saveAsAutoReplay(in Level lev) const
    {
        if (! shouldWeAutoSave)
            return;
        this.implSaveToFile(autoSaveFilename(), lev);
    }

    VfsFilename manualSaveFilename() const
    {
        return this.saveFilenameCustomBase(dirReplayManual);
    }

    VfsFilename autoSaveFilename() const
    {
        return this.saveFilenameCustomBase(
            _players.length > 1 ? dirReplayAutoMulti : dirReplayAutoSolutions);
    }

package:
    inout(ReplayData)[] dataSliceBeforePhyu(in Phyu upd) @nogc nothrow inout
    {
        // The binary search algo works also for this case.
        // But we add mostly to the end of the data, so check here for speed.
        if (_data.length == 0 || _data[$-1].update < upd)
            return _data;

        int bot = 0;         // first too-large is at a higher position
        int top = _data.len; // first too-large is here or at a lower position

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

    void addWithoutTouching(in ReplayData d)
    {
        // Add after the latest record that's smaller than or equal to d
        // Equivalently, add before the earliest record that's greater than d.
        // dataSliceBeforePhyu doesn't do exactly that, it ignores players.
        // I believe the C++ version had a bug in the comparison. Fixed here.
        auto slice = dataSliceBeforePhyu(Phyu(d.update + 1));
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
}

unittest {
    Replay a = Replay.newForLevel(null, null);
    Replay b = Replay.newForLevel(null, null);
    ReplayData d;
    d.skill = Ac.digger;
    d.toWhichLix = 50;
    d.update = Phyu(20);
    a.add(d);
    b.add(d);
    d.skill = Ac.builder;
    d.update = Phyu(5);
    a.add(d);
    assert (! a.equalBefore(b, Phyu(30)));
    assert (! b.equalBefore(a, Phyu(30)));
    b.add(d);
    assert (a.equalBefore(b, Phyu(30)));
    assert (b.equalBefore(a, Phyu(30)));

    d.skill = Ac.basher;
    d.update = Phyu(10);
    b.add(d);
    assert (! a.equalBefore(b, Phyu(30)));
    assert (! b.equalBefore(a, Phyu(30)));
    assert (a.equalBefore(b, Phyu(10)));
    assert (b.equalBefore(a, Phyu(10)));
}
