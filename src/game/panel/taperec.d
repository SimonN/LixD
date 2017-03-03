module game.panel.taperec;

/* The buttons that appear in the bottom-right-hand corner of the screen
 * during singleplayer: Pause, framestepping, nuke, ...
 */

import basics.globals;
import basics.user;
import game.panel.nuke;
import graphic.internal;
import gui;
import hardware.keyset;

class TapeRecorderButtons : Element {
private:
    enum frameFast  = 4;
    enum frameTurbo = 5;

    BitmapButton _restart, _pause, _saveState, _loadState;
    NukeButton _nuke;
    TwoTasksButton _zoom, _speedBack, _speedAhead, _speedFast;

public:
    this(Geom g)
    {
        super(g);
        immutable ylg1 = 20f;
        immutable ylg2 = (ylg - ylg1)/2f;

        void newBut(T)(ref T b, int x, int y, int frame,
            in KeySet keyLeft = 0, in KeySet keyRight = 0)
            if (is(T : BitmapButton))
        {
            b = new T(new Geom(x * xlg/4f, ylg1 * (y >= 1) + ylg2 * (y >= 2),
                               xlg/4f, y == 0 ? ylg1 : ylg2),
                      getInternal(basics.globals.fileImageGamePanel));
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

        _nuke = new NukeButton(new Geom(xlg/2f, ylg1, xlg/4f, ylg2));
        addChild(_nuke);

        _pause = new BitmapButton(
            new Geom(0, 0, xlg/4f, ylg - 20f, From.BOTTOM_RIGHT),
            getInternal(basics.globals.fileImageGamePause));

        // stateSave has xl = (2 * its normal xl) because stateLoad starts hidden.
        // Once there is a savestate, stateSave shrinks and stateLoad pops in.
        _saveState = new BitmapButton(
            new Geom(0, 0, xlg, 20),
            getInternal(basics.globals.fileImageGamePanel2));
        _loadState = new BitmapButton(
            new Geom(xlg/2f, 0, xlg/2f, 20),
            getInternal(basics.globals.fileImageGamePanel2));
        _saveState.xf = 2;
        _loadState.xf = 3;
        showLoadState(false);

        _pause   .hotkey = keyPause;
        _saveState.hotkey = keyStateSave;
        _loadState.hotkey = keyStateLoad;
        addChildren(_pause, _saveState, _loadState);
    }

    @property const {
        bool paused()        { return _pause.on; }
        bool speedIsNormal() { return ! paused && ! _speedFast.on; }
        bool speedIsFast()   { return ! paused && _speedFast.on
                                               && _speedFast.xf == frameFast; }
        bool speedIsTurbo()  { return ! paused && _speedFast.on
                                               && _speedFast.xf == frameTurbo;}
        bool restart()            { return _restart.execute; }
        bool saveState()          { return _saveState.execute; }
        bool loadState()          { return _loadState.execute; }
        bool zoomIn()             { return _zoom.executeLeft; }
        bool zoomOut()            { return _zoom.executeRight; }
        bool framestepBackOne()   { return _speedBack.executeLeft; }
        bool framestepBackMany()  { return _speedBack.executeRight; }
        bool framestepAheadOne()  { return _speedAhead.executeLeft; }
        bool framestepAheadMany() { return _speedAhead.executeRight; }
        bool nukeDoubleclicked()  { return _nuke.doubleclicked; }
    }

    void speedToNormal() { setSpeedTo(1); }
    void nuke(bool b) { _nuke.on = b; }
    void pause(bool b)
    {
        if (b)
            setSpeedTo(0);
        else
            _pause.on = false;
    }

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

    private void setSpeedTo(in int a)
    {
        assert (a >= 0);
        assert (a <  4);
        _pause.on     = (a == 0);
        _speedFast.on = (a >= 2);
        _speedFast.xf = (a < 3 ? frameFast : frameTurbo);
    }
}
