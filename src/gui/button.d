module gui.button;

/* A clickable button, can have a hotkey.
 *
 * Two design patterns are supported: a) Event-based and b) polling.
 * a) To poll the button, query get_clicked() during its parent's calc().
 * b) To register a delegate f to be executed on click, use set_on_click(f).
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
    @property int  hotkey() const    { return _hotkey;     }
    @property int  hotkey(int i = 0) { return _hotkey = i; }

    @property bool clicked() const             { return _clicked_last_calc; }
    @property void on_click(void delegate() f) { _on_click = f; }

private:

    bool _warm;   // if true, activate upon mouse click, not on mouse release
    bool _hot;    // if true, activate upon mouse down,  not on click/release
    int  _hotkey; // default is 0, which is not a key.

    bool _clicked_last_calc;
    bool _down;
    bool _on;

    void delegate() _on_click;



protected:

override void
calc_self()
{
    immutable bool mouse_here = is_mouse_here();

    if (hidden) {
        _clicked_last_calc = false;
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
        // Active clicking.
        // If the hotkey is ALLEGRO_KEY_ENTER, then we allow
        // ALLEGRO_KEY_PAD_ENTER too.
        bool b =
            (! _warm && ! _hot && mouse_here && get_mlr())
         || (  _warm && ! _hot && mouse_here && get_ml ())
         || (             _hot && mouse_here && get_mlh());
        // See module hardware.keyboard for why Enter is separated
        if (_hotkey == ALLEGRO_KEY_ENTER) b = b || key_enter_once();
        else                              b = b || key_once(_hotkey);

        _clicked_last_calc = b;
        if (_on_click !is null && _clicked_last_calc) _on_click();
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
