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
        cutbit = cb;
    }

    void set_x_frame(in int i) { x_frame = i; req_draw();      }
    int  get_x_frame()  const  { return x_frame;               }
    int  get_x_frames() const  { return cutbit.get_x_frames(); }

private:

    const(Cutbit) cutbit;
    int           x_frame;

protected:

    override void draw_self()
    {
        super.draw_self();
        immutable int y_frame = get_on() && ! get_down() ? 1 : 0;

        // center the image on the button
        int cb_x = to!int(xs + xls/2 - cutbit.get_xl());
        int cb_y = to!int(ys + yls/2 - cutbit.get_yl());
        cutbit.draw(guiosd, cb_x, cb_y, x_frame, y_frame);
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

    void set_checked(bool b = true) { set_x_frame(b ? xf_ck : 0); req_draw(); }
    bool get_checked() const        { return get_x_frame() == xf_ck;          }
    void toggle()                   { set_checked(! get_checked());           }

    private static immutable xf_ck = 2;

}
// end class Checkbox
