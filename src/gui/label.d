module gui.label;

/* Alignment of Label (LEFT, CENTER, RIGHT) is set by the xFrom nibble of
 * (Geom.From from). Fixed or non-fixed printing is chosen in class Label.
 */

import std.conv;
import std.range;  // walkLength
import std.string; // toStringz
import std.uni;    // .byGrapheme.walkLength, find size of displayed string

import basics.alleg5; // filled rectangle undraw
import basics.help; // backspace when shortening a string
import graphic.color;
import graphic.textout;
import gui;

class Label : Element {
private:

    string _text;
    string _textShort; // shortened version of text, can't be returned
    bool   _shortened;  // true if textShort != text

    AlFont _font; // check if this crashes if Label not destroyed!
    Alcol  _color;
    bool   _fixed;

public:
    bool undrawBeforeDraw = false; // if true, drawSelf() calls undraw() first

    enum string abbrevSuffix      = ".";
    enum int    fixedCharXl       = 12; // most chars might occupy this much
    enum int    fixedCharXSpacing = 10;

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

    @property const(AlFont) font()      const { return _font;      }
    @property string        text()      const { return _text;      }
    @property Geom.From     aligned()   const { return geom.xFrom; }
    @property Alcol         color()     const { return _color;     }
    @property bool          shortened() const { return _shortened; }

    @property font(AlFont f) { _font  = f; shorten_text(); return _font; }
    @property text(string s)
    {
        if (s == _text)
            return _text;
        _text = s;
        shorten_text();
        return _text;
    }

    @property number(in int i) { _text  = i.to!string; shorten_text();     }
    @property color (Alcol  c) { _color = c; reqDraw(); return _color;     }
    @property fixed (bool   b) { _fixed = b; shorten_text(); return b;     }

    float textLg()         const { return textLg(this._text); }
    float textLg(string s) const
    {
        return (! s.len)  ? 0f
            :  (! _fixed) ? al_get_text_width(font, s.toStringz)
                            / Geom.stretchFactor
            :               s.byGrapheme.walkLength * fixedCharXl;
    }

    bool tooLong(string s) const { return s.len && textLg(s) > xlg; }

protected:
    override void resizeSelf() { shorten_text(); }
    override void drawSelf()
    {
        if (undrawBeforeDraw)
            undraw();
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

    override void undrawSelf()
    {
        // Some letters extend further to the left than the left border.
        // Don't only paint the Element's rectangle, paint more to the left.
        al_draw_filled_rectangle(xs - Geom.thicks, ys,
                                 xs + xls,         ys + yls, undrawColor);
    }

private:
    void shorten_text()
    out { assert (_shortened == (_textShort != _text)); }
    body {
        reqDraw();
        _textShort = _text;
        _shortened = false;
        if (! text.length)
            return;
        else if (_fixed) {
            while (tooLong(_textShort)) {
                _shortened = true;
                if (aligned == Geom.From.RIGHT)
                    _textShort = _textShort[1 .. $];
                else
                    _textShort = _textShort[0 .. $-1];
            }
        }
        else {
            _shortened = tooLong(_text);
            if (_shortened) {
                while (_textShort.length > 0 && tooLong(_textShort ~ abbrevSuffix))
                    _textShort = backspace(_textShort);
                _textShort ~= abbrevSuffix;
            }
        }
    }
}
// end class Label
