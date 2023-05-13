module file.replay.replay;

/* Replay: Holds all history for a game, but not the physical map.
 *
 * The game relies on the players in the replay to map PlNrs to Styles.
 * The game or the game's Nurse uses the Style to look up the Tribe.
 * The Tribe is a team, and the game thinks in terms of Tribes, not PlNrs.
 */

import std.algorithm;
import std.range;
import optional;

public import file.replay.tweakrq;
public import net.ac;
public import net.style;
public import net.repdata;

import basics.help; // array.len of type int
import basics.globals;
import file.date;
import file.filename;
static import file.option.allopts;
import file.replay.tweakimp;
import file.replay.io;
import level.level;
import net.profile;
import net.permu;
import net.versioning;

class Replay {
package:
    // The pointed-to level filename.
    // May be none, e.g., in networking games.
    // Can't use Optional with Rebindable because of memory corruption, thus
    // the private variable is non-Optional and still accepts null legally,
    // and we have public/package get/set properties called levelFilename
    // that correctly return Optional!Filename.
    MutFilename _levelFnCanBeNullInNetgames;

    // The required date when the level was built. This is useful to check
    // whether a replay plays against the same version of the level against
    // which the replay was recorded originally.
    MutableDate _levelBuiltRequired;

    Version _gameVersionRequired;
    Profile[PlNr] _players;
    Permu _permu; // contains natural numbers [0 .. #styles[, not the plNrs
    Ply[] _plies;

public:
    static newForLevel(Filename levFn, Date levBuilt)
    {
        Replay ret = new Replay();
        ret.levelFilename = levFn;
        ret._levelBuiltRequired = levBuilt;
        return ret;
    }

    static newNoLevelFilename(Date levBuilt)
    {
        Replay ret = new Replay();
        ret._levelBuiltRequired = levBuilt;
        return ret;
    }

    static loadFromFile(Filename loadFrom)
    {
        Replay ret = new Replay();
        ret.implLoadFromFile(loadFrom);
        return ret;
    }

    Replay clone() const { return new Replay(this); }
    immutable(Replay) iClone() const { return cast(immutable Replay) clone(); }

    this(in typeof(this) rhs)
    {
        _gameVersionRequired = rhs._gameVersionRequired;
        _levelBuiltRequired = rhs._levelBuiltRequired;
        rhs.levelFilename.match!(
            (fn) { levelFilename = fn; },
            () { _levelFnCanBeNullInNetgames = MutFilename(null); });
        _permu = rhs._permu.clone();
        _plies = rhs._plies.dup;

        assert (! _players.length);
        rhs._players.byKeyValue.each!(a => _players[a.key] = a.value);
    }

private:
    this()
    {
        touch();
        _levelBuiltRequired = Date.now;
        _permu = new Permu("0");
    }

package:
    Optional!Filename levelFilename(Filename fn) @nogc nothrow
    {
        _levelFnCanBeNullInNetgames = fn;
        return levelFilename();
    }


public:
    // == ignores levelBuiltRequired and _gameVersionRequired.
    // I'm not sure how good that decision is. The idea is that replays
    // will behave identically anyway even when those differ.
    override bool opEquals(Object rhsObj) const
    {
        if (const rhs = cast(const(Replay)) rhsObj)
            return _plies == rhs._plies
                && cast(const(Profile[PlNr])) _players == rhs._players
                && _permu == rhs._permu
                && levelFilename == rhs.levelFilename;
        else
            return false;
    }

    Optional!Filename levelFilename() const @nogc nothrow
    {
        return _levelFnCanBeNullInNetgames is null ? no!Filename
            : some!Filename(_levelFnCanBeNullInNetgames.get);
    }

    const pure nothrow @safe @nogc {
        Date levelBuiltRequired() {return _levelBuiltRequired; }
        Version gameVersionRequired() { return _gameVersionRequired; }
        int numPlayers() { return _players.length & 0x7FFF_FFFF; }
        const(Profile[PlNr]) players() { return _players; }
        const(Permu) permu() { return _permu; }
        bool empty() { return _plies.length == 0; }
        Phyu latestPhyu() {
            return (_plies.length > 0) ? _plies[$-1].when : Phyu(0);
        }

        bool isOfflineSingleplayer() { return _players.length == 1; }

        bool isOnlineSingleplayer()
        {
            return ! isOfflineSingleplayer()
                && _players.byValue.all!(pl =>
                    pl.style == _players.byValue.front.style);
        }

        bool isOnlineMultiplayer()
        {
            return ! isOfflineSingleplayer && ! isOnlineSingleplayer;
        }
    }

