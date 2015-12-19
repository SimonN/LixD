module gui.label;

/* Alignment of Label (LEFT, CENTER, RIGHT) is set by the xFrom nibble of
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

    enum string abbreviationSuffix = ".";

    this(Geom g, string s = "")
    {
        if (g.yl < 1f)
            g.yl = 20;
        super(g);
        _font  = djvuM;
        _text  = s;
        _color = graphic.color.color.guiText;
        shorten_text();
    }

    @property string    text   () const { return _text;  }
    @property Geom.From aligned() const { return geom.xFrom; }
    @property AlCol     color  () const { return _color; }

    nothrow @property int get_number() const
    {
        try return text.to!int;
        catch (Exception) return 0;
    }

    @property font  (AlFont f) { _font  = f; shorten_text();               }
    @property text  (string s) { _text  = s; shorten_text(); return _text; }
    @property number(in int i) { _text  = i.to!string; shorten_text();     }
    @property color (AlCol  c) { _color = c; reqDraw(); }
    @property fixed (bool   b) { _fixed = b; shorten_text(); }

    override string toString() const { return "Label-`" ~ _text ~ "'"; }

private:

    string _text;
    string _textShort; // shortened version of text, can't be returned
    bool   _shortened;  // true if textShort != text

    AlFont _font; // check if this crashes if Label not destroyed!
    AlCol  _color;
    bool   _fixed;



private void
shorten_text()
out {
    assert (_shortened == (_textShort != _text));
}
body {
    reqDraw();
    _textShort = _text;
    _shortened = false;

    if (! text.length) {
        return;
    }
    else if (_fixed) {
        immutable one_char_geoms = 10;
        while (_textShort.length > 0
            && _textShort.length * one_char_geoms > xlg
        ) {
            _shortened = true;
            if (aligned == Geom.From.RIGHT)
                _textShort = _textShort[1 .. $];
            else
                _textShort = _textShort[0 .. $-1];
        }
    }
    else {
        // variable-width character printing length must be measured by A5
        int textwidth(in string s)
        {
            return al_get_text_width(_font, s.toStringz());
        }

        _shortened = (textwidth(text) >= xls);
        if (_shortened) {
            while (_textShort.length > 0
                && textwidth(_textShort ~ abbreviationSuffix) >= xls
            ) {
                _textShort = backspace(_textShort);
            }
            _textShort ~= abbreviationSuffix;
        }
    }
}



protected override void
drawSelf()
{
    if (! text.length)
        return;

    switch (aligned) {
    case Geom.From.LEFT:
        drawText(_font, _textShort, xs, ys, _color);
        break;
    case Geom.From.CENTER:
        drawTextCentered(_font, _textShort, xs + xls / 2, ys, _color);
        break;
    case Geom.From.RIGHT:
        drawTextRight(_font, _textShort, xs + xls, ys, _color);
        break;
    default:
        assert (false);
    }
}

}
// end class Label
