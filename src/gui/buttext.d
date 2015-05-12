module gui.buttext;

/* A button with text printed on it.
 *
 * The button may have a checkmark on its right-hand side. If present, the
 * maximal length for the text is shortened. Set check_frame != 0 to get it.
 */

import std.conv;

import gui;
import basics.globals;
import graphic.color;
import graphic.cutbit;
import graphic.gralib;

class TextButton : Button {

    this(Geom g)
    {
        super(g);
        // the text should not be drawn on the 3D part of the button, but only
        // to the uniformly colored center. Each side has a thickness of 2.
        // The checkmark already accounts for this.
        // The checkmark is at the right of the button, for all text aligns.
        float th  = Geom.thickg * 2; // *2 for nice spacing at ends
        alias lef = Geom.From.LEFT;
        alias ctr = Geom.From.CENTER;
        left         = new Label(new Geom(th, 0, g.xl - 2*th,      0, lef));
        left_check   = new Label(new Geom(th, 0, g.xl - th-ch_xlg, 0, lef));
        center       = new Label(new Geom(0,  0, g.xl - 1*th,      0, ctr));
        center_check = new Label(new Geom(0,  0, g.xl - 2*ch_xlg,  0, ctr));

        check_geom = new Geom(0, 0, ch_xlg, ch_xlg, Geom.From.RIGHT);
        check_geom.parent = this.geom;

        add_children(left, left_check, center, center_check);
    }

    bool align_left() const { return _align_left;                            }
    bool align_left(bool b) { _align_left=b; req_draw(); return _align_left; }

    string text() const      { return _text;                }
    string text(in string s) { _text = s; req_draw(); return s; }

    int check_frame() const { return _check_frame;                            }
    int check_frame(int i)  { _check_frame=i;req_draw(); return _check_frame; }

    override string toString() const { return "But-`" ~  _text ~ "'"; }

private:

    string _text;
    bool   _align_left;
    int    _check_frame; // frame 0 is empty, then don't draw anything and
                         // don't shorten the text maximal length
    Label left;
    Label left_check;
    Label center;
    Label center_check;

    Geom  check_geom;

    static immutable ch_xlg = 20; // size in geoms of checkbox



protected override void
draw_self()
{
    super.draw_self();

    auto label_list = [ center, center_check, left, left_check ];
    foreach (label; label_list)
        label.text = "";
    with (label_list[_align_left * 2 + (_check_frame != 0)]) {
        text  = this._text;
        color = this.get_color_text();
    }

    // Draw the checkmark, which doesn't overlap with the children.
    // There's a (ch_xlg) x (ch_xlg) area reserved for the cutbit on the right.
    // Draw to the center of this square.
    if (_check_frame != 0) {
        auto cb = get_internal(file_bitmap_menu_checkmark);
        cb.draw(guiosd,
            to!int(check_geom.xs + check_geom.xls/2 - cb.get_xl()/2),
            to!int(check_geom.ys + check_geom.yls/2 - cb.get_xl()/2),
            _check_frame, 2 * (on && ! down)
        );
    }
}

}; // Klassenende
