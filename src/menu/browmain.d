module menu.browmain;

import game.replay;
import file.filename;
import gui.listlev;
import level.level;
import menu.browbase;

class BrowserCalledFromMainMenu : BrowserBase {

    // forward constructor :E
    this(
        in string      title,
        in Filename    baseDir,
           Filename    currentFile,
        ListLevel.LevelCheckmarks   lcm,
        ListLevel.ReplayToLevelName rtl
    ) {
        super(title, baseDir, currentFile, lcm, rtl);
    }

    @property bool          gotoGame()     const { return _gotoGame;     }
    @property inout(Replay) replayRecent() inout { return _replayRecent; }
    @property inout(Level)  levelRecent()  inout { return _levelRecent;  }

protected:

    @property bool   gotoGame(bool b)       { return _gotoGame     = b; }
    @property Replay replayRecent(Replay r) { return _replayRecent = r; }
    @property Level  levelRecent (Level l)  { return _levelRecent  = l; }

private:

    bool     _gotoGame;
    Replay   _replayRecent;
    Level    _levelRecent;
}
