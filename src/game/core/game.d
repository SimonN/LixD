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

import core.time;
import std.conv; // float to int in prepare nurse
import std.exception;
import std.range;

import enumap;
import optional;

import basics.alleg5;
import basics.globals;
import basics.help : len;
import file.filename;
import file.trophy;
import file.replay;
import opt = file.option.allopts;

import game.argscrea;
import game.core.calc;
import game.core.chatarea;
import game.core.draw;
import game.core.scrstart;
import game.core.speed;
import game.core.splatrul;
import game.core.tooltip;
import game.effect;
import game.exitwin;
import game.nurse.interact;
import game.panel.base;
import game.tweaker.tweaker;

import graphic.camera.mapncam;
import gui;
import hardware.display; // fps for framestepping speed
import hardware.music;
import hardware.sound;
import level.level;
import net.client.client;
import net.client.richcli;
import physics;

class Game : IRoot, NetClientObserver {
public:
    const(Level) level;

package:
    /*
     * The map does not hold the referential level image, that's
     * in cs.land and cs.lookup. Instead, the map loads a piece
     * of that land, blits gadgets and lixes on it, and blits the
     * result to the screen. It is both a renderer and a camera.
     */
    MapAndCamera map;

    InteractiveNurse nurse;
    EffectManager _effect; // never null, never the NullEffectSink
    RichClient _netClient; // null unless playing/observing multiplayer

    long altickLastPhyu;
    long _altickHighlightGoalsUntil; // starts at 0, which means don't highl.

    // When we have time-shifted away from the server, we set this variable,
    // and let the physics update function gradually pay back this dept.
    // Is > 0 if we have to speed up, is < 0 if we have to slow down.
    // Should always be zero in singleplayer.
    long _alticksToAdjust;

    // Assignments for the next update go in here, and are only written into
    // the replay right before the update happens. If the replay is cut off
    // by skill assignment, the undispatched data is not cut off with it.
    // If the replay is cut off by explicit cutting (LMB into empty space),
    // the undispatched data too is emptied.
    Ply[] undispatchedAssignments;

    ReallyExitWindow modalWindow;
    Panel pan;
    TooltipLine _panelExplainer;
    TooltipLine _mapClickExplainer;
    Tweaker _tweaker; // Never null, but often hidden
    ChatArea _chatArea;
    SplatRuler _splatRuler;
    bool _gotoMainMenu;

private:
    Phyu _setLastPhyuToNowLastCalled = Phyu(-1);

public:
    enum ticksNormalSpeed = ticksPerSecond / phyusPerSecondAtNormalSpeed;
    enum updatesAheadMany = ticksPerSecond / ticksNormalSpeed * 10;

