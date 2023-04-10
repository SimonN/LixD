module menu.lobby.lobby;

import std.algorithm;
import std.range;
import std.string;

import opt = file.option.allopts;
import file.language;
import file.log;
import gui;
import hardware.mouse;
import hardware.sound;
import menu.lobby.topleft;
import menu.lobby.connect;
import menu.lobby.handicap;
import menu.lobby.lists : RoomList;
import menu.preview.thumbn;
import menu.browser.frommain;
import menu.browser.network;
import net.client.client;
import net.client.richcli;
import net.handicap;

class Lobby : Window, NetClientObserver {
private:
    bool _gotoGame;
    bool _gotoMainMenu;
    TextButton _buttonExit;
    ConnectionPicker _connections;

    RichClient _netClient;
    Console _console;
    TopLeftUI _topLeft;
    RoomList _roomList;
    LevelThumbnail _preview;
    Label _levelTitle;
    BrowserCalledFromMainMenu _browser;

    TextButton _chooseLevel;
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
    // Create Lobby that is not connected
    this() {
        super(new Geom(0, 0, gui.screenXlg, gui.screenYlg),
            Lang.winLobbyTitle.transl);
        commonConstructor();
        showOrHideGuiBasedOnConnection();
    }

    // Create Lobby after finishing a game
    this(RichClient aRichClient)
    in { assert(aRichClient, "RichClient should exist after a netgame"); }
    do {
        super(new Geom(0, 0, gui.screenXlg, gui.screenYlg),
            Lang.winLobbyTitle.transl);
        commonConstructor();

        aRichClient.console = _console;
        // Game's RichClient will always return to use here, usually still
        // connected. Sometimes, the connection dropped, then we get an
        // unconnected RichClient -- we don't want this in _netClient.
        if (aRichClient.connected) {
            _netClient = aRichClient;
            _netClient.register(this);
            _preview.preview(_netClient.level);
            _levelTitle.text = _netClient.level ? _netClient.level.name : "";
            _chat.text = _netClient.unsentChat;
            _netClient.unsentChat = "";
            _chat.on = _chat.text != "";
            refreshPeerList();
        }
        showOrHideGuiBasedOnConnection();
    }

    const pure nothrow @safe @nogc {
        bool gotoMainMenu() { return _gotoMainMenu; }
        bool gotoGame() { return _gotoGame && _netClient; }
    }

    auto loseOwnershipOfRichClient()
    {
        assert (_netClient, "shouldn't lose ownership of null client");
        _netClient.unregister(this);
        auto ret = _netClient;
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
            destroySubwindows();
        }
        if (_topLeft.execute) { // must be in workSelf(), reason: Handi focuses
            immutable wish = _topLeft.chosenProfile;
            opt.networkLastStyle = wish.style;
            _netClient.setOurProfile(wish);
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
        handleRoomList();
        showOrHideGuiBasedOnConnection();
    }

private:
    void commonConstructor()
    {
        _buttonExit = new TextButton(new Geom(20, 20, 120, 20, From.BOT_RIG),
            Lang.commonBack.transl);
        _buttonExit.hotkey = opt.keyMenuExit.value;
        _buttonExit.onExecute = &this.onExitButtonExecute;
        addChild(_buttonExit);

        _console = new LobbyConsole(new Geom(0, 60, xlg-40, 160, From.BOTTOM));
        addChild(_console);

        _connections = new ConnectionPicker(
            new Geom(0, 40, 320,180,From.TOP),
            &this.acceptConnection,
            &this.onEnetDLLMissing);
        _showWhenDisconnected ~= _connections;

        _topLeft = new TopLeftUI(new Geom(20, 40, 300, 20*8 + 20 + 20));
        _showWhenConnected ~= _topLeft;
        _roomList = new RoomList(new Geom(20, 40,
            xlg - 3*20 - _topLeft.xlg, 20*8, From.TOP_RIGHT));
        _showDuringLobby ~= _roomList;

        _preview = new LevelThumbnail(new Geom(_roomList.geom));
        _showDuringGameRoom ~= _preview;

        enum midButtonsY = 60+20*8;
        _chooseLevel = new TextButton(new Geom(20, midButtonsY,
            (_roomList.xlg - 20) / 2f, 20, From.TOP_RIGHT),
            Lang.winLobbySelectLevel.transl);
        _chooseLevel.onExecute = ()
        {
            assert (! _browser);
            _browser = new BrowserNetwork();
            addFocus(_browser);
        };
        _chooseLevel.hotkey = opt.keyMenuEdit.value;
        _showDuringGameRoom ~= _chooseLevel;

        _levelTitle = new Label(new Geom(30 + _chooseLevel.xlg,
            midButtonsY, 300, 20, From.TOP_RIGHT));
        _levelTitle.undrawBeforeDraw = true;
        _showDuringGameRoom ~= _levelTitle;

        enum chatLabelXl = 50;
        _chat = new Texttype(new Geom(20 + chatLabelXl, 20,
            gui.screenXlg - _buttonExit.xlg - chatLabelXl - 60,
            20, From.BOT_LEF));
        _chat.allowScrolling = true;
        _chat.onEnter = ()
        {
            if (_chat.text == "")
                return;
            assert (connected);
            _netClient.sendChatMessage(_chat.text);
            _chat.text = "";
        };
        _chat.onEsc = () { _chat.text = ""; };
        _chat.hotkey = opt.keyChat.value;
        _showWhenConnected ~= _chat;
        _showWhenConnected ~= new Label(new Geom(20, 20, chatLabelXl,
                                20, From.BOT_LEF), Lang.winLobbyChat.transl);
        foreach (e; chain(_showWhenDisconnected, _showWhenConnected,
                          _showDuringLobby, _showDuringGameRoom))
            addChild(e);
    }

