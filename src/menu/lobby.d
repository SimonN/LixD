module menu.lobby;

import std.algorithm;
import std.conv;
import std.file;
import std.format;
import std.range;

import basics.globconf;
import basics.user;
import file.language;
import gui;
import hardware.mouse;
import level.level;
import menu.lobbyui;
import menu.preview;
import menu.browser.frommain;
import menu.browser.network;
import net.client;
import net.iclient;
import net.permu;
import net.structs; // Profile
import net.versioning;

class Lobby : Window {
private:
    bool _gotoGame;
    bool _gotoMainMenu;
    TextButton _buttonExit;
    TextButton _buttonCentral;

    RichClient _netClient;
    Console _console;
    PeerList _peerList;
    ColorSelector _colorSelector;
    RoomList _roomList;
    Preview _preview;
    BrowserCalledFromMainMenu _browser;

    TextButton _chooseLevel;
    TextButton _declareReady;
    Texttype _chat;

    // Rule: A GUI element is either in exactly one of these, or in none.
    // _showWhenConnected is shown at the union of times when _showDuringLobby
    // and _showDuringGameRoom. Due to the rule, it nonetheless shouldn't
    // have anything that's in one of the other two.
    Element[] _showWhenDisconnected;
    Element[] _showWhenConnected;
    Element[] _showDuringLobby;
    Element[] _showDuringGameRoom;

public:
    this(RichClient aRichClient // existing client or null if not connected
    ) {
        super(new Geom(0, 0, Geom.screenXlg, Geom.screenYlg),
            Lang.winLobbyTitle.transl);
        _buttonExit = new TextButton(new Geom(20, 20, 120, 20, From.BOT_RIG),
            Lang.commonBack.transl);
        _buttonExit.hotkey = basics.user.keyMenuExit;
        _buttonExit.onExecute = () { onExitButtonExecute(); };
        addChild(_buttonExit);

        _console = new LobbyConsole(new Geom(0, 60, xlg-40, 160, From.BOTTOM));
        addChild(_console);

        _buttonCentral = new TextButton(new Geom(0, 40, 200, 40, From.TOP));
        _buttonCentral.text = Lang.winLobbyStartCentral.transl;
        _buttonCentral.hotkey = keyMenuMainNetwork;
        _buttonCentral.onExecute = () { connect(ipCentralServer); };
        _showWhenDisconnected ~= _buttonCentral;

        _peerList = new PeerList(new Geom(20, 40, 120, 20*8));
        _showWhenConnected ~= _peerList;
        _colorSelector = new ColorSelector(new Geom(160, 40, 40, 20*8));
        _showWhenConnected ~= _colorSelector;
        _roomList = new RoomList(new Geom(20, 40, 300, 20*8, From.TOP_RIGHT));
        _showDuringLobby ~= _roomList;
        _preview = new Preview(new Geom(_roomList.geom));
        _showDuringGameRoom ~= _preview;

        enum midButtonsY = 60+20*8;
        _declareReady = new TextButton(new Geom(20, midButtonsY,
            _peerList.xlg, 20), Lang.winLobbyReady.transl);
        _declareReady.hotkey = keyMenuOkay;
        addChild(_declareReady);
        // See showOrHideGuiBasedOnConnection for particular showing/hiding,
        // because _declareReady isn't in any of the _showXyz arrays

        _chooseLevel = new TextButton(new Geom(20, midButtonsY, 120, 20,
            From.TOP_RIGHT), Lang.winLobbySelectLevel.transl);
        _chooseLevel.onExecute = ()
        {
            assert (! _browser);
            _browser = new BrowserNetwork();
            addFocus(_browser);
        };
        _chooseLevel.hotkey = keyMenuEdit;
        _showDuringGameRoom ~= _chooseLevel;

        enum chatLabelXl = 50;
        _chat = new Texttype(new Geom(20 + chatLabelXl, 20,
            Geom.screenXlg - _buttonExit.xlg - chatLabelXl - 60,
            20, From.BOT_LEF));
        _chat.onEnter = ()
        {
            if (_chat.text == "")
                return;
            assert (connected);
            _netClient.sendChatMessage(_chat.text);
            _chat.text = "";
        };
        _chat.onEsc = () { _chat.text = ""; };
        _chat.hotkey = basics.user.keyChat;
        _showWhenConnected ~= _chat;
        _showWhenConnected ~= new Label(new Geom(20, 20, chatLabelXl,
                                20, From.BOT_LEF), Lang.winLobbyChat.transl);
        foreach (e; chain(_showWhenDisconnected, _showWhenConnected,
                          _showDuringLobby, _showDuringGameRoom))
            addChild(e);

        if (aRichClient) {
            _netClient = aRichClient;
            _netClient.console = _console;
            setOurEventHandlers();
            _preview.level = _netClient.level;
            _chat.text = _netClient.unsentChat;
            _netClient.unsentChat = "";
            refreshPeerList();
        }
        showOrHideGuiBasedOnConnection();
    }

