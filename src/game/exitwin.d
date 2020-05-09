module game.exitwin;

import file.option; // hotkeys
import file.language;
import gui;
import hardware.keyset;

class ReallyExitWindow : Window {
protected:
    TextButton _resume; // never null
    TextButton _exitGame; // never null

public:
    this()
    {
        enum butXl = 180;
        enum butYl = 20;
        super(new Geom(0, -gui.panelYlg / 2, butXl + 40, 110, From.CENTER),
            Lang.winAbortNetgameTitle.transl);
        _resume = new TextButton(new Geom(0, 40, butXl, butYl, From.TOP));
        _resume.text = Lang.winAbortNetgameContinuePlaying.transl;
        _resume.hotkey = KeySet(keyPause, keyGameExit);
        _exitGame = new TextButton(new Geom(0, 70, butXl, butYl, From.TOP));
        _exitGame.text = Lang.winAbortNetgameExitToLobby.transl;
        _exitGame.hotkey = keyMenuDelete;
        addChildren(_resume, _exitGame);
    }

    final bool resume() const { return _resume && _resume.execute; }
    final bool exitGame() const { return _exitGame && _exitGame.execute; }
}
