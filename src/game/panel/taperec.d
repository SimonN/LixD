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
    BitmapButton _pause, _restart;
    NukeButton _nuke;
    TwoTasksButton _speedBack, _speedAhead, _speedFast;

public:
    this(Geom g)
    {
        super(g);
        void newBut(T)(ref T b, int x, int y, int frame,
            in UserOption!KeySet keyLeft = null,
            in UserOption!KeySet keyRight = null)
            if (is(T : BitmapButton))
        {
            b = new T(new Geom(x * xlg/4f, y * ylg/2f, xlg/4f, ylg/2f),
                InternalImage.gamePanel.toCutbit);
            b.xf = frame;
            b.hotkey = keyLeft ? keyLeft.value : KeySet();
            static if (is (T == TwoTasksButton))
                b.hotkeyRight = keyRight ? keyRight.value : KeySet();
            addChild(b);
        }
        newBut(_restart, 0, 0, 8, opt.keyRestart);
        _restart.resize(xlg/2f, ylg/2f); // Until we have a better layout idea.

        newBut(_speedBack, 0, 1, 10, opt.keyFrameBackOne, opt.keyFrameBackMany);
        newBut(_speedAhead, 1, 1, 3,
            opt.keyFrameAheadOne, opt.keyFrameAheadMany);
        newBut(_speedFast, 2, 1, frameFast,
            opt.keySpeedFast, opt.keySpeedTurbo);

        _nuke = new NukeButton(new Geom(2 * xlg/4f, 0, xlg/4f, ylg/2f),
                               NukeButton.WithTimeLabel.no);
        addChild(_nuke);

        _pause = new BitmapButton(
            new Geom(0, 0, xlg/4f, ylg, From.BOTTOM_RIGHT),
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
        bool restart()            { return _restart.execute; }
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
                : _restart.isMouseHere ? Tooltip.ID.restart
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
