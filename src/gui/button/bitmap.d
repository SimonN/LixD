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

    @property int xf(in int i) { reqDraw(); return _cbe.xf = i; }
    @property int xf()  const  { return _cbe.xf;  }
    @property int xfs() const  { return _cbe.xfs; }
    @property int yf()  const  { return this.on && ! this.down ? 1 : 0; }

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
// end class BitmapButton



class Checkbox : BitmapButton {
private:
    immutable int _xfWhenChecked = 2; // 2 is the checkmark, or caller sets it.

public:
    this(Geom g, in int xfWhenChecked = 2)
    {
        g.xl = 20;
        g.yl = 20;
        super(g, InternalImage.menuCheckmark.toCutbit);
        _xfWhenChecked = xfWhenChecked;
        this.onExecute = (){ this.toggle; };
    }

    bool checked() const
    {
        return xf == _xfWhenChecked;
    }

    void checked(bool b)
    {
        xf = b ? _xfWhenChecked : 0;
        reqDraw();
    }

    void toggle()
    {
        checked = ! checked;
    }
}
// end class Checkbox
