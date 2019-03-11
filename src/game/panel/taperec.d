module game.panel.taperec;

/* The buttons that appear in the bottom-right-hand corner of the screen
 * during singleplayer: Pause, framestepping, nuke, ...
 */

import std.algorithm;

import file.option;
import game.panel.nuke;
import game.panel.tooltip;
import graphic.internal;
import gui;
import hardware.keyset;

// This doesn't have save/load state
class TapeRecorderButtons : Element, TooltipSuggester {
private:
    enum frameFast  = 4;
    enum frameTurbo = 5;

    // All the buttons are non-null, always
    BitmapButton _restart, _pause;
    NukeButton _nuke;
    TwoTasksButton _zoom, _speedBack, _speedAhead, _speedFast;

public:
    this(Geom g)
    {
        super(g);
        immutable ylg1 = 0f;
        immutable ylg2 = ylg/2f;

        void newBut(T)(ref T b, int x, int y, int frame,
            in KeySet keyLeft = 0, in KeySet keyRight = 0)
            if (is(T : BitmapButton))
        {
            b = new T(new Geom(x * xlg/4f, ylg1 * (y >= 1) + ylg2 * (y >= 2),
                               xlg/4f, y == 0 ? ylg1 : ylg2),
                InternalImage.gamePanel.toCutbit);
            b.xf = frame;
            b.hotkey = keyLeft;
            static if (is (T == TwoTasksButton))
                b.hotkeyRight = keyRight;
            addChild(b);
        }
        newBut(_zoom,       0, 1,  2, keyZoomIn, keyZoomOut);
        newBut(_speedBack,  0, 2, 10, keyFrameBackOne, keyFrameBackMany);
        newBut(_speedAhead, 1, 2,  3, keyFrameAheadOne, keyFrameAheadMany);
        newBut(_speedFast,  2, 2, frameFast, keySpeedFast, keySpeedTurbo);
        newBut(_restart,    1, 1,  8, keyRestart);

        _nuke = new NukeButton(new Geom(xlg/2f, ylg1, xlg/4f, ylg2),
                               NukeButton.WideDesign.no);
        addChild(_nuke);

        _pause = new BitmapButton(
            new Geom(0, 0, xlg/4f, ylg - ylg1, From.BOTTOM_RIGHT),
            InternalImage.gamePause.toCutbit);
        _pause.hotkey = keyPause;
        addChild(_pause);
    }

    @property const {
        bool paused()        { return _pause.on; }
        bool speedIsNormal() { return ! paused && ! _speedFast.on; }
        bool speedIsFast()   { return ! paused && _speedFast.on
                                               && _speedFast.xf == frameFast; }
        bool speedIsTurbo()  { return ! paused && _speedFast.on
                                               && _speedFast.xf == frameTurbo;}
        bool restart()            { return _restart.execute; }
        bool zoomIn()             { return _zoom.executeLeft; }
        bool zoomOut()            { return _zoom.executeRight; }
        bool framestepBackOne()   { return _speedBack.executeLeft; }
        bool framestepBackMany()  { return _speedBack.executeRight; }
        bool framestepAheadOne()  { return _speedAhead.executeLeft; }
        bool framestepAheadMany() { return _speedAhead.executeRight; }
        bool nukeDoubleclicked()  { return _nuke.doubleclicked; }

        bool isSuggestingTooltip()
        {
            return children.any!(ch => ch.isMouseHere);
        }

        Tooltip.ID suggestedTooltip()
        in { assert (isSuggestingTooltip); }
        body {
            return _restart.isMouseHere ? Tooltip.ID.restart
                : _pause.isMouseHere ? Tooltip.ID.pause
                : _nuke.isMouseHere ? Tooltip.ID.nuke
                : _zoom.isMouseHere ? Tooltip.ID.zoom
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

class SaveStateButtons : Element, TooltipSuggester {
private:
    BitmapButton _saveState, _loadState;

public:
    this(Geom g)
    {
        super(g);

        // stateSave.xl = (2 * its normal xl) because stateLoad starts hidden.
        // Once there is a savestate, stateSave shrinks and stateLoad pops in.
        _saveState = new BitmapButton(
            new Geom(0, 0, xlg, 20),
            InternalImage.gamePanel2.toCutbit);
        _loadState = new BitmapButton(
            new Geom(xlg/2f, 0, xlg/2f, 20),
            InternalImage.gamePanel2.toCutbit);
        _saveState.xf = GamePanel2Xf.quicksave;
        _loadState.xf = GamePanel2Xf.quickload;
        _saveState.hotkey = keyStateSave;
        _loadState.hotkey = keyStateLoad;
        addChildren(_saveState, _loadState);
        showLoadState(false);
    }

    @property const {
        bool saveState() { return _saveState.execute; }
        bool loadState() { return _loadState.execute; }

        bool isSuggestingTooltip()
        {
            return children.any!(ch => ch.isMouseHere);
        }

        Tooltip.ID suggestedTooltip()
        in { assert (isSuggestingTooltip); }
        body {
            return _saveState.isMouseHere ? Tooltip.ID.stateSave
                : Tooltip.ID.stateLoad;
        }
    }

protected:
    override void calcSelf()
    {
        if (_saveState.execute)
            showLoadState(true);
    }


private:
    // I assumed that the game should inform the panel about whether there are
    // savestates. But now, I call it in this.calcSelf, that seems enough.
    void showLoadState(bool b)
    {
        _saveState.resize(b ? xlg/2f : xlg, _saveState.ylg);
        _loadState.shown = b;
    }
}
