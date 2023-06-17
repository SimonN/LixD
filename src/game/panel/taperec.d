module game.panel.taperec;

/*
 * The buttons that appear in the bottom-right-hand corner of the screen
 * during singleplayer: Pause, framestepping, nuke, ...
 *
 *  +-------------+-------------+-------------+
 *  |             |             |             |
 *  |     Nuke    |     >>>     |             |
 *  |             |             |             |
 *  +-------------+-------------+    Pause    |
 *  |             |             |             |
 *  |     < |     |     | >     |             |
 *  |             |             |             |
 *  +-------------+-------------+-------------+
 *
 *  Does _not_ contain menu-opening button, tweaker-opening button, ...
 */

import std.algorithm;

import opt = file.option.allopts;
import file.option.useropt;
import game.panel.nuke;
import game.panel.tooltip;
import graphic.internal;
import gui;
import hardware.keyset;

class TapeRecorderButtons : Element, TooltipSuggester {
private:
    enum frameFast  = 4;
    enum frameTurbo = 5;

    // All the buttons are non-null, always
    BitmapButton _pause;
    NukeButton _nuke;
    TwoTasksButton _speedBack, _speedAhead, _speedFast;

public:
    this(Geom g)
    {
        super(g);
        immutable ylg1 = 0f;
        immutable ylg2 = ylg/2f;

        void newBut(T)(ref T b, int x, int y, int frame,
            in UserOption!KeySet keyLeft = null,
            in UserOption!KeySet keyRight = null)
            if (is(T : BitmapButton))
        {
            b = new T(new Geom(x * xlg/3f, ylg1 * (y >= 1) + ylg2 * (y >= 2),
                               xlg/3f, y == 0 ? ylg1 : ylg2),
                InternalImage.gamePanel.toCutbit);
            b.xf = frame;
            b.hotkey = keyLeft ? keyLeft.value : KeySet();
            static if (is (T == TwoTasksButton))
                b.hotkeyRight = keyRight ? keyRight.value : KeySet();
            addChild(b);
        }
        newBut(_speedBack, 0, 2, 10, opt.keyFrameBackOne, opt.keyFrameBackMany);
        newBut(_speedAhead, 1, 2, 3,
            opt.keyFrameAheadOne, opt.keyFrameAheadMany);
        newBut(_speedFast, 1, 1, frameFast,
            opt.keySpeedFast, opt.keySpeedTurbo);

        _nuke = new NukeButton(new Geom(0, ylg1, xlg/3f, ylg2),
                               NukeButton.WithTimeLabel.no);
        addChild(_nuke);

        _pause = new BitmapButton(
            new Geom(0, 0, xlg/3f, ylg - ylg1, From.BOTTOM_RIGHT),
            InternalImage.gamePause.toCutbit);
        _pause.hotkey = opt.keyPause.value;
        addChild(_pause);
    }

    const {
        bool paused()        { return _pause.on; }
        bool speedIsNormal() { return ! paused && ! _speedFast.on; }
        bool speedIsFast()   { return ! paused && _speedFast.on
                                               && _speedFast.xf == frameFast; }
        bool speedIsTurbo()  { return ! paused && _speedFast.on
                                               && _speedFast.xf == frameTurbo;}
        bool framestepBackOne()   { return _speedBack.executeLeft; }
        bool framestepBackMany()  { return _speedBack.executeRight; }
        bool framestepAheadOne()  { return _speedAhead.executeLeft; }
        bool framestepAheadMany() { return _speedAhead.executeRight; }
        bool nukeDoubleclicked()  { return _nuke.doubleclicked; }
    }

    const nothrow @safe @nogc {
        bool isSuggestingTooltip()
        {
            return children.any!(ch => ch.isMouseHere);
        }

        Tooltip.ID suggestedTooltip()
        in { assert (isSuggestingTooltip); }
        do {
            return _pause.isMouseHere ? Tooltip.ID.pause
                : _nuke.isMouseHere ? Tooltip.ID.nuke
                : _speedBack.isMouseHere ? Tooltip.ID.framestepBack
                : _speedAhead.isMouseHere ? Tooltip.ID.framestepAhead
                : Tooltip.ID.fastForward;
        }
    }

    void setSpeedNormal() { setSpeedTo(1); }
    void pause(bool b)
    {
        if (b)
            setSpeedTo(0);
        else
            _pause.on = false;
    }

    inout(NukeButton) nuke() inout { return _nuke; }

protected:
    override void calcSelf()
    {
        assert (!!_pause && !!_speedBack && !!_speedAhead && !!_speedFast);
        if (_pause.execute)
            setSpeedTo(paused ? 1 : 0);
        else if (_speedFast.executeLeft)
            setSpeedTo(_speedFast.on ? 1 : 2);
        else if (_speedFast.executeRight)
            setSpeedTo(_speedFast.xf == frameTurbo ? 1 : 3);
        else if (_speedBack.executeLeft || _speedBack.executeRight
                                        || _speedAhead.executeLeft)
            setSpeedTo(0);
        // We don't handle (speed back to normal) on level restart.
        // Game will tell us to set the speed. Reason: Not only we can
        // restart the level, but the game can get that command from
        // the end-of-level dialog.
    }

private:
    void setSpeedTo(in int a)
    {
        assert (a >= 0);
        assert (a <  4);
        _pause.on     = (a == 0);
        _speedFast.on = (a >= 2);
        _speedFast.xf = (a < 3 ? frameFast : frameTurbo);
    }
}
