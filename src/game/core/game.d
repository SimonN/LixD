module game.core.game;

/* Game is the gameplay part of the program: The part of the program that has
 * a skill panel at the bottom, a level map above, and occasionally dialogs.
 *
 * You should only construct a Game in interactive mode.
 * To unittest or to verify replays, create a Nurse directly.
 *
 * Game contains a Nurse. Game also contains UI to affect the nurse.
 *
 * Nurse contains states of physics. One of these states is in a Model and
 * thereby can advance. Other states are in a PhysicsCache and the nurse
 * loads them as appropriate to recalculate during netgames or framestepping.
 */

public import basics.cmdargs; // Runmode;
public import game.core.view;

import std.conv; // float to int in prepare nurse
import std.exception;
import std.range;

import optional;

import basics.alleg5;
import basics.globals;
import basics.globconf; // username, to determine whether to save result
import basics.help : len;
import basics.user; // Trophy
import file.filename;

import game.core.calc;
import game.core.chatarea;
import game.core.draw;
import game.core.scrstart;
import game.core.speed;
import game.core.splatrul;
import game.effect;
import game.harvest;
import game.nurse.interact;
import game.panel.base;
import game.physdraw;
import game.replay;
import game.tribe;
import game.window.base;

import graphic.map;
import gui;
import hardware.display; // fps for framestepping speed
import hardware.music;
import hardware.sound;
import level.level;
import lix; // _drawHerHighlit
import net.repdata;
import net.structs;

class Game {
public:
    const(Level) level;

package:
    Map map; // The map does not hold the referential level image, that's
             // in cs.land and cs.lookup. Instead, the map loads a piece
             // of that land, blits gadgets and lixes on it, and blits the
             // result to the screen. It is both a renderer and a camera.
    InteractiveNurse nurse;
    EffectManager _effect; // null if we're verifying
    RichClient _netClient; // null unless playing/observing multiplayer

    long altickLastPhyu;
    long _altickPingGoalsUntil; // starts at 0, which means don't ping goals

    // When we have time-shifted away from the server, we set this variable,
    // and let the physics update function gradually pay back this dept.
    // Is > 0 if we have to speed up, is < 0 if we have to slow down.
    // Should always be zero in singleplayer.
    long _alticksToAdjust;

    ConstLix _drawHerHighlit;

    // Assignments for the next update go in here, and are only written into
    // the replay right before the update happens. If the replay is cut off
    // by skill assignment, the undispatched data is not cut off with it.
    // If the replay is cut off by explicit cutting (LMB into empty space),
    // the undispatched data too is emptied.
    ReplayData[] undispatchedAssignments;

    ReallyExitWindow modalWindow;
    Panel pan;
    ChatArea _chatArea;
    SplatRuler _splatRuler;

    int _profilingGadgetCount;
    bool _gotoMainMenu;
    bool _replayNeverCancelledThereforeDontSaveAutoReplay;
    bool _maySaveTrophy;

private:
    Phyu _setLastPhyuToNowLastCalled = Phyu(-1);

public:
    @property bool gotoMainMenu() { return _gotoMainMenu; }

    enum phyusPerSecond     = 15;
    enum ticksNormalSpeed   = ticksPerSecond / phyusPerSecond;
    enum updatesDuringTurbo = 9;
    enum updatesAheadMany   = ticksPerSecond / ticksNormalSpeed * 10;

    static int updatesBackMany()
    {
        // This is (1/lag) * 1 second. No lag => displayFPS == ticksPerSecond.
        return (ticksPerSecond + 1) * ticksPerSecond
            /  (displayFps     + 1) / ticksNormalSpeed;
    }

    this(Level lv, Filename levelFilename, Replay rp, in bool maySaveTrophy)
    {
        assert (lv);
        assert (lv.playable);
        level = lv;
        _maySaveTrophy = maySaveTrophy;
        prepareNurse(levelFilename, rp);
        commonConstructor();
    }

    this(RichClient client)
    {
        enforce(client, "Game started without networking client.");
        enforce(client.level, "Networking game started without level.");
        enforce(client.level.playable, "Networking level is unplayable.");
        enforce(client.permu, "Networking game has no player permutation.");

        level = client.level;
        _netClient = client;
        _netClient.onConnectionLost = ()
        {
            // Maybe too drastic? Lobby will catch us
            this._gotoMainMenu = true;
        };
        _netClient.onPeerSendsReplayData = (ReplayData data)
        {
            this.undispatchedAssignments ~= data;
        };
        _netClient.onMillisecondsSinceGameStart = (int millis)
        {
            this.adjustToMatchMillisecondsSinceGameStart(millis);
        };
        prepareNurse(null, null);
        commonConstructor();
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
        if (nurse) {
            nurse.dispose();
            nurse = null;
        }
    }

    Harvest harvest() const
    {
        return Harvest(level, nurse.constReplay,
            some(nurse.trophyForTribe(localStyle)),
            ! _replayNeverCancelledThereforeDontSaveAutoReplay);
    }

    const(Replay) replay() const { return nurse.constReplay; }

    auto loseOwnershipOfRichClient()
    {
        if (! _netClient)
            return null;
        auto ret = _netClient;
        _netClient = null;

        if (_chatArea)
            _chatArea.saveUnsentMessageAndDispose();
        ret.onConnectionLost = null;
        ret.onPeerSendsReplayData = null;
        ret.onMillisecondsSinceGameStart = null;
        return ret;
    }

