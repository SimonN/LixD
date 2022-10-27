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
    this(SomePickerCfg)(
        in string title,
        in Filename baseDir,
        in float ylOfNameplate,
        SomePickerCfg cfg,
    ) {
        super(title, baseDir, cfg);
        _preview = new FullPreview(
            new Geom(20, 60, infoXl, 160f + 20f + ylOfNameplate, From.TOP_RIG),
            20f, ylOfNameplate);
        _preview.setUndrawBeforeDraw();
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
    enum float ylOfNameplateForLevels = 60f;
    enum float ylOfNameplateForReplays = 80f;

    bool gotoGame(bool b) { return _gotoGame = b; }

    auto pickerConfig() const
    {
        auto cfg = PickerConfig!(Breadcrumb, LevelTiler)();
        cfg.showSearchButton = true;
        return cfg;
    }

    final void previewNone() { _preview.previewNone(); }
    final void preview(in Level lev) { _preview.preview(lev); }
    final void preview(in Replay r, in Filename fnOfThatReplay, in Level l)
    {
        _preview.preview(r, fnOfThatReplay, l);
    }

    final float trophyLineY()  const
    {
        assert (_preview);
        return _preview.yg + _preview.ylg;
    }
}
