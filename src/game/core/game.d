module game.core.game;

/* Game is the gameplay part of the program: The part of the program that has
 * a skill panel at the bottom, a level map above, and occasionally dialogs.
 *
 * Game contains a Nurse. Game also contains UI to affect the nurse.
 *
 * Nurse contains states of physics. One of these states is in a Model and
 * thereby can advance. Other states are in a PhysicsCache and the nurse
 * loads them as appropriate to recalculate during netgames or framestepping.
 *
 * Noninteractive games don't need the UI. I'm confused why I don't
 * bypass Game in that case and let the verifier work directly on the Nurse.
 * Game instantiates differently based on Runmode.
 */

public import basics.cmdargs; // Runmode;
public import game.core.view;

import std.algorithm; // find;
import std.conv; // float to int in prepare nurse
import std.typecons; // Rebindable!(const Lixxie)

import basics.alleg5;
import basics.globals;
import basics.globconf; // username, to determine whether to save result
import basics.help; // len;
import basics.user; // Result
import file.filename;

import game.core.calc;
import game.core.chatarea;
import game.core.draw;
import game.core.scrstart;
import game.core.speed;
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
import net.repdata;
import net.structs;

class Game {
package:
    immutable Runmode runmode;
    Level level;
    Map map; // The map does not hold the referential level image, that's
             // in cs.land and cs.lookup. Instead, the map loads a piece
             // of that land, blits gadgets and lixes on it, and blits the
             // result to the screen. It is both a renderer and a camera.
    Nurse nurse;
    EffectManager _effect; // null if we're verifying
    RichClient _netClient; // null unless playing/observing multiplayer

    long altickLastPhyu;

    // When we have time-shifted away from the server, we set this variable,
    // and let the physics update function gradually pay back this dept.
    // Is > 0 if we have to speed up, is < 0 if we have to slow down.
    // Should always be zero in singleplayer.
    long _alticksToAdjust;

    Rebindable!(const Lixxie) _drawHerHighlit;

    // Assignments for the next update go in here, and are only written into
    // the replay right before the update happens. If the replay is cut off
    // by skill assignment, the undispatched data is not cut off with it.
    // If the replay is cut off by explicit cutting (LMB into empty space),
    // the undispatched data too is emptied.
    ReplayData[] undispatchedAssignments;

    GameWindow modalWindow;
    Panel pan;
    ChatArea _chatArea;

    int _profilingGadgetCount;
    bool _gotoMainMenu;
    bool _replayNeverCancelledThereforeDontSaveAutoReplay;

private:
    Phyu _setLastPhyuToNowLastCalled = Phyu(-1);

public:
    @property bool gotoMainMenu()         { return _gotoMainMenu; }

