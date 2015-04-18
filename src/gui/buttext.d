module gui.buttext;

/* A button with text printed on it.
 *
 * The button may have a checkmark on its right-hand side. If present, the
 * maximal length for the text is shortened. Set check_frame != 0 to get it.
 */

import std.conv;

import gui;
import basics.globals;
import graphic.cutbit;
import graphic.gralib;

class TextButton : Button {

    this(in int x = 0, in int y = 0, in int xl = 100, in int yl = 20)
    {
        this(Geom.From.TOP_LEFT, x, y, xl, yl);
    }

    this(Geom.From from, in int x  =   0, in int y  =  0,
                         in int xl = 100, in int yl = 20)
    {
        super(from, x, y, xl, yl);
        // the text should not be drawn on the 3D part of the button, but only
        // to the uniformly colored center. Each side has a thickness of 2.
        // The checkmark already accounts for this.
        // The checkmark is at the right of the button, for all text aligns.
        immutable th = Geom.thickg;
        left         = new Label(Geom.From.LEFT,  th, 0, xl - 2 * th);
        left_check   = new Label(Geom.From.LEFT,  th, 0, xl - th - ch_xlg);
        center       = new Label(Geom.From.CENTER, 0, 0, xl - 2 * th);
        center_check = new Label(Geom.From.CENTER, 0, 0, xl - 2 * ch_xlg);

        check_geom   = new Geom(Geom.From.RIGHT, 0, 0, ch_xlg, ch_xlg);
        check_geom.parent = this.get_geom();

        add_children(left, left_check, center, center_check);
    }

    bool get_align_left() const         { return align_left;         }
    void set_align_left(bool b = true)  { align_left = b; prepare(); }

    string get_text() const      { return text;         }
    void   set_text(in string s) { text = s; prepare(); }

    int  get_check_frame() const { return check_frame;         }
    void set_check_frame(int i)  { check_frame = i; prepare(); }

private:

    string text;
    bool   align_left;
    int    check_frame; // frame 0 is empty, then don't draw anything and
                        // don't shorten the text maximal length
    Label left;
    Label left_check;
    Label center;
    Label center_check;

    Geom  check_geom;

    static immutable ch_xlg = 20; // size in geoms of checkbox



// need to move these rendering methods into something in Element, such that
// it's NVI-conformally called by req_draw(); -- or maybe not, since these
// are pretty complex with the text rendering, which is unnecessary at click
private void
prepare()
{
    req_draw();
    foreach (label; [ left, left_check, center, center_check ]) {
        label.text = "";
    }
    switch (align_left * 2 + (check_frame != 0)) {
        case 0: center      .text = text; break;
        case 1: center_check.text = text; break;
        case 2: left        .text = text; break;
        case 3: left_check  .text = text; break;
        default: assert (false);
    }
}



protected override void
draw_self()
{
    super.draw_self();

    // Draw the checkmark, which doesn't overlap with the children.
    // There's a (ch_xlg) x (ch_xlg) area reserved for the cutbit on the right.
    // Draw to the center of this square.
    if (check_frame != 0) {
        auto cb = get_internal(file_bitmap_menu_checkmark);
        cb.draw(guiosd,
            to!int(check_geom.xs + check_geom.xls/2 - cb.get_xl()/2),
            to!int(check_geom.ys + check_geom.yls/2 - cb.get_xl()/2),
            check_frame, 2 * (get_on() && ! get_down())
        );
    }
}

}; // Klassenende
