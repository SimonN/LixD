module gui.picker.scrollb;

import std.algorithm;

import basics.globals;
import graphic.internal;
import graphic.color;
import gui;

class Scrollbar : Element {
private:
    Frame _track;
    BitmapButton _up;
    BitmapButton _down;
    Button _car;

    int _totalLen;
    int _pageLen;
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
        _car = new Button(new Geom(0, xlg, xlg, ylg - 2 * xlg));
        undrawColor        = color.guiM;
        _track.undrawColor = color.guiM;
        addChildren(_track, _up, _down, _car);
    }

    @property totalLen() const { return _totalLen; }
    @property pageLen()  const { return _pageLen;  }
    @property pos()      const { return _pos;      }
    @property execute()  const { return _execute;  }

    @property int totalLen(in int i)
    {
        assert (i >= 0);
        if (_totalLen == i)
            return _totalLen;
        _totalLen = i;
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

    @property int pos(in int i)
    {
        if (_pos == i)
            return _pos;
        _pos = clamp(i, 0, _totalLen - _pageLen);
        updateCar();
        return _pos;
    }

protected:
    override void calcSelf()
    {
        immutable oldPos = pos;
        pos = pos + _down.execute() - _up.execute();
        _execute = pos != oldPos;
        if (disabled)
            _car.down = _up.down = _down.down = false;
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
        if (disabled)
            return;
        _car.resize(xlg,         _track.ylg * pageLen / totalLen);
        _car.move  (0, _up.ylg + _track.ylg * pos     / totalLen);
    }
}
