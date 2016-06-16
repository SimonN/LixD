module gui.picker.scrollb;

import std.algorithm;

import basics.help;
import basics.globals;
import graphic.internal;
import hardware.mouse; // react directly to mouse wheel
import gui;

class Scrollbar : Element {
private:
    Frame _track;
    BitmapButton _up;
    BitmapButton _down;
    Button _car;

    int _totalLen;
    int _pageLen;
    int _coarseness = 1; // always scroll in multiples of this
    int _wheelSpeed = 5; // should be multiple of _coarseness
    int _pos;

    bool _execute;

public:
    this(Geom g)
    {
        super(g);
        assert (ylg >= 2 * xlg);
        const cb = getInternal(fileImageGuiNumber);
        _track = new Frame(new Geom(xlg/3, xlg, xlg/3, ylg - 2*xlg));
        _up   = new BitmapButton(new Geom(0, 0, xlg, xlg), cb);
        _down = new BitmapButton(new Geom(0, 0, xlg, xlg, From.BOTTOM), cb);
        _up.xf = 8;
        _down.xf = 11;
        _up.whenToExecute = _down.whenToExecute
            = Button.WhenToExecute.whenMouseClickAllowingRepeats;
        _car = new Button(new Geom(0, xlg, xlg, ylg - 2 * xlg));
        addChildren(_track, _up, _down, _car);
    }

    @property totalLen()   const { return _totalLen;   }
    @property pageLen()    const { return _pageLen;    }
    @property coarseness() const { return _coarseness; }
    @property wheelSpeed() const { return _wheelSpeed; }
    @property pos()        const { return _pos;        }
    @property execute()    const { return _execute;    }

    @property int totalLen(in int i)
    {
        assert (i >= 0);
        if (_totalLen == i.roundUpTo(_coarseness))
            return _totalLen;
        _totalLen = i.roundUpTo(_coarseness);
        pos = _pos;
        updateCar();
        return _totalLen;
    }

    @property int pageLen(in int i)
    {
        assert (i >= 0);
        if (_pageLen == i)
            return _pageLen;
        _pageLen = i;
        updateCar();
        return pageLen();
    }

    @property int coarseness(in int i)
    {
        assert (i > 0);
        _coarseness = i;
        totalLen = _totalLen;
        pos = _pos;
        return _coarseness;
    }

    @property int wheelSpeed(in int i)
    {
        assert (i >= 0);
        return _wheelSpeed = i;
    }

    @property int pos(in int i)
    {
        immutable potentialPos = max(0, min(i, _totalLen - _pageLen))
                                .roundTo(_coarseness);
        if (_pos == potentialPos)
            return _pos;
        _pos = potentialPos;
        updateCar();
        return _pos;
    }

protected:
    override void calcSelf()
    {
        startDragging();
        if (this.hasFocus)
            setPosFromDragging();
        else
            setPosFromButtonsAndWheel();
        if (disabled)
            _car.down = _up.down = _down.down = false;
        else if (this.hasFocus) {
            _car.down = true;
            _up.down = _down.down = false;
        }
    }

    override void drawSelf()
    {
        undrawSelf();
        super.drawSelf();
    }

private:
    bool disabled() { return totalLen <= pageLen; }

    void updateCar()
    {
        reqDraw();
        _car.resize(xlg, _track.ylg * (disabled ? 1 : 1f*pageLen / totalLen));
        _car.move(0, _up.ylg + (disabled ? 0 : _track.ylg * pos / totalLen));
    }

    void startDragging()
    {
        if (! this.hasFocus && ! disabled && mouseClickLeft && isMouseHere
            && ! _up.isMouseHere && ! _down.isMouseHere)
            addFocus(this);
    }

    void setPosFromDragging()
    {
        assert (this.hasFocus);
        if (mouseHeldLeft && ! disabled) {
            _execute = true;
            assert (_track.yls > _car.yls);
            pos = roundInt((mouseY - _track.ys - _car.yls / 2f)
                / (_track.yls - _car.yls) // screen range that car can travel
                * (_totalLen - _pageLen));
        }
        else
            rmFocus(this);
    }

    void setPosFromButtonsAndWheel()
    {
        immutable change = _coarseness * (_down.execute() - _up.execute())
                         + _wheelSpeed * mouseWheelNotches();
        _execute = change != 0;
        pos = pos + change;
    }
}
