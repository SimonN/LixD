module game.panel.savestat;

/*
 * Two buttons.
 * +-------------+---------------------------+
 * |   Restart   |         Save state        |
 * +-------------+---------------------------+
 *
 * They expand in-place to three buttons after saving a state:
 * +-------------+-------------+-------------+
 * |   Restart   |  Load state |  Save state |
 * +-------------+-------------+-------------+
 */

import opt = file.option.allopts;
import game.panel.tooltip;
import graphic.internal;
import gui;
import hardware.keyset;

class SaveStateButtons : Element, TooltipSuggester {
private:
    BitmapButton _load, _save, _restart;

public:
    this(Geom g)
    {
        super(g);
        BitmapButton mkButton(in int nr, in int xFrame, in KeySet aHotkey)
        {
            auto ret = new BitmapButton(new Geom(nr * (xlg / 3f), 0,
                xlg / 3f, ylg), InternalImage.gamePanel2.toCutbit);
            ret.xf = xFrame;
            ret.hotkey = aHotkey;
            addChild(ret);
            return ret;
        }
        _restart = mkButton(0, GamePanel2Xf.restart, opt.keyRestart.value);
        _load = mkButton(1, GamePanel2Xf.quickload, opt.keyStateLoad.value);
        _save = mkButton(2, GamePanel2Xf.quicksave, opt.keyStateSave.value);
        _save.onExecute = () { showLoadState(true); };
        showLoadState(false);
    }

    const nothrow @safe @nogc {
        bool loadState() pure { return _load.execute; }
        bool saveState() pure { return _save.execute; }
        bool restart() pure { return _restart.execute; }

        bool isSuggestingTooltip()
        {
            return _load.isMouseHere || _save.isMouseHere
                || _restart.isMouseHere;
        }

        Tooltip.ID suggestedTooltip()
        in { assert (isSuggestingTooltip); }
        do {
            return _restart.isMouseHere ? Tooltip.ID.restart
                : _load.isMouseHere ? Tooltip.ID.stateLoad
                : Tooltip.ID.stateSave;
        }
    }

private:
    // Better would be if the game informed the panel about (whether there are
    // states saved). For now, I call this via _save.onExecute, see our ctor.
    void showLoadState(bool b)
    {
        _save.resize((2 - b) * xlg/3f, _save.ylg);
        _save.move((1 + b) * xlg/3f, 0);
        _load.shown = b;
    }
}
