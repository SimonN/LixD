module gui.button.button;

/* A clickable button, can have a hotkey.
 *
 * Two design patterns are supported: a) Event-based callback and b) polling.
 * a) To poll the button, (bool execute() const) during its parent's calc().
 * b) To register a delegate f to be called back, use onExecute(f).
 */

import std.algorithm;
import std.conv;
import std.string;

import basics.alleg5; // we shorten the hotkey label ourselves, not a Label
import basics.help;
import basics.user; // hotkey display option

import graphic.color;
import gui;
import hardware.keyboard;
import hardware.keyset;
import hardware.mouse;

class Button : Element {
private:
    KeySet _hotkey;
    bool _execute;
    bool _down;
    bool _on;
    void delegate() _onExecute;

public:
    WhenToExecute whenToExecute;

    enum WhenToExecute {
        whenMouseRelease, // cold, normal menu buttons
        whenMouseClick, // warm, pause button
        whenMouseHeld, // hot, skill button
        whenMouseClickAllowingRepeats // spawnint, framestepping
    }

    this(Geom g) { super(g); }

    // execute is read-only. Derived classes should make their own bool
    // and then override execute().
    @property bool execute() const              { return _execute; }
    @property void onExecute(void delegate() f) { _onExecute = f;  }

    mixin (GetSetWithReqDraw!"hotkey");
    mixin (GetSetWithReqDraw!"down");
    mixin (GetSetWithReqDraw!"on");

    override @property bool shown() const { return super.shown; }
    override @property bool shown(in bool b)
    {
        if (super.shown != b) {
            super.shown = b;
            _down    = false;
            _execute = false;
        }
        return super.shown;
    }

    Alcol colorText() { return _on && ! _down ? color.guiTextOn
                                              : color.guiText; }
protected:
    // override these if needed
    void   drawOntoButton()     { }
    string hotkeyString() const { return _hotkey.nameShort; }

    override void
    calcSelf()
    {
        immutable mouseHere = isMouseHere();
        final switch (whenToExecute) {
        case WhenToExecute.whenMouseRelease:
            down     = mouseHere && mouseHeldLeft;
            _execute = mouseHere && mouseReleaseLeft || _hotkey.keyTapped;
            break;
        case WhenToExecute.whenMouseClick:
            down     = mouseHere && mouseHeldLeft;
            _execute = mouseHere && mouseClickLeft || _hotkey.keyTapped;
            break;
        case WhenToExecute.whenMouseHeld:
            down     = false;
            _execute = mouseHere && mouseHeldLeft || _hotkey.keyTapped;
            break;
        case WhenToExecute.whenMouseClickAllowingRepeats:
            down     = mouseHere && mouseHeldLeft;
            _execute = mouseHere && mouseClickLeft
                    || mouseHere && mouseHeldLongLeft
                    || _hotkey.keyTappedAllowingRepeats;
            break;
        }
        if (_onExecute !is null && _execute)
            _onExecute();
    }

    final override void // override drawOntoButton instead
    drawSelf()
    {
        // select the colors according to the button's state
        auto c1 = _down ? color.guiDownD : _on ? color.guiOnD : color.guiL;
        auto c2 = _down ? color.guiDownM : _on ? color.guiOnM : color.guiM;
        auto c3 = _down ? color.guiDownL : _on ? color.guiOnL : color.guiD;
        draw3DButton(xs, ys, xls, yls, c1, c2, c3);
        drawOntoButton();
        if (basics.user.showButtonHotkeys.value) {
            children.each!(ch => ch.draw); // force drawing now, such that...
            drawHotkey();                  // the hotkey is drawn on top
        }
    }

private:
    void drawHotkey()
    {
        string s = hotkeyString();
        // Minor copy-pasta from gui.Label. The hotkey label is not a Label.
        while (s.length && al_get_text_width(djvuS, s.toStringz)
                        / gui.stretchFactor >= this.xlg - 2 * gui.thickg)
            s = basics.help.backspace(s);
        if (s.length)
            drawTextRight(djvuS, s,
                xs + xls - gui.thicks,
                ys + yls - gui.thicks - al_get_font_line_height(djvuS),
                colorText);
    }
}
