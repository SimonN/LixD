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

final class Graphic {
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

    const(Albit) albit() const pure nothrow @nogc { return cutbit.albit; }

    // This should go in the following "pure nothrow @nogc {",
    // but fmod is not yet pure in the D standard library.
    // https://issues.dlang.org/show_bug.cgi?id=11320
    double rotation(double dbl) nothrow @nogc { return _rot = fmod(dbl, 4); }

    pure nothrow @safe @nogc {
        bool mirror () const { return _mirror; }
        double rotation() const { return _rot; }
        bool mirror (bool b) { return _mirror = b; }

        // Looks dumb, why not make _xf/_yf public? Lixxie overrides these,
        // because it wants to choose the frame to draw even while const.
        // This is bad design, maybe the Lixxie shouldn't even inherit from us.
        int xf() const { return _xf; }
        int yf() const { return _yf; }
        int xf(in int i) { return _xf = i; }
        int yf(in int i) { return _yf = i; }

        Rect rect() const { return Rect(_loc, xl, yl); }
        Point loc() const { return _loc; }
        Point loc(in Point newLoc)
        {
            return _loc = env ? env.wrap(newLoc) : newLoc;
        }

        int xl() const
        {
            return (_rot == 0 || _rot == 2) ? cutbit.xl : cutbit.yl;
        }

        int yl() const
        {
            return (_rot == 0 || _rot == 2) ? cutbit.yl : cutbit.xl;
        }

        int xfs() const { return cutbit ? cutbit.xfs : 1; }
        int yfs() const { return cutbit ? cutbit.yfs : 1; }
    }

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
        cutbit.draw(_loc, _xf, _yf, _mirror, _rot);
    }

    /*
     * Hack: This breaks the abstraction that Graphic knows about its selected
     * frame (xf, yf). I need this break for gadgets that want to pick a frame
     * and draw it once, all while the Gadget and the Graphic remain const.
     */
    void drawSpecificFrame(in Point xfyf) const
    {
        assert (env, "can't draw, no target environment specified");
        cutbit.draw(_loc, xfyf.x, xfyf.y, _mirror, _rot);
    }

    // Ignore (Topology env) and mirr/rotat; and blit immediately.
    // Only used for mouse cursor and replay sign.
    void drawToCurrentAlbitNotTorbit() const
    {
        cutbit.drawToCurrentAlbitNotTorbit(_loc, _xf, _yf);
    }
}
