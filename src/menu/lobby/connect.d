module menu.lobby.connect;

/* The buttons shown when you enter the lobby dialog.
 * When you select one of these buttons, all vanish, and the program tries
 * to connect to a server.
 */

import std.string;

import basics.globconf;
import basics.user;
import gui;
import file.language;

class ConnectionPicker : Element {
private:
    TextButton _central;
    TextButton _custom;
    Texttype _customIP;

    void delegate(string ip) _onExecute;

public:
    this(Geom g)
    {
        super(g);
        _central = new TextButton(new Geom(0, 0, xlg, 40));
        _custom = new TextButton( new Geom(0, 60, xlg/2, 20));
        _customIP = new Texttype( new Geom(xlg/2, 60, xlg/2, 20));

        _central.text = Lang.winLobbyStartCentral.transl
                            ~ " " ~ ipCentralServer;
        _custom.text = Lang.winLobbyStartClient.transl;
        _customIP.text = ipLastUsed;
        _central.hotkey = keyMenuMainNetwork;
        _custom.hotkey = keyMenuMainSingle;
        _central.onExecute = () { _onExecute && _onExecute(ipCentralServer); };
        _custom.onExecute = () {
            ipLastUsed = _customIP.text.strip;
            _onExecute && _onExecute(ipLastUsed);
        };
        addChildren(_central, _custom, _customIP);
    }

    @property void onExecute(typeof(_onExecute) f) { _onExecute = f; }
}

