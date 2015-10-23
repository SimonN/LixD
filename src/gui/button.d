module gui.button;

/* A clickable button, can have a hotkey.
 *
 * Two design patterns are supported: a) Event-based callback and b) polling.
 * a) To poll the button, (bool execute() const) during its parent's calc().
 * b) To register a delegate f to be called back, use onExecute(f).
 */

import basics.alleg5; // keyboard enum
import graphic.color;
import gui;
import hardware.keyboard;
import hardware.mouse;

class Button : Element {

    this(Geom g) { super(g); }

    @property bool down() const { return _down; }
    @property bool on  () const { return _on;   }
    @property bool down(bool b) { _down = b; reqDraw(); return _down; }
    @property bool on  (bool b) { _on   = b; reqDraw(); return _on;   }

    @property bool warm() const { return _warm; }
    @property bool hot () const { return _hot;  }
    @property bool warm(bool b) { _warm = b; _hot  = false; return _warm; }
    @property bool hot (bool b) { _hot  = b; _warm = false; return _hot;  }

    AlCol colorText() { return _on && ! _down ? color.guiTextOn
                                              : color.guiText; }

    @property int hotkey() const { return _hotkey;     }
    @property int hotkey(int i)  { return _hotkey = i; }

    // execute is read-only. Derived classes should make their own bool
    // and then override execute().
    @property bool execute() const { return _execute; }

    @property void onExecute(void delegate() f) { _onExecute = f; }

private:

    bool _warm;   // if true, activate upon mouse click, not on mouse release
    bool _hot;    // if true, activate upon mouse down,  not on click/release
    int  _hotkey; // default is 0, which is not a key.

    bool _execute;
    bool _down;
    bool _on;

    void delegate() _onExecute;



protected:

override void
calcSelf()
{
    immutable bool mouseHere = isMouseHere();

    if (hidden) {
        _execute = false;
    }
    else {
        // Appear pressed down, but not activated? This is only possible
        // in cold mode. We're using the same check for switching back off
        // a warm button too, but never for hot buttons.
        if (! _hot) {
            if (mouseHere && mouseHeldLeft && (! _warm || ! _on)) {
                if (! _down) reqDraw();
                _down = true;
            }
            else {
                if (_down) reqDraw();
                _down = false;
            }
        }
        // Check whether to execute by clicks/releases or hotkey down.
        _execute = keyTapped(_hotkey);
        _execute = _execute
            || (! _warm && ! _hot && mouseHere && mouseReleaseLeft)
            || (  _warm && ! _hot && mouseHere && mouseClickLeft)
            || (             _hot && mouseHere && mouseHeldLeft);
        if (_onExecute !is null && _execute)
            _onExecute();
    }
}



override void
drawSelf()
{
    // select the colors according to the button's state
    auto c1 = _down ? color.guiDownD : _on ? color.guiOnD : color.guiL;
    auto c2 = _down ? color.guiDownM : _on ? color.guiOnM : color.guiM;
    auto c3 = _down ? color.guiDownL : _on ? color.guiOnL : color.guiD;

    draw3DButton(xs, ys, xls, yls, c1, c2, c3);
}

}
// end class
