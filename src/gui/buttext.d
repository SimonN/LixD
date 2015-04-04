module gui.buttext;

/* A button with text printed on it.
 *
 * The button may have a checkmark on its right-hand side. If present, the
 * maximal length for the text is shortened. Set check_frame != 0 to get it.
 */

import std.conv;

import gui;
import basics.globals;
import basics.help;
import graphic.cutbit;
import graphic.gralib;
import graphic.textout;

class TextButton : Button {

    this(float x = 0, float y = 0, float xl = 100, float yl = 20)
    {
        this(Geom.From.TOP_LEFT, x, y, xl, yl);
    }

    this(Geom.From from, float x  =   0, float y  =  0,
                         float xl = 100, float yl = 20)
    {
        super(from, x, y, xl, yl);
    }

    bool get_align_left() const         { return align_left;          }
    void set_align_left(bool b = true)  { align_left = b; req_draw(); }

    string get_text() const      { return text;          }
    void   set_text(in string s) { text = s; req_draw(); }

    int  get_check_frame() const { return check_frame;          }
    void set_check_frame(int i)  { check_frame = i; req_draw(); }

private:

    string text;
    bool   align_left;  // standard is false, meaning centered
    int    check_frame; // frame 0 is empty, then don't draw anything and
                        // don't shorten the text maximal length

protected:

override void
draw_self()
{
    super.draw_self();

    if (text.length > 0) {
        // compute the length of the text, and display a shorter version
        // with dots at the end if it's too long.
        auto pixellen = xls - 2 * Geom.thickness;
        auto cb = get_internal(file_bitmap_menu_checkmark);
        if (check_frame != 0) pixellen -= cb.get_xl() * (align_left ? 1 : 2);
        string text_to_print = shorten_with_dots(text, djvu_m, pixellen);

        if (align_left) {
            draw_text(djvu_m, text_to_print,
             xs + Geom.thickness, ys, get_color_text());
        }
        else {
            draw_text_centered(djvu_m, text_to_print,
             xs + xls/2, ys, get_color_text());
        }
        // draw the checkmark
        if (check_frame != 0) {
            cb.draw(guiosd, to!int(xs + xls) - cb.get_xl(), to!int(ys),
             check_frame, 2 * (get_on() && ! get_down()));
        }
    }
}

}; // Klassenende