    enum ticksNormalSpeed   = ticksPerSecond / 15; // run at 15 Pyus per sec
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
        initializePanel();
        initializeConsole();
        setLastPhyuToNow();
    }

    this(RichClient client)
    {
        this.runmode = Runmode.INTERACTIVE;
        assert (client);
        assert (client.level);
        assert (client.level.good);
        level = client.level;
        _netClient = client;
        _netClient.onPeerSendsReplayData = (ReplayData data)
        {
            this.undispatchedAssignments ~= data;
        };
        _netClient.onMillisecondsSinceGameStart = (int millis)
        {
            this.adjustToMatchMillisecondsSinceGameStart(millis);
        };
        prepareNurse(null, null);
        initializePanel();
        initializeConsole();
        setLastPhyuToNow();
    }

    /* Using ~this to dispose stuff is probably bad style.
     * Maybe refactor into a dispose() method that we call at exactly one
     * point. ~this might be called more often by the language.
     */
    void dispose()
    {
        if (pan) {
            gui.rmElder(pan);
            pan = null;
        }
        if (_chatArea) {
            gui.rmElder(_chatArea);
            _chatArea = null;
        }
        if (modalWindow) {
            gui.rmFocus(modalWindow);
            modalWindow = null;
        }
        saveResult();
        saveAutoReplay();
        if (nurse) {
            nurse.dispose();
            nurse = null;
        }
    }

    Result evaluateReplay()
    {
        assert (level);
        return nurse.evaluateReplayUntilSingleplayerHasSavedAtLeast(
            level.required);
    }

    auto loseOwnershipOfRichClient()
    {
        if (! _netClient)
            return null;
        auto ret = _netClient;
        _netClient = null;

        if (_chatArea)
            _chatArea.saveUnsentMessageAndDispose();
        // Null all our event handlers. Maybe refactor to observer pattern?
        ret.onPeerSendsReplayData = null;
        ret.onMillisecondsSinceGameStart = null;
        return ret;
    }

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
        return nurse.replay.latestPhyu > nurse.upd;
    }

    @property bool multiplayer() const
    {
        return nurse.stateOnlyPrivatelyForGame.multiplayer;
    }

    @property Style localStyle() const
    {
        return nurse.replay.playerLocalOrSmallest.style;
    }

    @property const(Tribe) localTribe() const
    {
        auto ptr = localStyle in cs.tribes;
        assert (ptr, "badly cloned cs? Local style isn't there");
        return *ptr;
    }

    @property PlNr plNrLocal() const
    {
        return nurse.replay.plNrLocalOrSmallest;
    }

    @property auto playerLocal() const
    {
        return nurse.replay.playerLocalOrSmallest;
    }

    @property View view() const
    {
        assert (nurse && nurse.replay, "call view() after init'ing replay");
        return createView(nurse.replay.numPlayers,
            // need && and ?: due to _netClient's alias inner() this
            _netClient && _netClient.inner ? _netClient.inner : null);
    }

    void setLastPhyuToNow()
    {
        assert (this.nurse);
        if (_effect)
            _effect.deleteAfter(nurse.upd);
        if (pan)
            pan.setLikeTribe(localTribe);
        if (runmode == Runmode.INTERACTIVE && nurse.updatesSinceZero == 0
            && _setLastPhyuToNowLastCalled != 0
        ) {
            hardware.sound.playLoud(Sound.LETS_GO);
        }
        _setLastPhyuToNowLastCalled = nurse.updatesSinceZero;
        altickLastPhyu = timerTicks;
    }

    void saveResult()
    {
        if (nurse && nurse.singleplayerHasSavedAtLeast(level.required)
                  && playerLocal.name == basics.globconf.userName)
            setLevelResult(nurse.replay.levelFilename,
                           nurse.resultForTribe(localStyle));
    }

private:
    @property cs() inout
    {
        assert (nurse);
        return nurse.stateOnlyPrivatelyForGame;
    }

    private void prepareNurse(Filename levelFilename, Replay rp)
    {
        assert (! nurse);
        _replayNeverCancelledThereforeDontSaveAutoReplay = rp !is null;
        if (! rp)
            rp = generateFreshReplay(levelFilename);
        // DTODONETWORK: Eventually, observers shall cycle through the
        // spectating teams. Don't set a final style here, but somehow
        // make the effect manager depend on what the GUI chooses.
        if (runmode == Runmode.INTERACTIVE)
            _effect = new EffectManager(rp.playerLocalOrSmallest.style);
        nurse = new Nurse(level, rp, _effect);
    }

    Replay generateFreshReplay(Filename levelFilename)
    {
        auto rp = Replay.newForLevel(levelFilename, level.built);
        if (! _netClient)
            rp.addPlayer(PlNr(0), Style.garden,
                         basics.globconf.userName, true);
        else {
            foreach (plNr, prof; _netClient.profilesInOurRoom)
                if (prof.feeling != Profile.Feeling.observing)
                    rp.addPlayer(plNr, prof.style, prof.name,
                                 plNr == _netClient.ourPlNr);
        }
        return rp;
    }

    void initializePanel()
    {
        assert (nurse);
        assert (nurse.replay);
        assert (pan is null);
        if (runmode != Runmode.INTERACTIVE)
            return;

        map = new Map(cs.land, gui.screenXls.to!int,
                              (gui.screenYls - gui.panelYls).to!int);
        this.centerCameraOnHatchAverage();
        assert (level);
        pan = new Panel(view, level.required);
        gui.addElder(pan);
        pan.setLikeTribe(localTribe);
        pan.highlightFirstSkill();
    }

    void initializeConsole()
    {
        assert (! _chatArea);
        if (runmode != Runmode.INTERACTIVE)
            return;
        _chatArea = new ChatArea(new Geom(0, 0, gui.screenXlg, 0),
            _netClient);
        gui.addElder(_chatArea);
    }

    void saveAutoReplay()
    {
        if (! _replayNeverCancelledThereforeDontSaveAutoReplay
            && nurse && nurse.replay
        ) {
            nurse.replay.saveAsAutoReplay(level,
                nurse.singleplayerHasSavedAtLeast(level.required));
        }
    }
}