    Permu permu(Permu p) { _permu = p; return p; }

    string styleToNames(in Style st) const
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

    void touch()
    {
        _gameVersionRequired = gameVersion();
        if (_players.length == 1) {
            foreach (ref Profile pl; _players)
                pl.name = file.option.allopts.userName;
        }
    }

    void addPlayer(PlNr nr, in Profile p)
    {
        _players[nr] = p;
    }

    const pure nothrow @safe @nogc {
        bool wasPlayedBy(string who)
        {
            return _players.byValue.canFind!(pl => pl.name == who);
        }

        /*
         * equalBefore(), extends():
         * These don't check whether the metadata/general data is the same.
         * We assume that Game only calls this on replays of the same level.
         * "Before" is exclusive, you might want to pass Phyu(now + 1).
         */
        bool equalBefore(in Replay rhs, in Phyu t)
        in { assert (rhs !is null); }
        do {
            return this.plySliceBefore(t) == rhs.plySliceBefore(t);
        }

        bool extends(in Replay rhs)
        in { assert (rhs !is null); }
        do {
            immutable rlen = rhs._plies.length;
            return _plies.length >= rlen && _plies[0 .. rlen] == rhs._plies[];
        }

        /*
         * Call allPlies() rarely, e.g., to list all entries in the tweaker.
         * Prefer to call plySliceFor().
         */
        const(Ply)[] allPlies() { return _plies; }
        const(Ply)[] plySliceFor(in Phyu upd)
        {
            auto slice = this.plySliceBefore(Phyu(upd + 1));
            int firstGood = slice.len;
            while (firstGood > 0 && slice[firstGood - 1].when == upd)
                --firstGood;
            assert (firstGood >= 0);
            assert (firstGood <= slice.length);
            return _plies[firstGood .. slice.length];
        }
    }

    void add(in Ply d)
    {
        touch();
        this.addWithoutTouching(d);
    }

    void eraseEarlySingleplayerNukes()
    {
        // Game updates nukes, then spawns, then lix perform.
        enum beforePhyu = 61; // Not 60, only nuke if it kills lix.
        if (_players.length > 1)
            return;
        for (int i = 0; i < _plies.length; ++i) {
            if (_plies[i].when >= beforePhyu) {
                break;
            }
            else if (_plies[i].isNuke) {
                _plies = _plies[0 .. i] ~ _plies[i+1 .. $];
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
        if (_players.length != 1 || _plies.canFind!(rd => rd.isNuke)) {
            return;
        }
        cutGlobalFutureAfter(lastActionsToKeep);

        Ply termNuke = Ply();
        termNuke.by = _players.byKey.front;
        termNuke.when = Phyu(lastActionsToKeep + 1);
        termNuke.isNuke = true;
        add(termNuke);
    }

    void cutGlobalFutureAfter(in Phyu upd)
    {
        assert (upd >= 0);
        _plies = _plies[0 .. this.plySliceBefore(Phyu(upd + 1)).length];
        touch();
    }

    /*
     * See file.replay.change for what it returns.
     */
    TweakResult tweak(in ChangeRequest rq)
    {
        touch();
        return this.tweakImpl(rq);
    }

    void saveManually(in Level lev) const
    {
        this.implSaveToFile(manualSaveFilename(), lev);
    }

    void saveAsAutoReplay(in Level lev) const
    {
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
}

unittest {
    Replay a = Replay.newNoLevelFilename(Date.now());
    Replay b = Replay.newNoLevelFilename(Date.now());
    Ply d;
    d.skill = Ac.digger;
    d.toWhichLix = 50;
    d.when = Phyu(20);
    a.add(d);
    b.add(d);
    d.skill = Ac.builder;
    d.when = Phyu(5);
    a.add(d);
    assert (! a.equalBefore(b, Phyu(30)));
    assert (! b.equalBefore(a, Phyu(30)));
    b.add(d);
    assert (a.equalBefore(b, Phyu(30)));
    assert (b.equalBefore(a, Phyu(30)));

    d.skill = Ac.basher;
    d.when = Phyu(10);
    b.add(d);
    assert (! a.equalBefore(b, Phyu(30)));
    assert (! b.equalBefore(a, Phyu(30)));
    assert (a.equalBefore(b, Phyu(10)));
    assert (b.equalBefore(a, Phyu(10)));
}
