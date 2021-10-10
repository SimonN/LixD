module menu.browser.frommain;

import file.replay;
import file.filename;
import gui;
import gui.picker;
import level.level;
import menu.browser.select;
import menu.preview.base;
import menu.preview.fullprev;

class BrowserCalledFromMainMenu : BrowserHighlightSelect {
private:
    FullPreview _preview;
    bool _gotoGame;

public:
    // forward constructor :E
    this(T)(string title, Filename baseDir, T t) {
        super(title, baseDir, t);
        _preview = new FullPreview(
            new Geom(20, 60, infoXl, 240, From.TOP_RIG));
        addChild(_preview);
        previewNone();
    }

    // If you need to override this, add onDispose() and let dispose() call it.
    final void dispose()
    {
        if (_preview) {
            _preview.dispose();
        }
    }

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

    final void previewNone() { _preview.previewNone(); }
    final void preview(in Level lev) { _preview.preview(lev); }
    final void preview(in Replay r, in Level l) { _preview.preview(r, l); }

    final float trophyLineY()  const
    {
        assert (_preview);
        return _preview.yg + _preview.ylg;
    }
}
