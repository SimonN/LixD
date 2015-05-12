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

    this(Geom g, string s = "")
    {
        g.yl = 20;
        super(g);
        _font  = djvu_m;
        _text  = s;
        _color = graphic.color.color.gui_text;
        shorten_text();
    }

    @property string    text   () const { return _text;  }
    @property Geom.From aligned() const { return geom.x_from; }
    @property AlCol     color  () const { return _color; }

    nothrow @property int get_number() const
    {
        try return text.to!int;
        catch (Exception) return 0;
    }

    @property font  (AlFont f) { _font  = f; shorten_text(); }
    @property text  (string s) { _text  = s; shorten_text(); }
    @property number(in int i) { _text  = i.to!string; shorten_text(); }
    @property color (AlCol  c) { _color = c; req_draw(); }
    @property fixed (bool   b) { _fixed = b; shorten_text(); }

    override string toString() const { return "Label-`" ~ _text ~ "'"; }

private:

    string _text;
    string text_short; // shortened version of text, can't be returned
    bool   shortened;  // true if text_short != text

    AlFont _font; // check if this crashes if Label not destroyed!
    AlCol  _color;
    bool   _fixed;



private void
shorten_text()
{
    req_draw();
    text_short = _text;
    shortened  = false;

    if (! text.length) {
        return;
    }
    else if (_fixed) {
        immutable one_char_geoms = 10;
        while (text_short.length && text_short.length * one_char_geoms > xlg) {
            shortened = true;
            if (aligned == Geom.From.RIGHT)
                text_short = text_short[1 .. $];
            else
                text_short = text_short[0 .. $-1];
        }
    }
    else {
        // variable-width character printing length must be measured by A5
        int textwidth(in string s)
        {
            return al_get_text_width(_font, s.toStringz());
        }

        shortened = (textwidth(text) >= xls);
        if (shortened) {
            while (text_short.length && textwidth(text_short ~ "...") >= xls)
                text_short = backspace(text_short);
            text_short ~= "...";
        }
    }
}



protected override void
draw_self()
{
    if (! text.length) return;

    switch (aligned) {
    case Geom.From.LEFT:
        draw_text(_font, text_short, xs, ys, _color);
        break;
    case Geom.From.CENTER:
        draw_text_centered(_font, text_short, xs + xls / 2, ys, _color);
        break;
    case Geom.From.RIGHT:
        draw_text_centered(_font, text_short, xs + xls, ys, _color);
        break;
    default:
        assert (false);
    }
}

}
// end class Label
