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

    this(in int x  =   0, in int y  =  0,
         in int xl = 100, in int yl = 20)
    {
        this(Geom.From.TOP_LEFT, x, y, xl, yl);
    }

    this(Geom.From from, in int x  =   0, in int y  =  0,
                         in int xl = 100, in int yl = 20)
    {
        super(from, x, y, xl, yl);
    }

    bool get_down() const        { return down;              }
    bool get_on  () const        { return on;                }
    void set_down(bool b = true) { down = b;     req_draw(); }
    void set_on  (bool b = true) { on   = b;     req_draw(); }
    void set_off ()              { on   = false; req_draw(); }

    bool get_warm() const        { return warm; }
    bool get_hot () const        { return hot;  }
    void set_warm(bool b = true) { warm = b; hot  = false; }
    void set_hot (bool b = true) { hot  = b; warm = false; }

    AlCol get_color_text()       { return on && ! down ? color.gui_text_on
                                                       : color.gui_text; }
    int  get_hotkey() const      { return hotkey; }
    void set_hotkey(int i = 0)   { hotkey = i;    }

    bool get_clicked() const     { return clicked_last_calc; }

    void set_on_click(void delegate() f) { on_click = f; }

private:

    bool warm;   // if true, activate upon mouse click, not on mouse release
    bool hot;    // if true, activate upon mouse down,  not on click/release
    int  hotkey; // default is 0, which is not a key.

    bool clicked_last_calc;
    bool down;
    bool on;

    void delegate() on_click;



protected:

override void
calc_self()
{
    immutable bool mouse_here = is_mouse_here();

    if (get_hidden()) {
        clicked_last_calc = false;
    }
    else {
        // Appear pressed down, but not activated? This is only possible
        // in cold mode. We're using the same check for switching back off
        // a warm button too, but never for hot buttons.
        if (! hot) {
            if (mouse_here && get_mlh() && (! warm || ! on)) {
                if (! down) req_draw();
                down = true;
            }
            else {
                if (down) req_draw();
                down = false;
            }
        }
        // Active clicking.
        // If the hotkey is ALLEGRO_KEY_ENTER, then we allow
        // ALLEGRO_KEY_PAD_ENTER too.
        bool b =
            (! warm && ! hot && mouse_here && get_mlr())
         || (  warm && ! hot && mouse_here && get_ml ())
         || (            hot && mouse_here && get_mlh());
        // See module hardware.keyboard for why Enter is separated
        if (hotkey == ALLEGRO_KEY_ENTER) b = b || key_enter_once();
        else                             b = b || key_once(hotkey);

        clicked_last_calc = b;
        if (on_click !is null && clicked_last_calc) on_click();
    }
}



override void
draw_self()
{
    // select the colors according to the button's state
    immutable c1 = down ? color.gui_down_d : on ? color.gui_on_d : color.gui_l;
    immutable c2 = down ? color.gui_down_m : on ? color.gui_on_m : color.gui_m;
    immutable c3 = down ? color.gui_down_l : on ? color.gui_on_l : color.gui_d;

    draw_3d_button(xs, ys, xls, yls, c1, c2, c3);
}

}
// end class
