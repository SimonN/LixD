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
    @property Optional!Filename levelFilename(Filename fn) @nogc nothrow
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

    @property Optional!Filename levelFilename() const @nogc nothrow
    {
        return _levelFnCanBeNullInNetgames is null ? no!Filename
            : some!Filename(_levelFnCanBeNullInNetgames.get);
    }

    @property const pure nothrow @safe @nogc {
        Date levelBuiltRequired() {return _levelBuiltRequired; }
        Version gameVersionRequired() { return _gameVersionRequired; }
        int numPlayers() { return _players.length & 0x7FFF_FFFF; }
        const(Profile[PlNr]) players() { return _players; }
        const(Permu) permu() { return _permu; }
        bool empty() { return _plies.length == 0; }
        int latestPhyu() { return (_plies.length > 0) ? _plies[$-1].update : 0; }

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

    bool wasPlayedBy(string who) const pure nothrow @safe @nogc
    {
        return _players.byValue.canFind!(pl => pl.name == who);
    }

    // This doesn't check whether the metadata/general data is the same.
    // We assume that Game only calls this on replays of the same level.
    // "Before" is exclusive, you might want to pass Phyu(now + 1).
    bool equalBefore(in Replay rhs, in Phyu before) const @nogc nothrow
    in {
        assert (rhs !is null);
    }
    do {
        return this.plySliceBefore(before)
            == rhs.plySliceBefore(before);
    }

    void eraseEarlySingleplayerNukes()
    {
        // Game updates nukes, then spawns, then lix perform.
        enum beforePhyu = 61; // Not 60, only nuke if it kills lix.
        if (_players.length > 1)
            return;
        for (int i = 0; i < _plies.length; ++i) {
            if (_plies[i].update >= beforePhyu)
                break;
            else if (_plies[i].action == RepAc.NUKE) {
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
        if (_players.length != 1
            || _plies.canFind!(rd => rd.action == RepAc.NUKE))
            return;
        cutGlobalFutureAfter(lastActionsToKeep);

        Ply termNuke = Ply();
        termNuke.player = _players.byKey.front;
        termNuke.update = Phyu(lastActionsToKeep + 1);
        termNuke.action = RepAc.NUKE;
        add(termNuke);
    }

    void cutGlobalFutureAfter(in Phyu upd)
    {
        assert (upd >= 0);
        _plies = _plies[0 .. this.plySliceBefore(Phyu(upd + 1)).length];
        touch();
    }

    /*
     * We assume that we'll only call cutSingleLixFutureAfter() during
     * singleplayer, where there is only one tribe and we don't have to
     * compare players/styles/... We only look for matching lix IDs.
     */
    void cutSingleLixFutureAfter(in Phyu upd, in int lixID)
    {
        bool toCut(in Ply p) pure nothrow @safe @nogc
        {
            if (p.update <= upd) {
                return false;
            }
            return p.action == RepAc.NUKE
                || p.isSomeAssignment && p.toWhichLix == lixID;
        }
        if (_plies.empty
            || _plies[$-1].update <= upd
            || ! _plies.canFind!toCut
        ) {
            return; // Nothing to cut.
        }
        _plies = _plies.filter!(ply => ! toCut(ply)).array;
        touch();
    }

    /*
     * Our users should prefer to call plySliceFor() over allPlies().
     */
    const(Ply)[] plySliceFor(in Phyu upd) const pure nothrow @nogc
    {
        auto slice = this.plySliceBefore(Phyu(upd + 1));
        int firstGood = slice.len;
        while (firstGood > 0 && slice[firstGood - 1].update == upd)
            --firstGood;
        assert (firstGood >= 0);
        assert (firstGood <= slice.length);
        return _plies[firstGood .. slice.length];
    }

    /*
     * Call allPlies() rarely, e.g., to list all entries in the replay editor.
     */
    @property const(Ply)[] allPlies() const pure nothrow @nogc
    {
        return _plies;
    }

    bool getOnPhyuLixClicked(in Phyu upd, in int lix_id, in Ac ac) const
    {
        auto vec = plySliceFor(upd);
        foreach (const ref d; vec)
            if (d.isSomeAssignment && d.toWhichLix == lix_id && d.skill == ac)
                return true;
        return false;
    }

    void add(in Ply d)
    {
        touch();
        this.addWithoutTouching(d);
    }

    /*
     * See file.replay.change for what it returns.
     */
    TweakResult tweak(in ChangeRequest rq)
    {
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

unittest {
    Replay a = Replay.newNoLevelFilename(Date.now());
    for (int phyu = 100; phyu < 200; phyu += 10) {
        Ply ply;
        ply.action = phyu % 20 == 10 ? RepAc.ASSIGN_LEFT : RepAc.ASSIGN_RIGHT;
        ply.skill = phyu % 40 < 20 ? Ac.digger : Ac.climber;
        ply.toWhichLix = 3;
        ply.update = Phyu(phyu);
        a.add(ply);
    }
    assert (a.allPlies.length == 10);
    a.cutSingleLixFutureAfter(Phyu(150), 3);
    assert (a.allPlies.length == 6); // 100, 110, 120, 130, 140, 150
    assert (a.allPlies[$-1].update == Phyu(150));
}
