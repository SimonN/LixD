module game.gui.gamewin;

import std.typecons; // Rebindable
import std.string; // package class

import basics.alleg5; // package class, hotkeyNiceShort
import basics.user; // hotkeys
import file.filename;
import file.language;
import game.replay;
import gui;
import hardware.keyboard; // package class
import hardware.sound;
import level.level;

// This is a bit of a hackjob. Maybe button hotkeys should be implemented
// with the decorator pattern. Then this becomes two decorators stacked.
package class TextButtonMenuOkayIsSecondHotkey : TextButton {
    this(Geom g, string caption = "") { super(g, caption); }
    override @property bool execute() const {
        return super.execute || keyMenuOkay.keyTapped;
    }
    protected override string hotkeyString() const {
        return "%s/%s".format(hotkeyNiceShort(keyMenuOkay),
                              hotkeyNiceShort(super.hotkey));
    }
}

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

    final void setReplayAndLevel(
        const(Replay)   rep,
        const(Filename) levFn,
        const(Level)    lev,
    ) {
        assert (_saveReplay, "instantiate _saveReplay before passing replay");
        _replay = rep;
        _level  = lev;
        _levelFilename = levFn,
        _saveReplayDone = new Label(new Geom(_saveReplay.geom));
        _saveReplayDone.text = Lang.browserExportImageDone.transl;
        _saveReplayDone.hide();
        _saveReplay.onExecute = () {
            assert (_replay !is null);
            _replay.saveManually(_levelFilename, _level);
            hardware.sound.playLoud(Sound.DISKSAVE);
            if (_saveReplayDone) {
                _saveReplay.hide();
                _saveReplayDone.show();
            }
        };
        addChild(_saveReplayDone);
    }

private:

    Label _saveReplayDone;
    Rebindable!(const Replay)   _replay;
    Rebindable!(const Level)    _level;
    Rebindable!(const Filename) _levelFilename;
}
