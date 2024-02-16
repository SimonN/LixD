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
    BitmapButton _pause, _restart, _rewindPrevPly;
    NukeButton _nuke;
    TwoTasksButton _rewind, _skip, _speedFast;

public:
    this(Geom g)
    {
        super(g);
        void newBut(T)(ref T b, int x, int y, InternalImage img, int frame,
            in UserOption!KeySet keyLeft = null,
            in UserOption!KeySet keyRight = null)
            if (is(T : BitmapButton))
        {
            b = new T(new Geom(x * xlg/4f, y * ylg/2f, xlg/4f, ylg/2f),
                img.toCutbit);
            b.xf = frame;
            b.hotkey = keyLeft ? keyLeft.value : KeySet();
            static if (is (T == TwoTasksButton))
                b.hotkeyRight = keyRight ? keyRight.value : KeySet();
            addChild(b);
        }
        newBut(_rewindPrevPly, 0, 0, InternalImage.rewindPrevPly, 0,
            opt.keyRewindPrevPly);
        newBut(_restart, 1, 0, InternalImage.gamePanel, 8, opt.keyRestart);
        newBut(_rewind, 0, 1, InternalImage.gamePanel, 10,
            opt.keyRewindOneTick, opt.keyRewindOneSecond);
        newBut(_skip, 1, 1, InternalImage.gamePanel, 3,
            opt.keySkipOneTick, opt.keySkipTenSeconds);
        newBut(_speedFast, 2, 1, InternalImage.gamePanel, frameFast,
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
        bool rewindOneTick() { return _rewind.executeLeft; }
        bool rewindOneSecond() { return _rewind.executeRight; }
        bool rewindPrevPly() { return _rewindPrevPly.execute; }
        bool skipOneTick()  { return _skip.executeLeft; }
        bool skipTenSeconds() { return _skip.executeRight; }
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
                : _rewindPrevPly.isMouseHere ? Tooltip.ID.rewindPrevPly
                : _rewind.isMouseHere ? Tooltip.ID.rewindOneTick
                : _skip.isMouseHere ? Tooltip.ID.skipOneTick
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
        if (_pause.execute)
            setSpeedTo(paused ? 1 : 0);
        else if (_speedFast.executeLeft)
            setSpeedTo(_speedFast.on ? 1 : 2);
        else if (_speedFast.executeRight)
            setSpeedTo(_speedFast.xf == frameTurbo ? 1 : 3);
        // See game.core.speed for pausing/unpausing on framestepping.
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
