module gui.button.key;

import basics.alleg5; // timerTicks
import basics.globals; // ticksForDoubleClick
import gui;
import hardware.keyboard;
import hardware.keyset;
import hardware.mouse;

class KeyButton : TextButton {
private:
    KeySet _keySet;

public:
    this(Geom g, in KeySet set = KeySet())
    {
        super(g);
        _keySet = KeySet(set);
    }

    @property const(KeySet) keySet() const { return _keySet; }
    @property const(KeySet) keySet(in KeySet sc)
    {
        if (sc == _keySet)
            return sc;
        _keySet = KeySet(sc);
        formatScancode();
        return sc;
    }

    @property override bool on() const { return super.on(); }
    @property override bool on(in bool b)
    {
        if (b == on)
            return b;
        super.on(b);
        if (b) addFocus(this);
        else    rmFocus(this);
        return b;
    }

protected:
    override void calcSelf()
    {
        super.calcSelf();
        if (! on)
            on = execute;
        else {
            if (mouseClickLeft)
                // Only LMB cancels this. RMB and MMB are assignable hotkeys.
                on = false;
            else if (scancodeTapped) {
                _keySet = KeySet(scancodeTapped);
                on = false;
            }
            formatScancode();
        }
    }

private:
    void formatScancode()
    {
        reqDraw();
        text = (on && timerTicks % 30 < 15)
            ? "\ufffd" // replacement char, question mark in a box
            : _keySet.nameLong;
    }
}
