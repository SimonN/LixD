module game.panel.nuke;

import std.string;

import basics.alleg5;
import basics.globals;
import basics.user;
import game.core.game;
import graphic.color;
import graphic.internal;
import gui;

class NukeButton : BitmapButton {
private:
    bool _doubleclicked;
    typeof(timerTicks) _lastExecute;
    bool _overtimeRunning;
    int _overtimeRemainingInPhyus;

    Label _label;

public:
    enum WideDesign : bool { no, yes }

    this(Geom g, in WideDesign wide)
    {
        super(g, getInternal(wide ? fileImageGameNuke : fileImageGamePanel));
        hotkey = keyNuke;
        xf = wide ? 0 : 9;
        if (wide) {
            _label = new Label(new Geom(0, 0, xlg, 20, From.CENTER), "0:00");
            addChild(_label);
        }
    }

    @property bool doubleclicked() const { return _doubleclicked; }

    @property overtimeRunning(in bool ru)
    {
        if (ru == _overtimeRunning || ! _label)
            return;
        _overtimeRunning = ru;
        _label.color = _overtimeRunning ? color.guiTextOn : color.guiText;
        reqDraw();
    }

    @property overtimeRemainingInPhyus(in int re)
    in { assert (re >= 0); }
    body {
        if (re == _overtimeRemainingInPhyus || ! _label)
            return;
        _overtimeRemainingInPhyus = re;
        immutable secs = (re + Game.phyusPerSecond - 1) / Game.phyusPerSecond;
        _label.text = format!"%d:%2d"(secs / 60, secs % 60);
        reqDraw();
    }

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
