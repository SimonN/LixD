module gui.label;

/* Alignment of Label (LEFT, CENTER, RIGHT) is set by the xFrom nibble of
 * (Geom.From from).
 */

import std.conv;
import std.string; // toStringz
static import std.utf;

import basics.alleg5; // filled rectangle undraw
import basics.help; // backspace when shortening a string
import graphic.color;
import gui;

class Label : Element {
private:

    string _text;
    string _textShort; // shortened version of text, can't be returned
    bool   _shortened;  // true if textShort != text

    Alfont _font; // check if this crashes if Label not destroyed!
    Alcol  _color;
    AbbreviateNear _abbrevNear = AbbreviateNear.end;

public:
    bool undrawBeforeDraw = false; // if true, drawSelf() calls undraw() first

    alias AbbreviateNear = basics.help.CutAt;

    this(Geom g, string s = "")
    {
        if (g.yl < 1f)
            g.yl = 20;
        super(g);
        _font  = djvuM;
        _text  = s;
        _color = graphic.color.color.guiText;
        shortenText();
    }

    const(Alfont) font() const pure nothrow @safe @nogc { return _font; }
    void font(Alfont f)
    {
        if (_font == f)
            return;
        _font = f;
        shortenText();
    }

    string text() const pure nothrow @safe @nogc { return _text; }
    void number(in int i) { text = i.to!string; }
    void text(string s)
    {
        if (s == _text)
            return;
        _text = s;
        shortenText();
    }

    Alcol color() const pure nothrow @safe @nogc { return _color; }
    void color(in Alcol c)
    {
        if (c == _color)
            return;
        reqDraw();
        _color = c;
    }

    auto abbreviateNear() const pure nothrow @safe @nogc { return _abbrevNear;}
    void abbreviateNear(in AbbreviateNear abbr)
    {
        if (_abbrevNear == abbr)
            return;
        _abbrevNear = abbr;
        shortenText();
    }

    Geom.From aligned() const pure @safe { return geom.xFrom; }
    bool shortened() const pure nothrow @safe @nogc { return _shortened; }

    float textLg() const nothrow @safe { return textLg(this._text); }
    float textLg(string s) const nothrow @trusted
    {
        return s.empty ? 0f
            : al_get_text_width(font, s.toStringz) / gui.stretchFactor;
    }

    bool tooLong(string s) const nothrow @safe
    {
        return s.len && textLg(s) > xlg - 2 * gui.thicks;
    }

protected:
    override void resizeSelf() { shortenText(); }
    override void drawSelf()
    {
        if (undrawBeforeDraw)
            undraw();
        if (! text.length)
            return;
        switch (aligned) {
        case Geom.From.LEFT:
            // Keep space (gui.thicks) at left border, for "J", which
            // has a long hook protruding out of the left edge.
            drawText(_font, _textShort, xs + gui.thicks, ys, _color);
            break;
        case Geom.From.CENTER:
            drawTextCentered(_font, _textShort, xs + xls / 2, ys, _color);
            break;
        case Geom.From.RIGHT:
            // Keep space at right border, for "t",
            // which has its shadow and hooks protruding out of the right edge.
            drawTextRight(_font, _textShort, xs + xls - gui.thicks, ys, _color);
            break;
        default:
            assert (false);
        }
    }

    override void undrawSelf()
    {
        // Some letters extend further left/right than our border. Thus:
        al_draw_filled_rectangle(
            xs,
            ys,
            xs + xls,
            ys + yls, undrawColor);
    }

private:
    string addAbbrevDots(in string s) const pure nothrow @safe
    {
        final switch (_abbrevNear) {
            case AbbreviateNear.end: return s ~ ".";
            case AbbreviateNear.beginning: return "..." ~ s;
        }
    }

    void shortenText()
    out { assert (_shortened == (_textShort != _text)); }
    do {
        reqDraw();
        _textShort = _text;
        _shortened = false;
        if (text.length == 0 || std.utf.stride(text) == text.length) {
            /*
             * Don't shorten empty string.
             * Hack: Allow single-character strings to pass unshortened.
             * This is to let the "+"/"-" labels on the small key-binding
             * buttons pass unshortened. Those would get shortened to ".".
             */
            return;
        }
        _shortened = tooLong(_text);
        if (! _shortened) {
            return;
        }
        while (! _textShort.empty && tooLong(addAbbrevDots(_textShort))) {
            _textShort = backspace(_textShort, _abbrevNear);
        }
        _textShort = addAbbrevDots(_textShort);
    }
}
