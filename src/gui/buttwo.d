module gui.buttwo;

/* class TwoTasksButton : BitmapButton
 * class SpawnIntButton : TwoTasksButton
 *
 * warm/hot have different meanings from class Button. Right now, both mean:
 * Don't execute continuously on LMB hold after a while.
 */

import basics.globals; // bitmap file for the spawnint button
import graphic.cutbit;
import graphic.gralib;
import gui;
import hardware.keyboard;
import hardware.mouse;

class TwoTasksButton : BitmapButton {

    this(Geom g, const(Cutbit) cb)
    {
        super(g, cb);
    }

    // Executing spawn interval buttons works differently from executing
    // normal buttons. Normal buttons execute on mouse release, this button
    // executes on a mouse downpress, and can execute repeatedly when the
    // mouse button is held down. What a joy:
    @property bool execute_left()  const { return _execute_left;  }
    @property bool execute_right() const { return _execute_right; }

    @property int hotkey_right() const { return _hotkey_right;     }
    @property int hotkey_right(int i)  { return _hotkey_right = i; }

    // forward/wrap Button methods for convenience
    @property int  hotkey_left() const { return hotkey;     }
    @property int  hotkey_left(int i)  { return hotkey = i; }

    override @property bool execute() const { return _execute_left
                                                  || _execute_right; }
private:

    bool _execute_left;
    bool _execute_right;

    int _hotkey_right;
    int _ticks_lmb_is_held_for; // to have left mouse button (LMB) behave like
                            // a keypress that's repeated after a while.
protected:                  // Doesn't exist for RMB, only for hotkey_right.

    override void calc_self()
    {
        _execute_left  = false;
        _execute_right = false;
        down           = false;

        if (hidden) {
            _ticks_lmb_is_held_for = 0;
            return;
        }

        // don't call Button.calc_self, we're executing on mouse release
        _execute_left  = hardware.keyboard.key_once(hotkey);
        _execute_right = hardware.keyboard.key_once(_hotkey_right);

        if (is_mouse_here) {
            _execute_left  = _execute_left  || get_ml();
            _execute_right = _execute_right || get_mr();
            if (get_mlh())
                ++_ticks_lmb_is_held_for;
            else
                _ticks_lmb_is_held_for = 0;
        }
        else {
            _ticks_lmb_is_held_for = 0;
        }
        if (! warm && ! hot)
            if (_ticks_lmb_is_held_for > 30)
                _execute_left = true;

        down = key_hold(hotkey) || key_hold(_hotkey_right)
            || (is_mouse_here && (get_mlh || get_mrh));
    }
    // end calc_self

}
// end class TwoTasksButton



class SpawnIntervalButton : TwoTasksButton {

public:

    this(Geom g)
    {
        super(g, get_internal(basics.globals.file_bitmap_game_panel_2));
        Geom g2 = new Geom(g);
        g2.x   -= g.xl - 13;
        g2.from = From.CENTER;
        _label  = new Label(g2);
        add_child(_label);
    }

    @property int spawnint() const { return _spawnint; }

    @property int spawnint(in int i)
    {
        _spawnint = i;
        _label.number = _spawnint;
        req_draw();
        return _spawnint;
    }

private:

    int   _spawnint;
    Label _label;

}
// end class SpawnIntervalButton
