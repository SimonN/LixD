module gui.button.okay;

import std.algorithm : clamp;

import file.option;
import file.language;
import gui;
import hardware.mouse;

TextButton newOkay(Geom g)
{
    auto b = new TextButton(g, Lang.commonOk.transl);
    b.hotkey = file.option.keyMenuOkay;
    return b;
}

TextButton newCancel(Geom g)
{
    auto b = new TextButton(g, Lang.commonCancel.transl);
    b.hotkey = file.option.keyMenuExit;
    return b;
}

class OkayCancel : Element {
private:
    TextButton _okay;
    TextButton _cancel;

public:
    enum ExitWith {
        nothingYet,
        okay,
        cancel,
    }

    this(Geom g)
    in {
        assert (fitsHorizontally(g) || fitsVertically(g),
            "Size for the Okay/Cancel buttons is too small.");
    }
    do {
        super(g);
        if (fitsHorizontally(g)) {
            immutable butXlg = (xlg - spaceBetweenButtons(g)) / 2;
            _okay = newOkay(new Geom(0, 0, butXlg, ylg, From.LEFT));
            _cancel = newCancel(new Geom(0, 0, butXlg, ylg, From.RIGHT));
        }
        else {
            immutable butYlg = (ylg - spaceBetweenButtons(g)) / 2;
            _okay = newOkay(new Geom(0, xlg, 0, butYlg, From.TOP));
            _cancel = newCancel(new Geom(0, xlg, 0, butYlg, From.BOTTOM));
        }
        addChildren(_okay, _cancel);
    }

    ExitWith exitWith() const nothrow @nogc
    {
        return _cancel.execute ? ExitWith.cancel
            : _okay.execute || mouseClickRight ? ExitWith.okay
            : ExitWith.nothingYet;
    }

private:
    static bool fitsHorizontally(in Geom g)
    {
        return g.ylg >= 20 && g.xlg >= 200;
    }

    static bool fitsVertically(in Geom g)
    {
        return g.ylg >= 40 && g.xlg >= 100;
    }

    static float spaceBetweenButtons(in Geom g)
    {
        return fitsHorizontally(g) ? clamp(g.xlg - 200, 0f, 20f)
            : fitsVertically(g) ? clamp(g.ylg - 40, 0f, 20f)
            : 0f;
    }
}
