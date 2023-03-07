module menu.lobby.connect;

/*
 * The buttons shown when you enter the lobby dialog.
 * When you select one of these options, then click Okay, all options vanish,
 * and the program tries to connect to a server.
 *
 * You must provide a non-null function for _onOkay when you create this.
 * see its private section.
 *
 * You must provide a non-null function for _onMissingEnetDLL.
 */

import std.conv;
import std.string;

import gui;
import file.language;
import file.option;
import hardware.keyset;
import net.client.client;
import net.client.impl;
import net.client.withserv;
import net.versioning;

class ConnectionPicker : Element {
private:
    RadioButtons _radio;
    TextButton _connect;

    LabelledFixableTexttype _hostname;
    LabelledFixableTexttype _port;

    // When the user presses Okay, we will create an INetClient.
    // To pass this INetClient to our owner, the owner should provide this
    // delegate here, and we will call this delegate with the INetClient.
    // We pass the NetClientCfg only for our owner's convenience: The owner
    // does not have to create a client from that config, we already did that,
    // but the owner might display information to the user.
    void delegate(INetClient, NetClientCfg) _onOkay;
    void delegate(Exception) _onEnetDLLMissing;

public:
    this(
        Geom g,
        void delegate(INetClient, NetClientCfg) aOnOkay,
        void delegate(Exception) aOnEnetDLLMissing
    )
    in {
        assert (aOnEnetDLLMissing !is null, "pass non-null onMissingEnetDLL");
        assert (aOnOkay !is null,
            "pass non-null onOkay, see comments at top and on _onOkay");
    }
    do {
        super(g);
        _onOkay = aOnOkay;
        _onEnetDLLMissing = aOnEnetDLLMissing;

        _hostname = new LabelledFixableTexttype(
            new Geom(0, 80, xlg/2, 40, From.TOP_LEFT),
            Texttype.AllowedChars.unicode);
        _hostname.title = Lang.winLobbyTitleAddress.transl;
        _hostname.onEnter = &this.connect;

        _port = new LabelledFixableTexttype(
            new Geom(0, 80, xlg/2, 40, From.TOP_RIGHT),
            Texttype.AllowedChars.digits);
        _port.title = Lang.winLobbyTitlePort.transl;
        _port.onEnter = &this.connect;

        _radio = new RadioButtons(new Geom(0, 0, xlg, 40));
        _radio.addChoice(Lang.winLobbyStartCentral.transl);
        _radio.addChoice(Lang.winLobbyStartServer.transl);
        _radio.addChoice(Lang.winLobbyStartCustom.transl);
        _radio.onExecute = &this.handleChosenRadioButton;
        _radio.choose(networkConnectionMethod);

        _connect = new TextButton( new Geom(0, 0, 100, 40, From.BOTTOM));
        _connect.text = Lang.commonOk.transl;
        _connect.hotkey = KeySet(keyMenuOkay, keyMenuMainNetwork);
        _connect.onExecute = &this.connect;

        addChildren(_radio, _connect, _hostname, _port);
    }

private:
    void handleChosenRadioButton(int chosen)
    {
        switch (chosen) {
        case 0:
            _hostname.show();
            _hostname.fixedValue = networkCentralServerAddress;
            _port.fixedValue = networkCentralServerPort.value.to!string;
            break;
        case 1:
            _hostname.hide();
            _hostname.fixedValue = networkOwnServerAddress;
            _port.customValue = networkOwnServerPort.value.to!string;
            break;
        case 2:
            _hostname.show();
            _hostname.customValue = networkConnectToAddress;
            _port.customValue = networkConnectToPort.value.to!string;
            break;
        default:
            assert (false, "unhandled radio button");
        }
    }

    void connect()
    {
        if (_hostname.value.empty || _port.number == 0) {
            return;
        }
        NetClientCfg cfg = NetClientCfg();
        cfg.hostname = _hostname.value;
        cfg.port = _port.number;
        cfg.clientVersion = gameVersion;
        cfg.ourPlayerName = file.option.userName;
        try
            cfg.ourStyle = file.option.networkLastStyle.value.to!Style;
        catch (Exception)
            // Both client and server handle illegal values and will give
            // us a legal default value
            { }

        networkConnectionMethod = _radio.theChosen;

        INetClient ret;
        try {
            switch (_radio.theChosen) {
            case 0:
                ret = new NetClient(cfg);
                break;
            case 1:
                networkOwnServerPort = _port.number;
                ret = new ClientWithServer(cfg);
                break;
            case 2:
                networkConnectToAddress = _hostname.value;
                networkConnectToPort = _port.number;
                ret = new NetClient(cfg);
                break;
            default:
                assert (false, "unhandled radio button during connection");
            }
            // If no DLL exception thrown by the new'ing:
            _onOkay(ret, cfg);
        }
        catch (Exception e) {
            _onEnetDLLMissing(e);
        }
    }
}

private:

class LabelledFixableTexttype : Element {
private:
    Label _title;
    Label _fixed;
    Texttype _custom;

    invariant()
    {
        if (_fixed is null || _custom is null)
            return;
        assert (_fixed.shown != _custom.shown);
    }

public:
    this(Geom g, Texttype.AllowedChars alch)
    {
        super(g);
        _title = new Label(new Geom(0, 0, xlg, ylg/2f, From.TOP));
        _fixed = new Label(new Geom(0, 0, xlg, ylg/2f, From.BOTTOM));
        _fixed.undrawBeforeDraw = true;
        _custom = new Texttype(new Geom(0, 0, xlg, ylg/2f, From.BOTTOM));
        _custom.allowScrolling = true;
        _custom.allowedChars = alch;
        _custom.hide();
        addChildren(_title, _fixed, _custom);
    }

    @property string title() const { return _title.text; }
    @property string title(string s)
    {
        _title.text = s.strip;
        return s;
    }

    @property string value() const
    {
        return _fixed.shown ? _fixed.text.strip : _custom.text.strip;
    }

    @property int number() const nothrow
    {
        try {
            return value.to!int;
        }
        catch (Exception) {
            return 0;
        }
    }

    @property string fixedValue(string s)
    {
        _custom.on = false;
        _custom.hide();
        _fixed.show();
        _fixed.text = s.strip;
        return s;
    }

    @property string customValue(string s)
    {
        _fixed.hide();
        _custom.show();
        _custom.text = s.strip;
        return s;
    }

    @property bool on() const { return _custom.shown && _custom.on; }
    @property bool on(bool b)
    {
        _fixed.hide();
        _custom.show();
        return _custom.on = b;
    }

    @property void onEnter(void delegate() f) { _custom.onEnter = f; }
}