    @property gotoMainMenu() const { return _gotoMainMenu; }
    @property gotoGame() const { return _gotoGame && _netClient; }

    auto loseOwnershipOfRichClient()
    {
        assert (_netClient, "shouldn't lose ownership of null client");
        auto ret = _netClient;
        nullOurEventHandlers();
        _netClient = null;
        _gotoGame = false;
        _chat.on = false;
        ret.unsentChat = _chat.text;
        return ret;
    }

    void disconnect()
    {
        if (offline)
            return;
        if (_console)
            _console.add(connected ? Lang.netChatYouLoggedOut.transl
                                   : Lang.netChatStartCancel.transl);
        _netClient.disconnectAndDispose();
        _netClient = null;
    }

protected:
    // Do this even with a level browser in focus
    override void workSelf()
    {
        if (_browser && (_browser.gotoGame || _browser.gotoMainMenu)) {
            assert (_netClient);
            if (_browser.gotoGame)
                _netClient.selectLevel(_browser.fileRecent.readIntoVoidArray);
            rmFocus(_browser);
            destroy(_browser);
            _browser = null;
        }
        if (_netClient)
            _netClient.calc();
    }

    // Do this only when there is no level browser
    override void calcSelf()
    {
        showOrHideGuiBasedOnConnection();
        handleRightClick();
        if (! _netClient)
            return;
        scope (success)
            showOrHideGuiBasedOnConnection();

        if (_colorSelector.execute) {
            // The color selector doesn't return execute == true when you
            // click the button that's already on.
            if (_colorSelector.observing)
                _netClient.ourFeeling = Profile.Feeling.observing;
            else {
                _netClient.ourStyle = _colorSelector.style;
                basics.user.networkLastStyle = _colorSelector.style;
            }
        }
        if (_roomList.executeExistingRoom)
            _netClient.gotoExistingRoom(_roomList.executeExistingRoomID);
        else if (_roomList.executeNewRoom)
            _netClient.createRoom();
        if (_declareReady.execute) {
            assert (_netClient, "declare ready without net client running");
            assert (_netClient.mayWeDeclareReady, "declare ready disallowed");
            if (_declareReady.on) {
                _declareReady.on = false;
                _netClient.ourFeeling = Profile.Feeling.thinking;
            }
            else {
                _declareReady.on = true;
                _netClient.ourFeeling = Profile.Feeling.ready;
            }
        }
    }

private:
    bool connected() const { return _netClient && _netClient.connected; }
    bool connecting() const { return _netClient && _netClient.connecting; }
    bool offline() const { return ! connected && ! connecting; }
    bool inLobby() const { return connected && _netClient.ourProfile.room ==0;}

    void showOrHideGuiBasedOnConnection()
    {
        _showWhenDisconnected.each!(e => e.shown = offline);
        _showWhenConnected   .each!(e => e.shown = connected);
        _showDuringLobby     .each!(e => e.shown = connected && inLobby);
        _showDuringGameRoom  .each!(e => e.shown = connected && ! inLobby);
        _buttonExit.text = inLobby ? Lang.winLobbyDisconnect.transl
                       : connected ? Lang.winLobbyRoomLeave.transl
                      : connecting ? Lang.commonCancel.transl
                                   : Lang.commonBack.transl;
        if (! connected || inLobby)
            // See also refreshPeerList for visibility of this button
            _declareReady.shown = false;
    }

