module game.panel.savestat;

/*
 * One button.
 * +---------------------------+
 * |         Save state        |
 * +---------------------------+
 *
 * Expands in-place to two buttons after saving a state:
 * +-------------+-------------+
 * |  Load state |  Save state |
 * +-------------+-------------+
 */

import opt = file.option.allopts;
import game.panel.tooltip;
import graphic.internal;
import gui;
import hardware.keyset;

class SaveStateButtons : Element, TooltipSuggester {
private:
    BitmapButton _load, _save;

public:
    this(Geom g)
    {
        super(g);
        BitmapButton mkButton(in int xFrame, in KeySet aHotkey)
        {
            auto ret = new BitmapButton(new Geom(0, 0, xlg/2f, ylg),
                InternalImage.gamePanel2.toCutbit);
            ret.xf = xFrame;
            ret.hotkey = aHotkey;
            addChild(ret);
            return ret;
        }
        _load = mkButton(GamePanel2Xf.quickload, opt.keyStateLoad.value);
        _save = mkButton(GamePanel2Xf.quicksave, opt.keyStateSave.value);
        _save.onExecute = () { showLoadState(true); };
        showLoadState(false);
    }

    const nothrow @safe @nogc {
        bool loadState() pure { return _load.execute; }
        bool saveState() pure { return _save.execute; }

        bool isSuggestingTooltip()
        {
            return _load.isMouseHere || _save.isMouseHere;
        }

        Tooltip.ID suggestedTooltip()
        in { assert (isSuggestingTooltip); }
        do {
            return _load.isMouseHere ? Tooltip.ID.stateLoad
                : Tooltip.ID.stateSave;
        }
    }

private:
    // Better would be if the game informed the panel about (whether there are
    // states saved). For now, I call this via _save.onExecute, see our ctor.
    void showLoadState(bool b)
    {
        _save.resize(b ? xlg/2f : xlg, _save.ylg);
        _save.move(b ? xlg/2f : 0, 0);
        _load.shown = b;
    }
}
