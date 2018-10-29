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
import file.option; // username, to determine whether to save result
import basics.help : len;
import file.filename;
import file.trophy;
import file.replay;

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
import game.window.base;

import graphic.map;
import gui;
import hardware.display; // fps for framestepping speed
import hardware.music;
import hardware.sound;
import level.level;
import lix; // _drawHerHighlit
import physics.tribe;
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

    const(TrophyKey) _trophyKeyOfTheLevel;
    Filename _levelFnForHarvest;
    bool _gotoMainMenu;

private:
    Phyu _setLastPhyuToNowLastCalled = Phyu(-1);

public:
    enum phyusPerSecond     = 15;
    enum ticksNormalSpeed   = ticksPerSecond / phyusPerSecond;
    enum updatesDuringTurbo = 9;
    enum updatesAheadMany   = ticksPerSecond / ticksNormalSpeed * 10;

    /*
     * Create Game without replay. Pass level filename such that the Game
     * can create its own replay. You will be able to save tropies as long
     * as the TrophyKey's fileNoExt is nonempty. If fileNoExt is empty,
     * maybeImprove() will reject the trophy anyway.
     */
    this(Level lv, TrophyKey keyOfLv,
        Filename levelFnForLegacyPointedTo,
        Optional!Replay orp)
    in {
        assert (lv);
        assert (lv.playable);
        assert (levelFnForLegacyPointedTo !is null);
    }
    body {
        level = lv;
        _trophyKeyOfTheLevel = keyOfLv;
        _levelFnForHarvest = levelFnForLegacyPointedTo;
        import optional;
        if (orp.empty) { // Hack! orp.match failed with crazy template error
            commonConstructor(generateFreshReplay(
                some(levelFnForLegacyPointedTo)));
        }
        else {
            commonConstructor(orp.front);
        }
    }

    this(RichClient client)
    {
        enforce(client, "Game started without networking client.");
        enforce(client.level, "Networking game started without level.");
        enforce(client.level.playable, "Networking level is unplayable.");
        enforce(client.permu, "Networking game has no player permutation.");

        level = client.level;
        _netClient = client;
        _trophyKeyOfTheLevel = TrophyKey(""); // empty fileNoExt => never save
        _levelFnForHarvest = new VfsFilename(""); // shouldn't be important
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
        commonConstructor(generateFreshReplay(no!Filename));
    }

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
        if (map) {
            map.dispose();
            map = null;
        }
    }

    @property bool gotoMainMenu() { return _gotoMainMenu; }

    Harvest harvest() const
    {
        Trophy tro = Trophy(level.built, _levelFnForHarvest);
        tro.copyFrom(nurse.trophyForTribe(localStyle));
        return Harvest(level, nurse.constReplay, _trophyKeyOfTheLevel, tro);
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
        foreach (fn; nurse.constReplay.levelFilename)
            if (fn.fileNoExtNoPre != "")
                return fn.fileNoExtNoPre;
        return nurse.constStateForDrawingOnly.multiplayer
            ? "multiplayer" : "singleplayer";
    }

    void calc() { implGameCalc(this); }
    void draw() { implGameDraw(this); }

package:
    static int updatesBackMany()
    {
        // This is (1/lag) * 1 second. No lag => displayFPS == ticksPerSecond.
        return (ticksPerSecond + 1) * ticksPerSecond
            /  (displayFps     + 1) / ticksNormalSpeed;
    }

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

    @property bool singleplayerHasWon() const
    {
        return ! multiplayer && nurse && level
            && nurse.singleplayerHasSavedAtLeast(level.required);
    }

    @property bool singleplayerHasNuked() const
    {
        return ! multiplayer && nurse && level && nurse.singleplayerHasNuked;
    }

private:
    @property cs() inout
    {
        assert (nurse);
        return nurse.stateOnlyPrivatelyForGame;
    }

    void commonConstructor(Replay rp)
    {
        // DTODONETWORK: Eventually, observers shall cycle through the
        // spectating teams. Don't set a final style here, but somehow
        // make the effect manager depend on what the GUI chooses.
        _effect = new EffectManager(determineLocalStyle(rp));
        nurse = new InteractiveNurse(level, rp, _effect);

        initializePanel();
        initializeConsole();
        stopMusic();
        _splatRuler = createSplatRuler();
        setLastPhyuToNow();
    }

    Replay generateFreshReplay(Optional!Filename levelFilename)
    {
        auto rp = levelFilename.empty ? Replay.newNoLevelFilename(level.built)
            : Replay.newForLevel(levelFilename.unwrap, level.built);
        if (! _netClient) {
            rp.addPlayer(PlNr(0), Style.garden, file.option.userName);
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
    in { assert (rp); }
    body {
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
        foreach (player; nurse.constReplay.players) {
            pan.add(player.style, player.name);
        }
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
