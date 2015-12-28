module gui.texttype;

import std.conv; // filter result to string
import std.algorithm; // filter
import std.string; // stringz

import basics.alleg5;
import basics.globals; // ticksForDoubleClick
import basics.help;
import gui;
import hardware.keyboard;
import hardware.mouse;

class Texttype : Button {

    enum AllowedChars { unicode, filename, digits }
    enum caretChar = '|';

private:

    Label _label;

    string _text;
    string _textBackupForCancelling;

    bool _invisibleBG;
    bool _allowScrolling;

    void delegate() _onEnter;
    void delegate() _onEsc;

public:

    this(Geom g)
    {
        super(g);
        _label = new Label(TextButton.newGeomForLeftAlignedLabelInside(g));
        addChild(_label);
    }

    AllowedChars allowedChars;

    mixin (GetSetWithReqDraw!"invisibleBG");
    mixin (GetSetWithReqDraw!"allowScrolling");

    @property onEnter(void delegate() f) { _onEnter = f; }
    @property onEsc  (void delegate() f) { _onEsc   = f; }
    @property string text() const { return _text; }
    @property string text(in string s)
    {
        if (s == _text)
            return s;
        _text = s;
        pruneText();
        _label.text = _text;
        reqDraw();
        return s;
    }

    @property nothrow int number() const
    {
        assert (allowedChars == AllowedChars.digits);
        try               return _text.to!int;
        catch (Exception) return 0;
    }

    override @property bool on() const { return super.on; }
    override @property bool on(in bool b)
    {
        if (b == on)
            return b;
        super.on(b);
        if (b) {
            addFocus(this);
            _textBackupForCancelling = _text;
            _label.color = super.colorText;
        }
        else {
            rmFocus(this);
            _label.color = super.colorText;
        }
        return b;
    }

protected:

    override void calcSelf()
    {
        super.calcSelf();
        if (!on)
            on = super.execute;
        else {
            reqDraw(); // for the blinking cursor
            handleOnAndTyping();
            _label.text = ! on || (al_get_timer_count(basics.alleg5.timer)
                % ticksForDoubleClick < ticksForDoubleClick/2)
                ? _text : _text ~ caretChar;
        }
    }

private:

    void handleOnAndTyping()
    {
        if (mouseClickLeft || mouseClickRight || ALLEGRO_KEY_ENTER.keyTapped) {
            on = false;
            pruneDigits();
            if (_onEnter !is null)
                _onEnter();
        }
        else if (ALLEGRO_KEY_ESCAPE.keyTapped) {
            on = false;
            text = _textBackupForCancelling;
            if (_onEsc !is null)
                _onEsc();
        }
        else
            handleTyping();
    }

    void handleTyping()
    {
        if (backspace) {
            _text = backspace(_text);
            pruneText();
        }
        if (utf8Input != "") {
            _text ~= utf8Input();
            pruneText();
        }
    }

    void pruneText()
    {
        reqDraw();
        if (allowedChars == AllowedChars.filename)
            _text = escapeStringForFilename(_text);
        else if (allowedChars == AllowedChars.digits) {
            bool pred(dchar c) { return c >= '0' && c <= '9'; }
            _text = _text.filter!pred.to!string;
        }

        while (textTooLong)
            _text = backspace(_text);

        assert (! _allowScrolling, "DTODO: implement _allowScrolling");
    }

    bool textTooLong()
    {
        return ! _allowScrolling && _label.xls < al_get_text_width(
            cast (AlFont) _label.font, (_text ~ caretChar).toStringz());
    }

    void pruneDigits()
    {
        if (allowedChars != AllowedChars.digits)
            return;
        while (_text.length > 0 && _text[0] == '0')
            _text = _text[1 .. $];
        if (_text.length == 0)
            _text = "0";
        pruneText();
    }

}
// end class Texttype
