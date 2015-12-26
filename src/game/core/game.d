module game.core.game;

/* 2015-06-03. After 9 years, it's time to write another one of these classes.
 *
 * There are many methods that were distributed over many files in C++.
 * Here, we don't declare any private (accessible from same file) members,
 * but everything is package (accessible from files in same directory).
 */

public import basics.cmdargs; // Runmode;

import std.algorithm; // find;

import basics.alleg5;
import basics.globals;
import basics.help; // len;
import basics.nettypes;
import file.filename;
import game.core;
import game.gui.gamewin;
import graphic.color;
import graphic.map;
import gui;
import level.level;

class Game {

    @property bool gotoMenu() { return _gotoMenu; }

    enum ticksNormalSpeed   = 4;
    enum updatesDuringTurbo = 9;
    enum updatesBackMany    = ticksPerSecond / ticksNormalSpeed * 1;
    enum updatesAheadMany   = ticksPerSecond / ticksNormalSpeed * 10;

    this(Runmode rm, Level lv, Filename fn = null, Replay rp = null)
    {
        this.runmode = rm;
        implGameConstructor(this, lv, fn, rp);
    }

    ~this()     { implGameDestructor(this); }

    void calc() { implGameCalc(this); }
    void draw() { implGameDraw(this); }

package:

    bool _gotoMenu;
    immutable Runmode runmode;

    Level     level;
    Filename  levelFilename;
    Replay    replay;

    Map map; // The map does not hold the referential level image, that's
             // in cs.land and cs.lookup. Instead, the map loads a piece
             // of that land, blits gadgets and lixes on it, and blits the
             // result to the screen. It is both a renderer and a camera.

    GameState cs; // current state
    StateManager stateManager;
    PhysicsDrawer physicsDrawer;
    EffectManager effect;
    Panel pan;

    int _indexTribeLocal;
    int _indexMasterLocal;

    long altickLastUpdate;

    // Assignments for the next update go in here, and are only written into
    // the replay right before the update happens. If the replay is cut off,
    // the undispatched data is not cut off with it.
    ReplayData[] undispatchedAssignments;

    GameWindow modalWindow;

    int _profilingGadgetCount;

    @property bool replaying() const
    {
        assert (replay, "need to instantiate replay before isReplaying()");
        assert (cs, "need non-null cs to query during isReplaying()");
        // Replay data for update n means: this will be used when updating
        // from update n-1 to n. If there is still unapplied replay data,
        // then we are replaying.
        // DTODONETWORKING: Add a check that we are never replaying while
        // we're connected with other players.
        return replay.latestUpdate > cs.update;
    }

    @property bool multiplayer() const
    {
        assert (cs, "query for multiplayer after making the current state");
        assert (cs.tribes.length > 0, "query for multiplayer after making cs");
        return (cs.tribes.length > 1);
    }

    @property inout(Tribe) tribeLocal() inout
    {
        assert (cs, "null cs, shouldn't ever be null");
        assert (cs.tribes.length > _indexTribeLocal, "badly cloned cs");
        return cs.tribes[_indexTribeLocal];
    }

    @property int tribeID(const Tribe tr) const
    out (result) {
        assert (result < cs.tribes.length, "tribe must be findable in cs");
    }
    body {
        assert (cs);
        assert (cs.tribes.length > 0);
        return cs.tribes.len - cs.tribes.find!"a is b"(tr).len;
    }

    @property ref inout(Tribe.Master) masterLocal() inout
    {
        assert (cs, "null cs, shouldn't ever be null");
        assert (cs.tribes.len > _indexTribeLocal, "badly cloned cs");
        assert (cs.tribes[_indexTribeLocal].masters.len > _indexMasterLocal);
        return cs.tribes[_indexTribeLocal].masters[_indexMasterLocal];
    }

    @property bool singlePlayerHasWon() const
    {
        // doesn't assert, might get called in the destructor on an .init game
        return cs !is null && ! multiplayer
            && cs.tribes[0].lixSaved >= cs.tribes[0].lixRequired;
    }

}
