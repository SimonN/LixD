module game.core.game;

/* 2015-06-03. After 9 years, it's time to write another one of these classes.
 *
 * There are many methods that were distributed over many files in C++.
 * Here, we don't declare any private (accessible from same file) members,
 * but everything is package (accessible from files in same directory).
 */

public import basics.cmdargs; // Runmode;

import std.algorithm; // find;
import std.conv; // float to int in prepare nurse

import basics.alleg5;
import basics.globals;
import basics.help; // len;
import basics.user; // Result
import basics.nettypes;
import file.filename;

import game.core.calc;
import game.core.draw;
import game.core.scrstart;
import game.gui.gamewin;
import game.model.nurse;
import game.gui.panel;
import game.effect;
import game.physdraw;
import game.tribe;
import game.replay;

import graphic.color;
import graphic.map;
import gui;
import level.level;

class Game {

    @property bool gotoMainMenu()         { return _gotoMainMenu; }
    @property wasInstantiatedWithReplay() { return _wasInstantiatedWithReplay;}

    enum ticksNormalSpeed   = 4;
    enum updatesDuringTurbo = 9;
    enum updatesBackMany    = ticksPerSecond / ticksNormalSpeed * 1;
    enum updatesAheadMany   = ticksPerSecond / ticksNormalSpeed * 10;

    this(Runmode rm, Level lv, Filename fn = null, Replay rp = null)
    {
        this.runmode = rm;
        assert (lv);
        assert (lv.good);

        scope (exit)
            this.setLastUpdateToNow();
        level         = lv;
        levelFilename = fn;
        prepareNurse(rp, fn);
    }

    ~this()
    {
        if (pan)
            gui.rmElder(pan);
        if (modalWindow)
            gui.rmFocus(modalWindow);
        if (nurse && nurse.replay && ! wasInstantiatedWithReplay)
            nurse.replay.saveAsAutoReplay(levelFilename, level,
                                          cs.singlePlayerHasWon);
        if (nurse)
            nurse.dispose();
    }

    Result evaluateReplay() { return nurse.evaluateReplay(); }

    void calc()
    {
        assert (runmode == Runmode.INTERACTIVE);
        implGameCalc(this);
    }

    void draw()
    {
        assert (runmode == Runmode.INTERACTIVE);
        implGameDraw(this);
    }

package:

    immutable Runmode runmode;

    Level     level;
    Filename  levelFilename;

    Map map; // The map does not hold the referential level image, that's
             // in cs.land and cs.lookup. Instead, the map loads a piece
             // of that land, blits gadgets and lixes on it, and blits the
             // result to the screen. It is both a renderer and a camera.
    Nurse nurse;
    EffectManager effect;

    int _indexTribeLocal;
    int _indexMasterLocal;

    long altickLastUpdate;

    // Assignments for the next update go in here, and are only written into
    // the replay right before the update happens. If the replay is cut off
    // by skill assignment, the undispatched data is not cut off with it.
    // If the replay is cut off by explicit cutting (LMB into empty space),
    // the undispatched data too is emptied.
    ReplayData[] undispatchedAssignments;
    GameWindow modalWindow;
    Panel pan;

    int _profilingGadgetCount;

    bool _gotoMainMenu;
    bool _wasInstantiatedWithReplay;

    @property bool replaying() const
    {
        assert (nurse);
        // Replay data for update n means: this will be used when updating
        // from update n-1 to n. If there is still unapplied replay data,
        // then we are replaying.
        // DTODONETWORKING: Add a check that we are never replaying while
        // we're connected with other players.
        return nurse.replay.latestUpdate > nurse.upd;
    }

    @property const(Tribe) tribeLocal() const
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

    @property ref const(Tribe.Master) masterLocal() const
    {
        assert (cs, "null cs, shouldn't ever be null");
        assert (cs.tribes.len > _indexTribeLocal, "badly cloned cs");
        assert (cs.tribes[_indexTribeLocal].masters.len > _indexMasterLocal);
        return cs.tribes[_indexTribeLocal].masters[_indexMasterLocal];
    }

    void setLastUpdateToNow()
    {
        altickLastUpdate = timerTicks;
        effect.deleteAfter(nurse.upd);
        if (pan)
            pan.setLikeTribe(tribeLocal);
    }

private:

    @property cs() inout
    {
        assert (nurse);
        assert (nurse.stateOnlyPrivatelyForGame);
        return nurse.stateOnlyPrivatelyForGame;
    }

    private void prepareNurse(Replay rp, Filename fn)
    {
        assert (! effect);
        assert (! nurse);
        _wasInstantiatedWithReplay = rp !is null;
        if (! rp) {
            rp = new Replay();
            rp.levelFilename = fn;

            // DTODONETWORK: what to add?
            import lix.enums;
            rp.addPlayer(PlNr(0), Style.garden, basics.globconf.userName);
        }
        effect = new EffectManager;
        nurse  = new Nurse(level, rp, effect);

        // DTODONETWORKING: initialize to something different, and pass the
        // nurse the number of players
        _indexTribeLocal  = 0;
        _indexMasterLocal = 0;
        effect.tribeLocal = 0;

        assert (pan is null);
        if (runmode == Runmode.INTERACTIVE) {
            map = new Map(cs.land, Geom.screenXls.to!int,
                                  (Geom.screenYls - Geom.panelYls).to!int);
            this.centerCameraOnHatchAverage();
            pan = new Panel;
            gui.addElder(pan);
            pan.setLikeTribe(tribeLocal);
            pan.highlightFirstSkill();
        }
    }
}
