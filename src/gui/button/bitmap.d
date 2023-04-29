module gui.button.bitmap;

import std.conv; // to!int for drawing the cutbit

import graphic.cutbit;
import graphic.internal;
import gui;

class BitmapButton : Button {
private:
    CutbitElement _cbe;

public:
    this(Geom g, const(Cutbit) cb)
    {
        super(g);
        _cbe = new CutbitElement(new Geom(0, 0, xlg, ylg, From.CENTER), cb);
        addChild(_cbe);
    }

    void xf(in int i) pure nothrow @safe @nogc
    {
        if (i == xf) {
            return;
        }
        _cbe.xf = i;
        reqDraw();
    }

    const pure nothrow @safe @nogc {
        int xf() { return _cbe.xf;  }
        int yf() { return this.on && ! this.down ? 1 : 0; }
        int xfs() { return _cbe.xfs; }
    }

protected:
    override void drawOntoButton()
    {
        _cbe.yf = this.yf;
        // Force drawing _cbe right now, even though it's a child and would be
        // drawn later otherwise. The graphic must go behind the button hotkey
        // that is drawn in final super.drawSelf().
        _cbe.draw();
    }
}



class CheckableButton : BitmapButton {
private:
    immutable int _xfWhenChecked;

public:
    this(Geom g, in int xfWhenChecked)
    in { assert (xfWhenChecked != 0, "0 means empty button"); }
    do {
        g.xl = 20;
        g.yl = 20;
        super(g, InternalImage.menuCheckmark.toCutbit);
        _xfWhenChecked = xfWhenChecked;
    }

    final pure nothrow @safe @nogc {
        bool isChecked() const { return xf == _xfWhenChecked; }
        void check() { xf = _xfWhenChecked; }
        void uncheck() { xf = 0; }
        void checked(in bool b) { b ? check() : uncheck(); }
        void toggle() { isChecked ? uncheck() : check(); }
    }
}



class Checkbox : CheckableButton {
public:
    this(Geom g)
    {
        super(g, 2); // X-frame 2 is the checkmark.
        this.onExecute = () { toggle(); };
    }
}
