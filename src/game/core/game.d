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
import std.typecons; // Rebindable!(const Lixxie)

import basics.alleg5;
import basics.globals;
import basics.globconf; // username, to determine whether to save result
import basics.help; // len;
import basics.user; // Result
import net.repdata;
import file.filename;

import game.core.calc;
import game.core.draw;
import game.core.scrstart;
import game.window.base;
import game.model.nurse;
import game.panel.base;
import game.effect;
import game.physdraw;
import game.tribe;
import game.replay;

import graphic.color;
import graphic.map;
import gui;
import hardware.sound;
import hardware.display; // fps for framestepping speed
import level.level;
import lix; // _drawHerHighlit
import net.iclient;

class Game {
package:
    immutable Runmode runmode;
    Level level;
    Map map; // The map does not hold the referential level image, that's
             // in cs.land and cs.lookup. Instead, the map loads a piece
             // of that land, blits gadgets and lixes on it, and blits the
             // result to the screen. It is both a renderer and a camera.
    Nurse nurse;
    EffectManager effect;
    INetClient _netClient; // null unless playing/observing multiplayer

    int _indexTribeLocal;
    long altickLastUpdate;
    Rebindable!(const Lixxie) _drawHerHighlit;

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
    bool _replayNeverCancelledThereforeDontSaveAutoReplay;

private:
    Update _setLastUpdateToNowLastCalled = Update(-1);

public:
    @property bool gotoMainMenu()         { return _gotoMainMenu; }

    enum ticksNormalSpeed   = ticksPerSecond / updatesPerSecond;
    enum updatesDuringTurbo = 9;
    enum updatesAheadMany   = ticksPerSecond / ticksNormalSpeed * 10;

    static int updatesBackMany()
    {
        // This is (1/lag) * 1 second. No lag => displayFPS == ticksPerSecond.
        return (ticksPerSecond + 1) * ticksPerSecond
            /  (displayFps     + 1) / ticksNormalSpeed;
    }

    this(Runmode rm, Level lv, Filename levelFilename = null, Replay rp = null)
    {
        this.runmode = rm;
        assert (lv);
        assert (lv.good);
        level = lv;
        prepareNurse(levelFilename, rp);
        setLastUpdateToNow();
    }

    this(INetClient client, Level lv)
    {
        this.runmode = Runmode.INTERACTIVE;
        assert (lv);
        assert (lv.good);
        level = lv;
        _netClient = client;
        prepareNurse(null, null);
        setLastUpdateToNow();
    }

    ~this()
    {
        if (pan)
            gui.rmElder(pan);
        if (modalWindow)
            gui.rmFocus(modalWindow);
        saveResult();
        saveAutoReplay();
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

    @property PlNr masterLocal() const { return nurse.replay.playerLocal; }
    @property string masterLocalName() const
    {
        return nurse.replay.playerLocalName;
    }

    void setLastUpdateToNow()
    {
        assert (this.effect);
        assert (this.nurse);
        effect.deleteAfter(nurse.upd);
        if (pan)
            pan.setLikeTribe(tribeLocal);
        if (nurse.updatesSinceZero == 0
            && _setLastUpdateToNowLastCalled != 0
        ) {
            hardware.sound.playLoud(Sound.LETS_GO);
        }
        _setLastUpdateToNowLastCalled = nurse.updatesSinceZero;
        altickLastUpdate = timerTicks;
    }

    void saveResult()
    {
        if (nurse && nurse.singleplayerHasWon
                  && masterLocalName == basics.globconf.userName)
            setLevelResult(nurse.replay.levelFilename,
                           nurse.resultForTribe(_indexTribeLocal));
    }

private:
    @property cs() inout
    {
        assert (nurse);
        assert (nurse.stateOnlyPrivatelyForGame);
        return nurse.stateOnlyPrivatelyForGame;
    }

    private void prepareNurse(Filename levelFilename, Replay rp)
    {
        assert (! effect);
        assert (! nurse);
        _replayNeverCancelledThereforeDontSaveAutoReplay = rp !is null;
        if (! rp)
            rp = generateFreshReplay(levelFilename);
        effect = new EffectManager;
        nurse  = new Nurse(level, rp, effect);

        // The tribes (teams of >= 1 players) array is sorted as follows:
        // a < b <=> min(plNrs in tribe a) < min(plNrs in tribe b).
        // The n-th tribe (n zero-based) is the tribe such that there exists
        // exactly n tribes with plNrs lower than this tribe's lowest plNr.
        //
        // But I think this is bad! We should index tribes by styles.
        // They should become an AA.
        _indexTribeLocal  = 0;
        effect.tribeLocal = 0;
        GapaMode gapamode = rp.players.len == 1 ? GapaMode.single
                                                : GapaMode.multiPlay;
        assert (pan is null);
        if (runmode == Runmode.INTERACTIVE) {
            map = new Map(cs.land, Geom.screenXls.to!int,
                                  (Geom.screenYls - Geom.panelYls).to!int);
            this.centerCameraOnHatchAverage();
            pan = new Panel(gapamode);
            gui.addElder(pan);
            pan.setLikeTribe(tribeLocal);
            pan.highlightFirstSkill();
        }
    }

    Replay generateFreshReplay(Filename levelFilename)
    {
        auto rp = Replay.newForLevel(levelFilename, level.built);
        if (! _netClient)
            rp.addPlayer(PlNr(0), Style.garden, basics.globconf.userName);
        else {
            foreach (plNr, prof; _netClient.profilesInOurRoom)
                rp.addPlayer(plNr, prof.style, prof.name);
            rp.playerLocal = _netClient.ourPlNr;
        }
        return rp;
    }

    void saveAutoReplay()
    {
        if (! _replayNeverCancelledThereforeDontSaveAutoReplay
            && nurse && nurse.replay)
            nurse.replay.saveAsAutoReplay(level, nurse.singleplayerHasWon);
    }
}