    void connect(in string hostname)
    {
        NetClientCfg cfg;
        cfg.hostname = hostname;
        cfg.ourPlayerName = basics.globconf.userName;
        try
            cfg.ourStyle = basics.user.networkLastStyle.value.to!Style;
        catch (Exception)
            // Both client and server handle illegal values and will give
            // us a legal default value
            { }
        cfg.port = basics.globconf.serverPort;
        _netClient = new RichClient(new NetClient(cfg), _console);
        setOurEventHandlers();
        _console.add("Lix %s, enet %s. %s %s:%d...".format(gameVersion,
            _netClient.enetLinkedVersion, Lang.netChatStartClient.transl,
            hostname, cfg.port));
    }

    // This is dubious. Nepster suggests that we shouldn't treat RMB special
    // ever, because it should be remappable.
    void handleRightClick()
    {
        if (! hardware.mouse.mouseClickRight)
            return;
        if (offline)
            _gotoMainMenu = true;
        else if (connecting)
            disconnect();
    }

    void onExitButtonExecute()
    {
        if (connected && ! inLobby) {
            _netClient.gotoExistingRoom(Room(0));
            _preview.level = null;
        }
        else {
            if (offline)
                _gotoMainMenu = true;
            disconnect();
        }
    }

    void refreshPeerList()
    {
        _peerList.recreateButtonsFor(_netClient.profilesInOurRoom.values);
        _colorSelector.style = _netClient.ourProfile.style;
        if (_netClient.ourProfile.feeling == Profile.Feeling.observing)
            _colorSelector.setObserving();
        _declareReady.shown = _netClient.mayWeDeclareReady;
        _declareReady.on = _netClient.ourProfile.feeling
                            == Profile.Feeling.ready;
    }

    // Keep this the last private function in this class, it's so long
    void setOurEventHandlers()
    {
        assert (_netClient);

        // We don't print anything on connecting. Entering the lobby will
        // generate a message anyway, including an update to the peer list.
        _netClient.onConnect = null;
        _netClient.onCannotConnect = () { _netClient = null; };
        _netClient.onConnectionLost = () { _netClient = null; };
        _netClient.onPeerDisconnect = (string name) { refreshPeerList(); };
        _netClient.onPeerJoinsRoom = (const(Profile*) profile)
        {
            refreshPeerList();
        };

        _netClient.onPeerLeavesRoomTo = (string name, Room toRoom)
        {
            refreshPeerList();
            // If we're in the lobby, we'll get another packet with the
            // new possible rooms.
        };

        _netClient.onPeerChangesProfile = (const(Profile*))
        {
            refreshPeerList();
        };

        _netClient.onWeChangeRoom = (Room toRoom)
        {
            refreshPeerList();
            // We will later get a packet that tells us the rooms in the lobby.
            // Until then, don't show anything in this list. If we're not
            // in the lobby, the room list shouldn't even be shown anyway.
            _roomList.clearButtons();
        };

        _netClient.onListOfExistingRooms = (const(Room[]) rooms,
                                            const(Profile[]) profiles
        ) {
            _roomList.recreateButtonsFor(rooms, profiles);
        };

        _netClient.onLevelSelect = (string senderName, const(ubyte[]) data)
        {
            refreshPeerList();
            _preview.level = _netClient.level;
            _console.add("%s %s %s".format(senderName,
                Lang.netChatLevelChange.transl, _netClient.level.name));
        };

        _netClient.onGameStart = (Permu permu) {
            refreshPeerList();
            _console.add("Game starts! Permutation: " ~ permu.toString);
            _gotoGame = true;
        };
    }

    void nullOurEventHandlers()
    {
        assert (_netClient, "null only when we own a netClient");
        _netClient.onConnect = null;
        _netClient.onCannotConnect = null;
        _netClient.onConnectionLost = null;
        _netClient.onPeerDisconnect = null;
        _netClient.onPeerJoinsRoom = null;
        _netClient.onPeerLeavesRoomTo = null;
        _netClient.onPeerChangesProfile = null;
        _netClient.onWeChangeRoom = null;
        _netClient.onListOfExistingRooms = null;
        _netClient.onLevelSelect = null;
        _netClient.onGameStart = null;
    }
}
