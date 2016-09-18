module menu.lobby;

import std.algorithm;
import std.format;

import basics.globconf;
import basics.user;
import file.language;
import gui;
import menu.lobbyui;
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
    Texttype _chat;

    INetClient _netClient;
    Element[] _showWhenDisconnected; // Some elements are in neither this...
    Element[] _showWhenConnected;    // ...nor this array. They're always on.

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
            if (offline)
                _gotoMainMenu = true;
            disconnect();
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
        _roomList = new RoomList(new Geom(20, 40, 300, 20*8, From.TOP_RIG));
        _showWhenConnected ~= _roomList;
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

        _showWhenDisconnected.each!(e => addChild(e));
        _showWhenConnected.each!(e => addChild(e));
        showOrHideGuiBasedOnConnection();
    }

    bool gotoMainMenu() const { return _gotoMainMenu; }

protected:
    override void calcSelf()
    {
        if (_netClient)
            _netClient.calc();
        showOrHideGuiBasedOnConnection();
        scope (success)
            showOrHideGuiBasedOnConnection();

        if (_colorSelector.execute && _netClient) {
            // The color selector doesn't return execute == true when you
            // click the button that's already on.
            if (_colorSelector.spectating)
                _netClient.ourFeeling = Profile.Feeling.spectating;
            else
                _netClient.ourStyle = _colorSelector.style;
        }
    }

private:
    bool connected() const { return _netClient && _netClient.connected; }
    bool connecting() const { return _netClient && _netClient.connecting; }
    bool offline() const { return ! connected && ! connecting; }

    void showOrHideGuiBasedOnConnection()
    {
        _showWhenDisconnected.each!(e => e.shown = offline);
        _showWhenConnected.each!(e => e.shown = connected);
        _buttonExit.text = connected ? Lang.winLobbyDisconnect.transl
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

    void disconnect()
    {
        if (offline)
            return;
        _console.add(connected ? Lang.netChatYouLoggedOut.transl
                               : Lang.netChatStartCancel.transl);
        _netClient.disconnect();
        _netClient = null;
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
            _roomList.shown = toRoom == 0;
            if (toRoom == 0)
                // DTODONETWORK: do we recreateButtonsFor on this event?
                // Or do we have a different event for entering lobby?
                _roomList.recreateButtonsFor();
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