    string filenamePrefixForScreenshot() const
    out (ret) { assert (ret != ""); }
    body {
        assert (nurse);
        assert (nurse.constReplay);
        if (nurse.constReplay.levelFilename
            && nurse.constReplay.levelFilename.fileNoExtNoPre != "")
            return nurse.constReplay.levelFilename.fileNoExtNoPre;
        else
            return nurse.constStateForDrawingOnly.multiplayer
                ? "multiplayer" : "singleplayer";
    }

    void calc() { implGameCalc(this); }
    void draw() { implGameDraw(this); }

package:
    @property bool replaying() const
    {
        assert (nurse);
        // Replay data for update n means: this will be used when updating
        // from update n-1 to n. If there is still unapplied replay data,
        // then we are replaying.
        // DTODONETWORKING: Add a check that we are never replaying while
        // we're connected with other players.
        return nurse.constReplay.latestPhyu > nurse.upd;
    }

    @property bool multiplayer() const
    {
        return nurse.stateOnlyPrivatelyForGame.multiplayer;
    }

    @property Style localStyle() const @nogc nothrow
    in { assert (_effect, "create effect manager before querying style"); }
    body { return _effect.localTribe; }

    @property const(Tribe) localTribe() const
    {
        auto ptr = localStyle in cs.tribes;
        assert (ptr, "badly cloned cs? Local style isn't there");
        return *ptr;
    }

    @property View view() const
    {
        assert (nurse && nurse.constReplay, "call view() after replay init");
        return createView(nurse.constReplay.numPlayers,
            // need && and ?: due to _netClient's alias inner() this
            _netClient && _netClient.inner ? _netClient.inner : null);
    }

    void setLastPhyuToNow()
    {
        assert (this.nurse);
        if (_effect)
            _effect.deleteAfter(nurse.upd);
        if (pan)
            pan.setLikeTribe(localTribe, level.ploder,
                             cs.overtimeRunning, cs.overtimeRemainingInPhyus);
        if (nurse.updatesSinceZero == 0 && _setLastPhyuToNowLastCalled != 0) {
            hardware.sound.playLoud(Sound.LETS_GO);
        }
        nurse.considerGC();
        _setLastPhyuToNowLastCalled = nurse.updatesSinceZero;
        altickLastPhyu = timerTicks;
    }

    bool singleplayerHasWon() const
    {
        return ! multiplayer && nurse && level
            && nurse.singleplayerHasSavedAtLeast(level.required);
    }

private:
    @property cs() inout
    {
        assert (nurse);
        return nurse.stateOnlyPrivatelyForGame;
    }

    void commonConstructor()
    {
        initializePanel();
        initializeConsole();
        stopMusic();
        setLastPhyuToNow();
        _splatRuler = createSplatRuler();
    }

    void prepareNurse(Filename levelFilename, Replay rp)
    {
        assert (! nurse);
        _replayNeverCancelledThereforeDontSaveAutoReplay = rp !is null;
        if (! rp)
            rp = generateFreshReplay(levelFilename);
        // DTODONETWORK: Eventually, observers shall cycle through the
        // spectating teams. Don't set a final style here, but somehow
        // make the effect manager depend on what the GUI chooses.
        _effect = new EffectManager(determineLocalStyle(rp));
        nurse = new InteractiveNurse(level, rp, _effect);
    }

    Replay generateFreshReplay(Filename levelFilename)
    {
        auto rp = Replay.newForLevel(levelFilename, level.built);
        if (! _netClient) {
            rp.addPlayer(PlNr(0), Style.garden, basics.globconf.userName);
        }
        else {
            rp.permu = _netClient.permu;
            foreach (plNr, prof; _netClient.profilesInOurRoom)
                if (prof.feeling != Profile.Feeling.observing)
                    rp.addPlayer(plNr, prof.style, prof.name);
        }
        return rp;
    }

    Style determineLocalStyle(in Replay rp) const
    {
        if (rp.players.length == 0)
            return Style.garden;
        if (_netClient) {
            auto ptr = _netClient.ourPlNr in rp.players;
            if (ptr)
                return ptr.style;
        }
        foreach (plNr, pl; rp.players)
            if (pl.name == userName)
                return pl.style;
        // We aren't in the players list, but it's nonempty. Observe randomly.
        import std.random;
        return rp.players.byValue
            .drop(uniform(0, rp.players.length.to!int)).front.style;
    }

    void initializePanel()
    in {
        assert (nurse);
        assert (nurse.constReplay);
        assert (level);
        assert (pan is null);
    }
    body {
        map = new Map(cs.land, gui.screenXls.to!int,
                              (gui.screenYls - gui.panelYls).to!int);
        this.centerCameraOnHatchAverage();
        pan = new Panel(view, level.required);
        gui.addElder(pan);
        setLastPhyuToNow(); // to fill skills, needed for highlightFirstSkill
        pan.highlightFirstSkill();
    }

    void initializeConsole()
    {
        assert (! _chatArea);
        _chatArea = new ChatArea(new Geom(0, 0, gui.screenXlg, 0),
            _netClient);
        gui.addElder(_chatArea);
    }
}
