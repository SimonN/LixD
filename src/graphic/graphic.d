module graphic.graphic;

/* A simple graphic object, i.e., an instance of Cutbit that is drawn to
 * a certain position on a torbit. This is not about graphic sets from L1,
 * ONML etc., see level/gra_set.h for that.
 */

import std.conv; // rounding/chopping double to int
import std.math;
import std.string : format; // for assert error only

import basics.alleg5;
import basics.help; // rounding float to a good int
import basics.topology;
import graphic.cutbit;
import graphic.torbit;

class Graphic {
private:
    Point  _loc;
    bool   _mirror;
    double _rot;
    int _xf;
    int _yf;

public:
    const(Cutbit)   cutbit;
    const(Topology) env;

    this(const(Cutbit) cb, const(Topology) to, Point newLoc = Point(0, 0))
    {
        cutbit = cb;
        env    = to;
        _loc   = env ? env.wrap(newLoc) : newLoc;
        _rot   = 0.0;
    }

    Graphic clone() const { return new Graphic(this); }
    this(in Graphic rhs)
    {
        assert (rhs);
        cutbit  = rhs.cutbit;
        env     = rhs.env;
        _loc    = rhs.loc;
        _mirror = rhs._mirror;
        _rot    = rhs._rot;
        _xf     = rhs._xf;
        _yf     = rhs._yf;
    }

    @property const(Albit)  albit()  const { return cutbit.albit; }

    // Phase these out eventually, replace with loc() below
    @property int x() const { return _loc.x; }
    @property int y() const { return _loc.y; }

    @property bool        mirror  () const { return _mirror; }
    @property double      rotation() const { return _rot;    }
    @property bool        mirror  (bool b)        { return _mirror = b;       }
    @property double      rotation(double dbl)    { return _rot = fmod(dbl,4);}

    // This looks dumb, why not make _xf/_yf public? Lixxie overrides these,
    // because it wants to choose the frame to draw even while const.
    // This is bad design, maybe the Lixxie shouldn't even inherit from this.
    @property int xf() const { return _xf; }
    @property int yf() const { return _yf; }
    @property int xf(in int i) { return _xf = i; }
    @property int yf(in int i) { return _yf = i; }

    @property Point loc() const { return _loc; }
    @property Point loc(in Point newLoc)
    {
        return _loc = env ? env.wrap(newLoc) : newLoc;
    }

    @property int xl() const
    {
        return (_rot == 0 || _rot == 2) ? cutbit.xl : cutbit.yl;
    }

    @property int yl() const
    {
        return (_rot == 0 || _rot == 2) ? cutbit.yl : cutbit.xl;
    }

    @property int xfs() const { return cutbit ? cutbit.xfs : 0; }
    @property int yfs() const { return cutbit ? cutbit.yfs : 0; }

    bool isLastFrame() const
    {
        return ! cutbit.frameExists(_xf + 1, _yf);
    }

    bool frameExists(in int which_xf, in int which_yf) const
    {
        return cutbit.frameExists(which_xf, which_yf);
    }

    void draw() const
    {
        assert (env, "can't draw, no target environment specified");
        // This calls the virtual xf(), yf() instead of using _xf, _yf.
        // We want to allow Lixxie to override that with frame and ac.
        cutbit.draw(_loc, xf, yf, _mirror, _rot);
    }

    // Ignore (Topology env) and mirr/rotat; and blit immediately.
    // Only used for mouse cursor and replay sign.
    void drawToCurrentAlbitNotTorbit() const
    {
        cutbit.drawToCurrentAlbitNotTorbit(_loc, _xf, _yf);
    }
}
