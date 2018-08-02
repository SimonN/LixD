module menu.lobby.connect;

/* The buttons shown when you enter the lobby dialog.
 * When you select one of these buttons, all vanish, and the program tries
 * to connect to a server.
 */

import std.string;

import file.option;
import file.option;
import gui;
import file.language;

class ConnectionPicker : Element {
private:
    RadioButtons _radio;
    TextButton _connect;
    Texttype _customIP;

    void delegate(string ip) _onExecute;

public:
    this(Geom g)
    {
        super(g);
        _radio = new RadioButtons(new Geom(0, 0, xlg, 40));
        _connect = new TextButton( new Geom(0, 0, 100, 40, From.BOTTOM));
        _customIP = new Texttype( new Geom(0, 20, xlg/2, 20, From.TOP_RIGHT));

        _customIP.allowScrolling = true;
        _customIP.text = networkIpLastUsed.strip;
        _customIP.onEnter = () { connectToCustomIP(); };

        _radio.addChoice(Lang.winLobbyStartCentral.transl
                            ~ " (" ~ ipCentralServer ~ ")");
        _radio.addChoice(Lang.winLobbyStartCustom.transl);
        _radio.onExecute = (int chosen) {
            _customIP.shown = _customIP.on = (chosen == 1);
        };
        _radio.choose(networkPreferCustom.value ? 1 : 0);

        _connect.text = Lang.winLobbyStartConnect.transl;
        _connect.hotkey = keyMenuMainNetwork;
        _connect.onExecute = () {
            if (! _onExecute)
                return;
            else if (_radio.chosen == 0) {
                networkPreferCustom.value = false;
                _onExecute(ipCentralServer);
            }
            else
                connectToCustomIP();
        };
        addChildren(_radio, _connect, _customIP);
    }

    @property void onExecute(typeof(_onExecute) f) { _onExecute = f; }

private:
    void connectToCustomIP()
    {
        if (_customIP.text.strip.empty) {
            _customIP.on = true;
            return;
        }
        networkPreferCustom.value = true;
        networkIpLastUsed = _customIP.text.strip;
        _onExecute(networkIpLastUsed);
    }
}

