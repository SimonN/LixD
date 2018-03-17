module menu.browser.frommain;

import game.replay;
import file.filename;
import gui;
import gui.picker;
import level.level;
import menu.browser.select;

class BrowserCalledFromMainMenu : BrowserHighlightSelect {
private:
    bool _gotoGame;

public:
    // forward constructor :E
    this(T)(string title, Filename baseDir, T t) { super(title, baseDir, t); }

    @property bool gotoGame() const { return _gotoGame; }
    @property inout(Replay) replayRecent() inout { return null; }
    abstract @property inout(Level) levelRecent() inout;

protected:
    @property bool gotoGame(bool b) { return _gotoGame = b; }

    auto pickerConfig() const
    {
        auto cfg = PickerConfig!LevelTiler();
        cfg.showSearchButton = true;
        return cfg;
    }
}
