module menu.outcome.single;

/*
 * A full-screen outcome of a singleplayer game.
 *
 * Presents the next level, and the next unsolved level if it differs,
 * and offers to go back to the singleplayer browser.
 */

import file.option.allopts;
import gui;
import game.harvest;
import menu.preview.base;
import menu.preview.fullprev;

class SinglePlayerOutcome : Window {
private:
    FullPreview _oldLevel;
    NextLevelButton _nextLevel;
    NextLevelButton _nextUnsolved;
    TextButton _gotoBrowser;

public:
    enum ExitWith {
        notYet,
        //gotoSameLevel, ---------- uncomment once implemented
        //gotoAnyNextLevel,
        //gotoNextUnsolvedLevel,
        gotoBrowser,
    }

    this(in Harvest harvest)
    {
        super(new Geom(0, 0, gui.screenXlg, gui.screenYlg),
            harvest.level.name);
        _oldLevel = new FullPreview(new Geom(20, 40, xlg/2, 160,
            From.TOP_RIGHT));
        _oldLevel.preview(harvest.level);
        addChild(_oldLevel);

        _nextLevel = newNext(From.BOTTOM_LEFT,
            "Play the next level:", harvest.level);
        _nextUnsolved = newNext(From.BOTTOM_RIGHT,
            "Play the next unsolved level:", harvest.level);

        _gotoBrowser = new TextButton(new Geom(0, 20, 300, 20, From.BOTTOM),
            "Go back to the SingleBrowser");
        _gotoBrowser.hotkey = keyMenuExit;
        addChild(_gotoBrowser);
    }

    void dispose()
    {
        _oldLevel.dispose();
    }

    ExitWith exitWith() const pure nothrow @safe @nogc
    {
        return _gotoBrowser.execute ? ExitWith.gotoBrowser : ExitWith.notYet;
    }

private:
    auto newNext(Geom.From from, string topCaption, in Level toPreview)
    {
        auto ret = new NextLevelButton(
            new Geom(20, 60, xlg/2 - 30, 200, from), topCaption);
        addChild(ret);
        ret.preview(toPreview);
        return ret;
    }
}

private:

class NextLevelButton : Button, PreviewLevelOrReplay {
private:
    Label _topCaption;
    FullPreview _preview;

public:
    this(Geom g, string topCaption)
    {
        super(g);
        _topCaption = new Label(
            new Geom(0, 10, xlg - 10, 20, From.TOP), topCaption);
        _preview = new FullPreview(
            new Geom(0, 40, xlg - 40, ylg - 50, From.TOP));
        addChildren(_topCaption, _preview);
    }

    void dispose() { _preview.dispose(); }
    void previewNone() { _preview.previewNone(); }
    void preview(in Level lev) { _preview.preview(lev); }
    void preview(in Replay rep, in Level lev) { _preview.preview(rep, lev); }
}
