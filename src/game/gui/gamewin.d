module game.gui.gamewin;

import std.typecons; // Rebindable

import basics.user; // hotkeys
import file.language;
import game.replay;
import graphic.color;
import gui;
import hardware.sound;
import level.level;

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

    final void captionSuperElements()
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

    final void setReplayAndLevel(in Replay r, in Level l)
    {
        assert (_saveReplay, "instantiate _saveReplay before passing replay");
        _replay = r;
        _level  = l;
        _saveReplayDone = new Label(new Geom(_saveReplay.geom));
        _saveReplayDone.text = Lang.browserExportImageDone.transl;
        _saveReplayDone.hide();
        _saveReplay.onExecute = () {
            assert (_replay !is null);
            _replay.saveManually(_level);
            hardware.sound.playLoud(Sound.DISKSAVE);
            if (_saveReplayDone) {
                _saveReplay.undrawColor = color.guiM;
                _saveReplay.hide();
                _saveReplayDone.show();
            }
        };
        addChild(_saveReplayDone);
    }

private:

    Label _saveReplayDone;
    Rebindable!(const Replay) _replay;
    Rebindable!(const Level)  _level;

}
