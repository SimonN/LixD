module gui.button.key;

import basics.alleg5; // timerTicks
import basics.globals; // ticksForDoubleClick
import gui;
import hardware.keyboard;
import hardware.keynames;
import hardware.mouse;

class KeyButton : TextButton {

    this(Geom g, in int sc = 0)
    {
        super(g);
        scancode = sc;
    }

    @property int scancode() const { return _scancode; }
    @property int scancode(in int sc)
    {
        if (sc == _scancode)
            return sc;
        _scancode = sc;
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

private:

    private int _scancode;

    void formatScancode()
    {
        reqDraw();
        text = (on && timerTicks % 30 < 15)
            ? "\ufffd" // replacement char, question mark in a box
            : hotkeyNiceLong(_scancode);
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
                _scancode = scancodeTapped;
                on = false;
            }
            formatScancode();
        }
    }
}