    this(ArgsToCreateGame args)
    in {
        assert (args.level !is null);
        assert (args.level.playable,
            "Level is not playable. Don't create a Game for this.");
        assert (args.levelFilename !is null);
    }
    do {
        level = args.level;
        if (args.loadedReplay.empty) {
            commonConstructor(generateFreshReplay(some(args.levelFilename)));
        }
        else {
            commonConstructor(args.loadedReplay.front.clone());
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
        _netClient.register(this);
        commonConstructor(generateFreshReplay(no!Filename));
    }

    void dispose()
    {
        void rmElderAndNull(T)(ref T anElder)
        {
            if (anElder is null) {
                return;
            }
            gui.rmElder(anElder);
            anElder = null;
        }
        rmElderAndNull(pan);
        rmElderAndNull(_panelExplainer);
        rmElderAndNull(_mapClickExplainer);
        rmElderAndNull(_tweaker);
        rmElderAndNull(_chatArea);
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

    bool gotoMainMenu() const pure nothrow @safe @nogc { return _gotoMainMenu;}

    HalfTrophy halfTrophyOfLocalTribe() const
    {
        return nurse.trophyForTribe(localStyle);
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
        ret.unregister(this);
        return ret;
    }

    string filenamePrefixForScreenshot() const
    out (ret) { assert (ret != ""); }
    do {
        assert (nurse);
        assert (nurse.constReplay);
        foreach (fn; nurse.constReplay.levelFilename)
            if (fn.fileNoExtNoPre != "")
                return fn.fileNoExtNoPre;
        return nurse.constStateForDrawingOnly.multiplayer
            ? "multiplayer" : "singleplayer";
    }

    void work() { implGameCalc(this); }
    void calc() { /* Empty, really a hack, we decide in work() */ }

    // We always draw ourselves.
    void reqDraw() { }
    bool draw() {
        implGameDraw(this);
        return true; // We've always drawn land/lix, even when window-covered.
    }

package:
    static int updatesBackMany()
    {
        // This is (1/lag) * 1 second. No lag => displayFPS == ticksPerSecond.
        return (ticksPerSecond + 1) * ticksPerSecond
            /  (displayFps     + 1) / ticksNormalSpeed;
    }

    bool isMouseOnLand() const nothrow @safe @nogc
    {
        assert (pan);
        assert (_tweaker, "even if hidden, this should be non-null");
        return ! pan.isMouseHere && ! _tweaker.isMouseHere;
    }

    bool canWeClickAirNowToCutGlobalFuture() const
    {
        return view.canInterruptReplays
            && nurse.hasFuturePlies
            && isMouseOnLand
            && (_tweaker.shown
                ? opt.airClicksCutWhenTweakerShown.value
                : opt.airClicksCutWhenTweakerHidden.value);
    }

    bool multiplayer() const
    {
        return nurse.stateOnlyPrivatelyForGame.multiplayer;
    }

    Style localStyle() const @nogc nothrow
    in { assert (_effect, "create effect manager before querying style"); }
    do { return _effect.localTribe; }

    const(Tribe) localTribe() const
    {
        auto ptr = localStyle in cs.tribes;
        assert (ptr, "badly cloned cs? Local style isn't there");
        return *ptr;
    }

    View view() const pure nothrow @safe @nogc
    {
        assert (nurse && nurse.constReplay, "call view() after replay init");
        return createView(nurse.constReplay.numPlayers, _netClient);
    }

    void setLastPhyuToNow()
    {
        assert (this.nurse);
        if (_effect)
            _effect.deleteAfter(nurse.now);
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

    bool singleplayerHasNuked() const
    {
        return ! multiplayer && nurse && level && nurse.singleplayerHasNuked;
    }

private:
    auto cs() inout
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
        // After the nurse has been created here, this.view() works.

        initializePanel();
        initializeMapAndRepEdit();
        initializeConsole();
        stopMusic();
        _splatRuler = createSplatRuler();
        setLastPhyuToNow();
    }

    Replay generateFreshReplay(Optional!Filename levelFilename)
    {
        auto rp = levelFilename.match!(
            () => Replay.newNoLevelFilename(level.built),
            (fn) => Replay.newForLevel(fn, level.built));
        if (! _netClient) {
            Profile single;
            single.name = opt.userName;
            single.style = Style.garden;
            rp.addPlayer(PlNr(0), single);
        }
        else {
            rp.permu = _netClient.permu;
            foreach (plNr, prof; _netClient.profilesInOurRoom)
                if (prof.feeling != Profile.Feeling.observing)
                    rp.addPlayer(plNr, prof);
        }
        return rp;
    }

    Style determineLocalStyle(in Replay rp) const
    in { assert (rp); }
    do {
        if (rp.players.length == 0)
            return Style.garden;
        if (_netClient) {
            auto ptr = _netClient.ourPlNr in rp.players;
            if (ptr)
                return ptr.style;
        }
        foreach (plNr, pl; rp.players)
            if (pl.name == opt.userName)
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
        assert (_panelExplainer is null);
        assert (_mapClickExplainer is null);
        assert (_tweaker is null);
    }
    do {
        pan = new Panel(view, level.required);
        foreach (player; nurse.constReplay.players) {
            pan.add(player.style, player.name);
        }
        gui.addElder(pan);
        setLastPhyuToNow(); // to fill skills, needed for highlightFirstSkill
        pan.chooseLeftmostSkill();

        _panelExplainer = new TooltipLine(new Geom(0, panelYlg,
            screenXlg - Tweaker.suggestedTweakerXlg, 20, From.BOTTOM_RIGHT));
        _mapClickExplainer = new TooltipLine(new Geom(0, 0,
            screenXlg - Tweaker.suggestedTweakerXlg, 20, From.TOP_RIGHT));

        // Workaround for github #473: Tooltips and the big score board
        // don't get along. For now, hide tooltips in modes with the board.
        immutable bool github473
            = opt.ingameTooltips.value && ! view.showScoreGraph;
        _panelExplainer.shown = github473;
        _mapClickExplainer.shown = github473;
        gui.addElder(_panelExplainer);
        gui.addElder(_mapClickExplainer);

        _tweaker = new Tweaker(new Geom(0, 0, Tweaker.suggestedTweakerXlg,
            screenYlg - panelYlg, From.TOP_RIGHT));
        _tweaker.hide();
        gui.addElder(_tweaker);
    }

    void initializeMapAndRepEdit()
    in {
        assert (map is null);
    }
    do {
        immutable mapXls = gui.screenXls.to!int;
        immutable mapYls = (gui.screenYls - gui.panelYls).to!int;
        immutable tweXls
            = (Tweaker.suggestedTweakerXlg * gui.context.stretchFactor).to!int;
        map = new MapAndCamera(cs.land, enumap.enumap(
            MapAndCamera.CamSize.fullWidth, Point(mapXls, mapYls),
            MapAndCamera.CamSize.withTweaker, Point(mapXls - tweXls, mapYls)));
        this.centerCameraOnHatchAverage();
    }

    void initializeConsole()
    {
        assert (! _chatArea);
        _chatArea = new ChatArea(new Geom(0, 0, gui.screenXlg, 0),
            _netClient);
        gui.addElder(_chatArea);
    }

public: // Implementation of NetClientObserver
    void onConnectionLost()
    {
        // Maybe too drastic? Lobby will catch us.
        this._gotoMainMenu = true;
    };

    void onPeerSendsPly(in Ply peersIncomingPly)
    {
        this.undispatchedAssignments ~= peersIncomingPly;
    };

    // The server tells us how many milliseconds have passed.
    // The client adds his networking lag to that value, then calls the
    // observer with the thereby-increased value of milliseconds.
    // Thus, here in GameCallbacks, (millis) is already the added value.
    void onMillisecondsSinceGameStart(in int millis) {
        this.recordServersWishSinceGameStart(dur!"msecs"(millis));
    }

    void onConnect() {}
    void onCannotConnect() {}
    void onVersionMisfit(in Version serverVersion) {}
    void onChatMessage(in string peerName, in string chat) {}
    void onPeerDisconnect(in string peerName) {}
    void onPeerJoinsRoom(in Profile2022) {}
    void onPeerLeavesRoomTo(in string peerName, in Room toRoom) {}
    void onPeerChangesProfile(in Profile2022 old, in Profile2022 theNew) {}
    void onWeChangeRoom(in Room toRoom) {}
    void onListOfExistingRooms(in RoomListEntry2022[]) {}
    void onLevelSelect(in string peerNameOfChooser, in ubyte[] data) {}
    void onGameStart(in Permu) {}
}
