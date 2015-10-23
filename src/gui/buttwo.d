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
    @property bool executeLeft()  const { return _executeLeft;  }
    @property bool executeRight() const { return _executeRight; }

    @property int hotkeyRight() const { return _hotkeyRight;     }
    @property int hotkeyRight(int i)  { return _hotkeyRight = i; }

    // forward/wrap Button methods for convenience
    @property int  hotkeyLeft() const { return hotkey;     }
    @property int  hotkeyLeft(int i)  { return hotkey = i; }

    override @property bool execute() const { return _executeLeft
                                                  || _executeRight; }
private:

    bool _executeLeft;
    bool _executeRight;

    int _hotkeyRight;
    int _ticksLMBIsHeldFor; // to have left mouse button (LMB) behave like
                            // a keypress that's repeated after a while.
protected:                  // Doesn't exist for RMB, only for hotkeyRight.

    override void calcSelf()
    {
        _executeLeft  = false;
        _executeRight = false;
        down          = false;

        if (hidden) {
            _ticksLMBIsHeldFor = 0;
            return;
        }

        // don't call Button.calcSelf, we're executing on mouse release
        _executeLeft  = hardware.keyboard.keyTapped(hotkey);
        _executeRight = hardware.keyboard.keyTapped(_hotkeyRight);

        if (isMouseHere) {
            _executeLeft  = _executeLeft  || mouseClickLeft();
            _executeRight = _executeRight || mouseClickRight();
            if (mouseHeldLeft)
                ++_ticksLMBIsHeldFor;
            else
                _ticksLMBIsHeldFor = 0;
        }
        else {
            _ticksLMBIsHeldFor = 0;
        }
        if (! warm && ! hot)
            if (_ticksLMBIsHeldFor > 30)
                _executeLeft = true;

        down = keyHeld(hotkey) || keyHeld(_hotkeyRight)
            || (isMouseHere && (mouseHeldLeft || mouseHeldRight));
    }
    // end calcSelf

}
// end class TwoTasksButton



class SpawnIntervalButton : TwoTasksButton {

public:

    this(Geom g)
    {
        super(g, getInternal(basics.globals.fileImageGamePanel2));
        Geom g2 = new Geom(g);
        g2.x   -= g.xl - 13;
        g2.from = From.CENTER;
        _label  = new Label(g2);
        addChild(_label);
    }

    @property int spawnint() const { return _spawnint; }

    @property int spawnint(in int i)
    {
        _spawnint = i;
        _label.number = _spawnint;
        reqDraw();
        return _spawnint;
    }

private:

    int   _spawnint;
    Label _label;

}
// end class SpawnIntervalButton
