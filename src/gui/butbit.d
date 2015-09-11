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

    @property int xf(in int i) { _xf = i; req_draw(); return _xf; }
    @property int xf()  const  { return _xf;         }
    @property int xfs() const  { return _cutbit.xfs; }

private:

    const(Cutbit) _cutbit;
    int           _xf;

protected:

    override void draw_self()
    {
        super.draw_self();
        immutable int yf = on && ! down ? 1 : 0;

        // center the image on the button
        int cb_x = to!int(xs + xls / 2f - _cutbit.xl / 2f);
        int cb_y = to!int(ys + yls / 2f - _cutbit.yl / 2f);
        _cutbit.draw(guiosd, cb_x, cb_y, _xf, yf);
    }

}
// end class BitmapButton



class Checkbox : BitmapButton {

    this(Geom g)
    {
        g.xl = 20;
        g.yl = 20;
        super(g, get_internal(file_bitmap_menu_checkmark));
        this.on_click = &toggle;
    }

    @property bool checked(bool b) { xf = (b ? xf_ck : 0);
                                     req_draw(); return b; }
    @property bool checked() const { return xf == xf_ck; }
    void toggle()                  { checked = ! checked; }

    private static immutable xf_ck = 2;

}
// end class Checkbox
