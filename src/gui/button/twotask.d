module gui.button.twotask;

/* class TwoTasksButton : BitmapButton
 * class SpawnIntButton : TwoTasksButton
 *
 * warm/hot have different meanings from class Button. Right now, both mean:
 * Don't execute continuously on LMB hold after a while.
 */

import std.format;

import file.language; // Hotkey names
import graphic.cutbit;
import graphic.internal;
import gui;
import hardware.keyset;
import hardware.mouse;

class TwoTasksButton : BitmapButton {
    this(Geom g, const(Cutbit) cb)
    {
        super(g, cb);
        whenToExecute = Button.WhenToExecute.whenMouseClickAllowingRepeats;
        // The default behavior for the left mouse button, therefore,
        // is like a spawn interval button. The right mouse function
        // always works like Button's whenMouseDown and can't be configured.
        // Setting whenToExecute configures the left mouse function only.
    }

    @property bool executeLeft()  const { return _executeLeft;  }
    @property bool executeRight() const { return _executeRight; }

    @property const(KeySet) hotkeyRight() const { return _hotkeyRight; }
    @property const(KeySet) hotkeyRight(in KeySet ks) {
        reqDraw();
        return _hotkeyRight = ks;
    }

    override @property bool execute() const { return _executeLeft
                                                  || _executeRight; }
private:
    bool _executeLeft;
    bool _executeRight;

    KeySet _hotkeyRight;

protected:
    override void calcSelf()
    {
        super.calcSelf();
        _executeLeft  = false;
        _executeRight = false;
        if (! shown)
            return;
        _executeLeft  = super.execute;
        _executeRight = isMouseHere
            && (mouseClickRight() || mouseHeldLongRight())
            || _hotkeyRight.keyTappedAllowingRepeats;
        down = hotkey.keyHeld || _hotkeyRight.keyHeld
            || (isMouseHere && (mouseHeldLeft || mouseHeldRight));
    }

    override string hotkeyString() const
    {
        return hotkey.empty ? _hotkeyRight.nameShort
            : _hotkeyRight.empty ? hotkey.nameShort
            : "%s/%s".format(hotkey.nameShort, _hotkeyRight.nameShort);
    }
}
