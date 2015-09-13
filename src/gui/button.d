module gui.button;

/* A clickable button, can have a hotkey.
 *
 * Two design patterns are supported: a) Event-based callback and b) polling.
 * a) To poll the button, (bool execute() const) during its parent's calc().
 * b) To register a delegate f to be called back, use on_execute(f).
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
    @property bool down(bool b) { _down = b; req_draw(); return _down; }
    @property bool on  (bool b) { _on   = b; req_draw(); return _on;   }

    @property bool warm() const { return _warm; }
    @property bool hot () const { return _hot;  }
    @property bool warm(bool b) { _warm = b; _hot  = false; return _warm; }
    @property bool hot (bool b) { _hot  = b; _warm = false; return _hot;  }

    AlCol get_color_text()      { return _on && ! _down ? color.gui_text_on
                                                        : color.gui_text; }
    @property int hotkey() const { return _hotkey;     }
    @property int hotkey(int i)  { return _hotkey = i; }

    // execute is read-only. Derived classes should make their own bool
    // and then override execute().
    @property bool execute() const { return _execute; }

    @property void on_execute(void delegate() f) { _on_execute = f; }

private:

    bool _warm;   // if true, activate upon mouse click, not on mouse release
    bool _hot;    // if true, activate upon mouse down,  not on click/release
    int  _hotkey; // default is 0, which is not a key.

    bool _execute;
    bool _down;
    bool _on;

    void delegate() _on_execute;



protected:

override void
calc_self()
{
    immutable bool mouse_here = is_mouse_here();

    if (hidden) {
        _execute = false;
    }
    else {
        // Appear pressed down, but not activated? This is only possible
        // in cold mode. We're using the same check for switching back off
        // a warm button too, but never for hot buttons.
        if (! _hot) {
            if (mouse_here && get_mlh() && (! _warm || ! _on)) {
                if (! _down) req_draw();
                _down = true;
            }
            else {
                if (_down) req_draw();
                _down = false;
            }
        }
        // Check whether to execute by clicks/releases or hotkey down.
        _execute = key_once(_hotkey);
        _execute = _execute
            || (! _warm && ! _hot && mouse_here && get_mlr())
            || (  _warm && ! _hot && mouse_here && get_ml ())
            || (             _hot && mouse_here && get_mlh());
        if (_on_execute !is null && _execute)
            _on_execute();
    }
}



override void
draw_self()
{
    // select the colors according to the button's state
    auto c1 = _down ? color.gui_down_d : _on ? color.gui_on_d : color.gui_l;
    auto c2 = _down ? color.gui_down_m : _on ? color.gui_on_m : color.gui_m;
    auto c3 = _down ? color.gui_down_l : _on ? color.gui_on_l : color.gui_d;

    draw_3d_button(xs, ys, xls, yls, c1, c2, c3);
}

}
// end class
