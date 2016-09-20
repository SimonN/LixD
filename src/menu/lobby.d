module menu.lobby;

import std.algorithm;
import std.file;
import std.format;
import std.range;

import basics.globconf;
import basics.user;
import file.language;
import gui;
import hardware.mouse;
import menu.lobbyui;
import menu.browser.frommain;
import menu.browser.network;
import net.client;
import net.iclient;
import net.structs; // Profile

class Lobby : Window {
private:
    bool _gotoMainMenu;
    TextButton _buttonExit;
    TextButton _buttonCentral;

    Console _console;
    PeerList _peerList;
    ColorSelector _colorSelector;
    RoomList _roomList;
    BrowserCalledFromMainMenu _browser;

    TextButton _chooseLevel;
    Texttype _chat;

    INetClient _netClient;
    // Rule: A GUI element is either in exactly one of these, or in none.
    // _showWhenConnected is shown at the union of times when _showDuringLobby
    // and _showDuringGameRoom. Due to the rule, it nonetheless shouldn't
    // have anything that's in one of the other two.
    Element[] _showWhenDisconnected;
    Element[] _showWhenConnected;
    Element[] _showDuringLobby;
    Element[] _showDuringGameRoom;

public:
    this()
    {
        super(new Geom(0, 0, Geom.screenXlg, Geom.screenYlg),
            Lang.winLobbyTitle.transl);
        _buttonExit = new TextButton(new Geom(20, 20, 120, 20, From.BOT_RIG),
            Lang.commonBack.transl);
        _buttonExit.hotkey = basics.user.keyMenuExit;
        _buttonExit.onExecute = ()
        {
            if (connected && ! inLobby)
                _netClient.gotoExistingRoom(Room(0));
            else {
                if (offline)
                    _gotoMainMenu = true;
                disconnect();
            }
        };
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
        _chooseLevel = new TextButton(new Geom(20, 60+20*8, 120, 20,
            From.TOP_RIGHT), Lang.winLobbySelectLevel.transl);
        _chooseLevel.onExecute = ()
        {
            assert (! _browser);
            _browser = new BrowserNetwork();
            addFocus(_browser);
        };
        _chooseLevel.hotkey = keyMenuEdit;
        _showDuringGameRoom ~= _chooseLevel;
        _chat = new Texttype(new Geom(60, 20, // 40 = label, 60 = 3x GUI space
            Geom.screenXlg - _buttonExit.xlg - 40 - 60, 20, From.BOT_LEF));
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
        _showWhenConnected ~= new Label(new Geom(20, 20, 40, 20, From.BOT_LEF),
                                        Lang.winLobbyChat.transl);
        foreach (e; chain(_showWhenDisconnected, _showWhenConnected,
                          _showDuringLobby, _showDuringGameRoom))
            addChild(e);
        showOrHideGuiBasedOnConnection();
    }

    bool gotoMainMenu() const { return _gotoMainMenu; }

    void disconnect()
    {
        if (offline)
            return;
        if (_console)
            _console.add(connected ? Lang.netChatYouLoggedOut.transl
                                   : Lang.netChatStartCancel.transl);
        _netClient.disconnect();
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
            if (_colorSelector.spectating)
                _netClient.ourFeeling = Profile.Feeling.spectating;
            else
                _netClient.ourStyle = _colorSelector.style;
        }
        if (_roomList.executeExistingRoom)
            _netClient.gotoExistingRoom(_roomList.executeExistingRoomID);
        else if (_roomList.executeNewRoom)
            _netClient.createRoom();
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
    }

    void connect(in string hostname)
    {
        _console.add("%s %s:%d...".format(Lang.netChatStartClient.transl,
            hostname, basics.globconf.serverPort));
        NetClientCfg cfg;
        cfg.hostname = hostname;
        cfg.ourPlayerName = basics.globconf.userName;
        cfg.port = basics.globconf.serverPort;
        _netClient = new NetClient(cfg);
        setOurEventHandlers();
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

    // Keep this the last private function in this class, it's so long
    void setOurEventHandlers()
    {
        assert (_netClient);
        void refreshPeerList()
        {
            _peerList.recreateButtonsFor(_netClient.profilesInOurRoom.values);
            _colorSelector.style = _netClient.ourProfile.style;
            if (_netClient.ourProfile.feeling == Profile.Feeling.spectating)
                _colorSelector.setSpectating();
        }

        // We don't print anything on connecting. Entering the lobby will
        // generate a message anyway, including an update to the peer list.
        _netClient.onConnect = null;

        _netClient.onConnectionLost = ()
        {
            refreshPeerList();
            _console.add(Lang.netChatYouLostConnection.transl);
        };

        _netClient.onChatMessage = (string name, string chatMessage)
        {
            _console.addWhite("%s: %s".format(name, chatMessage));
        };

        _netClient.onPeerDisconnect = (string name)
        {
            refreshPeerList();
            _console.add("%s %s".format(name,
                                        Lang.netChatPeerDisconnected.transl));
        };

        _netClient.onPeerJoinsRoom = (const(Profile*) profile)
        {
            refreshPeerList();
            assert (profile, "the network shouldn't send null pointers");
            if (profile.room == 0)
                _console.add("%s %s".format(profile.name,
                    Lang.netChatPlayerInLobby.transl));
            else
                _console.add("%s %s%d%s".format(profile.name,
                    Lang.netChatPlayerInRoom.transl, profile.room,
                    Lang.netChatPlayerInRoom2.transl));
        };

        _netClient.onPeerLeavesRoomTo = (string name, Room toRoom)
        {
            refreshPeerList();
            if (toRoom == 0)
                _console.add("%s %s".format(name,
                    Lang.netChatPlayerOutLobby.transl));
            else
                _console.add("%s %s%d%s".format(name,
                    Lang.netChatPlayerOutRoom.transl, toRoom,
                    Lang.netChatPlayerOutRoom2.transl));
        };

        _netClient.onPeerChangesProfile = (const(Profile*))
        {
            refreshPeerList();
        };

        _netClient.onWeChangeRoom = (Room toRoom)
        {
            refreshPeerList();
            _console.add(toRoom != 0
                ? "%s%d%s".format(Lang.netChatWeInRoom.transl, toRoom,
                                  Lang.netChatWeInRoom2.transl)
                : Lang.netChatWeInLobby.transl);
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

        _netClient.onLevelSelect = (string name, const(ubyte[]) data)
        {
            refreshPeerList();
            _console.add("%s %s %s".format(name,
                Lang.netChatLevelChange.transl, "[NOT IMPLEMENTED]"));
        };

        _netClient.onGameStart = () {
            refreshPeerList();
            _console.add("[GAME START NOT IMPLEMENTED]");
        };
    }
}