    bool connected() const { return _netClient && _netClient.connected; }
    bool connecting() const { return _netClient && _netClient.connecting; }
    bool offline() const { return ! connected && ! connecting; }
    bool inLobby() const { return connected && _netClient.ourRoom == Room(0); }

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

    void acceptConnection(INetClient cli, NetClientCfg cfgThatWasUsed)
    {
        _netClient = new RichClient(cli, _console);
        _netClient.register(this);
        _console.add("Lix %s, enet %s. %s %s:%d...".format(
            cfgThatWasUsed.clientVersion,
            _netClient.enetLinkedVersion, Lang.netChatStartClient.transl,
            cfgThatWasUsed.hostname, cfgThatWasUsed.port));
    }

    void onEnetDLLMissing(Exception e)
    {
        string msg = Lang.netChatEnetDLLMissing.transl
            ~ " " ~ e.msg.tr("\x09\x0A\x0D", "   ", "d");
        _console.add(msg);
        log(msg);
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

    void handleRoomList()
    {
        if (_roomList.executeExistingRoom) {
            const roomEntry = _roomList.executeExistingRoomEntry;
            if (roomEntry.owner.clientVersion.compatibleWith(gameVersion)) {
                _netClient.gotoExistingRoom(roomEntry.room);
            }
            else {
                _netClient.printVersionMisfitFor(roomEntry);
            }
        }
        else if (_roomList.executeNewRoom) {
            _netClient.createRoom();
        }
    }

    void onExitButtonExecute()
    {
        if (connected && ! inLobby) {
            _netClient.gotoExistingRoom(Room(0));
            _preview.previewNone();
            _levelTitle.text = "";
        }
        else {
            if (offline)
                _gotoMainMenu = true;
            disconnect();
        }
    }

    void refreshPeerList()
    {
        _topLeft.showInList(_netClient.profilesInOurRoom.values);
        _topLeft.choose(_netClient.ourProfile);
        _topLeft.allowToDeclareReady = _netClient.mayWeDeclareReady;
    }

    void destroySubwindows()
    {
        _topLeft.destroyHandicapWindow();
        if (! _browser)
            return;
        rmFocus(_browser);
        destroy(_browser);
        _browser = null;
    }

// ##### Implementation of NetClient ##########################################
public:
    // We don't print anything on connecting. Entering the lobby will
    // generate a message anyway, including an update to the peer list.
    void onConnect() {}
    void onCannotConnect()  { _netClient.unregister(this); _netClient = null; }
    void onVersionMisfit(in Version) {} // Console will print it
    void onConnectionLost()
    {
        destroySubwindows();
        _netClient.unregister(this);
        _netClient = null;
    }

    void onChatMessage(in string, in string) {} // Console will print it
    void onPeerDisconnect(in string) { refreshPeerList(); }
    void onPeerJoinsRoom(in Profile profile)
    {
        refreshPeerList();
        playLoud(Sound.JOIN);
    }

    void onPeerLeavesRoomTo(in string peerName, in Room toRoom)
    {
        refreshPeerList();
        // If we're in the lobby, we'll get another packet with the
        // new possible rooms.
    }

    void onPeerChangesProfile(in Profile2022 old, in Profile2022 next)
    {
        refreshPeerList();
        if (old.handicap == next.handicap) {
            return;
        }
        _console.add(next.handicap == Handicap.init
            ? Lang.netChatHandicapUnset.translf(next.name)
            : Lang.netChatHandicapSet.translf(next.name,
                next.handicap.toUiTextLongAndHelpful));
    }

    void onWeChangeRoom(in Room toRoom)
    {
        refreshPeerList();
        // We will later get a packet that tells us the rooms in the lobby.
        // Until then, don't show anything in this list. If we're not
        // in the lobby, the room list shouldn't even be shown anyway.
        _roomList.clearButtons();
    }

    void onListOfExistingRooms(in RoomListEntry2022[] rooms)
    {
        _roomList.recreateButtonsFor(rooms);
    }

    void onLevelSelect(in string senderName, in ubyte[] data)
    {
        refreshPeerList();
        _preview.preview(_netClient.level);
        _levelTitle.text = _netClient.level.name;
        _console.add(Lang.netChatLevelChange.translf(
            senderName, _netClient.level.name));
        playLoud(Sound.pageTurn);
    }

    void onGameStart(in Permu permu)
    {
        refreshPeerList();
        destroySubwindows(); // Or observing players get stuck in their browser
        _console.add(Lang.netGameHowToChat.translf(
            opt.keyChat.value.nameLong));
        _gotoGame = true;
    }

    void onPeerSendsPly(in Ply) {}
    void onMillisecondsSinceGameStart(in int millis) {}
}
