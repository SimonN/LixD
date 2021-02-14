module menu.browser.frommain;

import file.replay;
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

    bool gotoGame() const pure nothrow @safe @nogc
    {
        return _gotoGame;
    }

    @property inout(Replay) replayRecent() inout { return null; }
    abstract @property inout(Level) levelRecent() inout;

protected:
    bool gotoGame(bool b) { return _gotoGame = b; }

    auto pickerConfig() const
    {
        auto cfg = PickerConfig!(Breadcrumb, LevelTiler)();
        cfg.showSearchButton = true;
        return cfg;
    }
}
