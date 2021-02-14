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

class SinglePlayerOutcome : Window {
private:
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
            "End of singleplayer game");
        _gotoBrowser = new TextButton(new Geom(0, 20, 300, 40, From.BOTTOM),
            "Go back to the SingleBrowser");
        _gotoBrowser.hotkey = keyMenuExit;
        addChild(_gotoBrowser);
    }

    void dispose() {}

    ExitWith exitWith() const pure nothrow @safe @nogc
    {
        return _gotoBrowser.execute ? ExitWith.gotoBrowser : ExitWith.notYet;
    }
}
