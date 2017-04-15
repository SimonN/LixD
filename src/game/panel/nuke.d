module game.panel.nuke;

import basics.alleg5;
import basics.globals;
import basics.user;
import graphic.internal;
import gui;

class NukeButton : BitmapButton {
private:
    bool _doubleclicked;
    typeof(timerTicks) _lastExecute;

public:
    enum WideDesign : bool { no, yes }

    this(Geom g, in WideDesign wide)
    {
        super(g, getInternal(wide ? fileImageGameNuke : fileImageGamePanel));
        hotkey = keyNuke;
        xf = wide ? 0 : 9;
    }

    @property bool doubleclicked() const { return _doubleclicked; }

protected:
    override void calcSelf()
    {
        super.calcSelf();
        _doubleclicked = false;
        if (! on && execute) {
            auto now = timerTicks;
            _doubleclicked = (now - _lastExecute < ticksForDoubleClick);
            _lastExecute   = now;
        }
        if (! on && hotkey.keyHeld)
            down = true;
        else if (on)
            down = false;
    }
}
