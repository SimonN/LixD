module gui.label;

/* Alignment of Label (LEFT, CENTER, RIGHT) is set by the x_from nibble of
 * (Geom.From from). Fixed or non-fixed printing is chosen in class Label.
 */

import std.conv;
import std.string; // toStringz, since shortening strings is not a member of
                   // basics.help anymore

import basics.alleg5; // filled rectangle undraw
import basics.help; // backspace when shortening a string
import graphic.color;
import graphic.textout;
import gui;

class Label : Element {

    this(int x = 0, int y = 0, int xl = 100, string s = "")
    {
        this(Geom.From.TOP_LEFT, x, y, xl, s);
    }

    this(Geom.From from, int x = 0, int y = 0, int xl = 100, string s = "")
    {
        super(from, x, y, xl, 20);
        font = djvu_m;
        text = s;
        col  = color.gui_text;
        shorten_text();
    }

    string    get_text ()  const { return text;  }
    Geom.From get_align()  const { return get_geom().x_from; }
    AlCol     get_color()  const { return col; }

    nothrow int get_number() const
    {
        try return text.to!int;
        catch (Exception) return 0;
    }

    void set_font  (AlFont f) { font = f; shorten_text(); }
    void set_text  (string s) { text = s; shorten_text(); }
    void set_number(in int i) { text = i.to!string; shorten_text(); }
    void set_color (AlCol  c) { col  = c; req_draw(); }
    void set_fixed (bool b = true) { fixed = b; shorten_text(); }

private:

    string text;
    string text_short; // shortened version of text, can't be returned
    bool   shortened;  // true if text_short != text

    AlFont font; // check if this crashes if Label not destroyed!
    AlCol  col;
    bool   fixed;



private void
shorten_text()
{
    req_draw();
    text_short = text;
    shortened  = false;

    if (! text.length) {
        return;
    }
    else if (fixed) {
        immutable one_char_geoms = 10;
        while (text_short.length && text_short.length * one_char_geoms > xlg) {
            shortened = true;
            if (get_align() == Geom.From.RIGHT)
                text_short = text_short[1 .. $];
            else
                text_short = text_short[0 .. $-1];
        }
    }
    else {
        // variable-width character printing length must be measured by A5
        int textwidth(in string s)
        {
            return al_get_text_width(font, s.toStringz());
        }

        shortened = (textwidth(text) >= xls);
        if (shortened) {
            while (text_short.length && textwidth(text_short ~ "...") >= xls)
                text_short = backspace(text_short);
            if (text_short.length)
                text_short ~= "...";
        }
    }
}



protected override void
draw_self()
{
    if (! text.length) return;

    switch (get_align()) {
    case Geom.From.LEFT:
        draw_text(font, text_short, xs, ys, col);
        break;
    case Geom.From.CENTER:
        draw_text_centered(font, text_short, xs + xls / 2, ys, col);
        break;
    case Geom.From.RIGHT:
        draw_text_centered(font, text_short, xs + xls, ys, col);
        break;
    default:
        assert (false);
    }
}

}
// end class Label
