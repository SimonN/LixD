module gui.butbit;

import std.conv; // to!int for drawing the cutbit

import basics.globals; // name of checkmark bitmap
import graphic.cutbit;
import graphic.gralib;
import gui;

class BitmapButton : Button {

    this(Geom g, const(Cutbit) cb)
    {
        super(g);
        _cutbit = cb;
    }

    @property int xf(in int i) { _xf = i; reqDraw(); return _xf; }
    @property int xf()  const  { return _xf;         }
    @property int xfs() const  { return _cutbit.xfs; }

private:

    const(Cutbit) _cutbit;
    int           _xf;

protected:

    override void drawOntoButton()
    {
        immutable int yf = this.on && ! this.down ? 1 : 0;

        // center the image on the button
        int cbX = to!int(xs + xls / 2f - _cutbit.xl / 2f);
        int cbY = to!int(ys + yls / 2f - _cutbit.yl / 2f);
        _cutbit.draw(guiosd, cbX, cbY, xf, yf);
    }

}
// end class BitmapButton



class Checkbox : BitmapButton {

    this(Geom g)
    {
        g.xl = 20;
        g.yl = 20;
        super(g, getInternal(fileImageMenuCheckmark));
        this.onExecute = (){ this.toggle; };
    }

    @property bool checked(bool b) { xf = (b ? xfCheckmark : 0);
                                     reqDraw(); return b; }
    @property bool checked() const { return xf == xfCheckmark;   }
    bool toggle()                  { return checked = ! checked; }

    private enum xfCheckmark = 2;

}
// end class Checkbox
