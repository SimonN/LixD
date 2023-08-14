module gui.texttype;

/* A GUI element to enter numbers or text by typing on the keyboard.
 * Can be set to accept only digits. There is potential to improve this,
 * by choosing more carefully where pruneText() and pruneDigits() are called.
 * Maybe it should be abstract, with subclasses for different allowed chars.
 */

import std.conv; // filter result to string
import std.algorithm; // filter
import std.string; // stringz
import std.utf;

import basics.alleg5;
import basics.globals; // ticksForDoubleClick
import basics.help;
import gui;
import hardware.keyboard;
import hardware.mouse;
import hardware.display; // to get clipboard text

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

    void onEnter(void delegate() f) { _onEnter = f; }
    void onEsc  (void delegate() f) { _onEsc   = f; }
    string text() const pure nothrow @safe @nogc { return _text; }
    string text(in string s)
    {
        if (s == _text)
            return s;
        _text = s;
        pruneText();
        reqDraw();
        return s;
    }

    int number() const pure nothrow @safe
    {
        try               return _text.to!int;
        catch (Exception) return 0;
    }

    override bool on() const pure nothrow @safe @nogc { return super.on; }
    override bool on(in bool b) nothrow @safe
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
        }
    }

    override void drawOntoButton()
    {
        immutable hasCaret = on && timerTicks % ticksForDoubleClick
                                    >= ticksForDoubleClick/2;
        string forLabel = hasCaret ? _text ~ caretChar : _text;
        // There is similar cutting in pruneText, but that cutting affects
        // _text, not the label presentation. _text is the retrievable data.
        while (_allowScrolling && forLabel.length > 1
            && _label.tooLong(hasCaret ? forLabel : forLabel ~ caretChar))
            // remove first UTF char
            forLabel = forLabel[forLabel.stride .. $];
        _label.text = forLabel;
    }

private:
    void handleOnAndTyping()
    {
        if (mouseClickLeft || mouseClickRight || ALLEGRO_KEY_ENTER.keyTapped) {
            on = false;
            pruneDigits();
            if (ALLEGRO_KEY_ENTER.keyTapped && _onEnter !is null)
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
            _text = backspace(_text, CutAt.end);
            pruneText();
        }
        if (ctrlHeld && keyTapped(ALLEGRO_KEY_V)) {
            // We'll own an al_malloc()'ed copy of the text. We must al_free().
            char* alClipText = al_get_clipboard_text(theA5display);
            _text ~= alClipText.to!string;
            al_free(alClipText);
        }
        if (utf8Input != "") {
            _text ~= utf8Input();
            pruneText();
        }
    }

    // pruneText always allocates because it measures _text ~ caretChar :-/
    // The basics.help functions pruneString and escapeStringForFilename
    // only allocate if there is work to do, otherwise they return input.
    void pruneText()
    {
        reqDraw();
        if (allowedChars == AllowedChars.filename)
            _text = escapeStringForFilename(_text);
        else if (allowedChars == AllowedChars.digits)
            _text = pruneString(_text, c => c >= '0' && c <= '9');

        while (! _allowScrolling && _label.tooLong(_text ~ caretChar))
            _text = backspace(_text, CutAt.end);
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
