module game.panel.nuke;

import std.string;

import basics.alleg5;
import basics.globals;
import opt = file.option.allopts;
import game.panel.tooltip;
import graphic.color;
import graphic.internal;
import gui;
import hardware.keyset;

class NukeButton : Button, TooltipSuggester {
private:
    bool _doubleclicked;
    typeof(timerTicks) _lastExecute;
    bool _overtimeRunning;
    int _overtimeRemainingInPhyus;

    CutbitElement _icon; // Reimplement this part of BitmapButton to move it
    Label _label; // null when constructed with WithTimeLabel.no

public:
    enum WithTimeLabel : bool { no, yes }

    this(Geom g, in WithTimeLabel withTimeLabel)
    {
        super(g);
        hotkey = opt.keyNuke.value;

        if (withTimeLabel == WithTimeLabel.no) {
            _icon = new CutbitElement(new Geom(0, 0, xlg, ylg,
                From.CENTER), InternalImage.gamePanel.toCutbit);
            _icon.xf = 9;
            addChild(_icon);
        }
        else if (xlg < 80) {
            _icon = new CutbitElement(new Geom(0, 0, xlg/2, ylg,
                From.RIGHT), InternalImage.gamePanel2.toCutbit);
            _icon.xf = GamePanel2Xf.nuke;
            immutable float x = TextButton.textXFromLeft;
            _label = new Label(new Geom(x, 0, xlg - 2f*x, 20,
                From.LEFT), "0:00");
            addChildren(_icon, _label);
        }
        else {
            _icon = new CutbitElement(new Geom(xlg/6f, 0, xlg*2f/3f, ylg,
                From.CENTER), InternalImage.gamePanel2.toCutbit);
            _label = new Label(new Geom(-xlg/6f, 0, xlg*2f/3f, 20,
                From.CENTER), "0:00");
            addChildren(_icon, _label);
        }
    }

    bool doubleclicked() const { return _doubleclicked; }

    void overtimeRunning(in bool ru)
    {
        if (ru == _overtimeRunning || ! _label)
            return;
        _overtimeRunning = ru;
        _label.color = _overtimeRunning ? color.guiTextOn : color.guiText;
        reqDraw();
    }

    void overtimeRemainingInPhyus(in int re)
    in { assert (re >= 0); }
    do {
        if (re == _overtimeRemainingInPhyus || ! _label)
            return;
        _overtimeRemainingInPhyus = re;
        immutable secs = (re + phyusPerSecondAtNormalSpeed - 1)
            / phyusPerSecondAtNormalSpeed;
        _label.text = format!"%d:%02d"(secs / 60, secs % 60);
        reqDraw();
    }

    bool isSuggestingTooltip() const { return this.isMouseHere; }
    Tooltip.ID suggestedTooltip() const { return Tooltip.ID.nuke; }

protected:
    override void calcSelf()
    {
        super.calcSelf();
        _doubleclicked = false;
        _icon.yf = on ? 1 : 0;
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

class ToggleableTooltipSuggestingButton : BitmapButton, TooltipSuggester {
private:
    Tooltip.ID _tooltipId;

public:
    this(Geom g, in int aXf, in KeySet aHotkey, in Tooltip.ID tooltipId)
    {
        super(g, InternalImage.gamePanel2.toCutbit);
        xf = aXf;
        hotkey = aHotkey;
        _tooltipId = tooltipId;
        onExecute = () { on = ! on; };
    }

    bool isSuggestingTooltip() const { return this.isMouseHere; }
    Tooltip.ID suggestedTooltip() const { return _tooltipId; }
}

class HighlightGoalsButton : BitmapButton, TooltipSuggester {
public:
    this(Geom g)
    {
        super(g, InternalImage.gamePanel2.toCutbit);
        xf = GamePanel2Xf.highlightGoals;
        hotkey = opt.keyHighlightGoals.value;
    }

    bool isSuggestingTooltip() const { return this.isMouseHere; }
    Tooltip.ID suggestedTooltip() const
    {
        return Tooltip.ID.highlightGoals;
    }
}
