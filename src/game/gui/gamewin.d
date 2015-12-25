module game.gui.gamewin;

import basics.user; // hotkeys
import file.language;
import gui;

abstract class GameWindow : Window {

    this(Geom g)               { super(g, Lang.winGameTitle.transl); }
    this(Geom g, string title) { super(g, title); }

    final bool resume()   { return _resume   && _resume.execute;   }
    final bool restart()  { return _restart  && _restart.execute;  }
    final bool exitGame() { return _exitGame && _exitGame.execute; }

protected:

    TextButton _resume;
    TextButton _saveReplay;
    TextButton _restart;
    TextButton _exitGame;

    void captionGameWindowButtons()
    {
        void oneBut(ref TextButton b, in string cap, in int hk)
        {
            if (! b)
                return;
            b.text   = cap;
            b.hotkey = hk;

            addChild(b);
        }
        oneBut(_resume,     Lang.winGameResume.transl,     keyPause);
        oneBut(_saveReplay, Lang.winGameSaveReplay.transl, keyStateSave);
        oneBut(_restart,    Lang.winGameRestart.transl,    keyRestart);
        oneBut(_exitGame,   Lang.winGameMenu.transl,       keyGameExit);
    }

}
