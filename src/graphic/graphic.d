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

/*  this(const Cutbit, const Topology, int = 0, int = 0);
 *  this(Graphic)
 */
    Graphic clone() const { return new Graphic(this); }

    const(Cutbit) cutbit;
    const(Topology) env;

    @property const(Albit)  albit()  const { return cutbit.albit; }

    @property int x() const { return _x; }
    @property int y() const { return _y; }
//  @property int x(in int/float);
//  @property int y(in int/float);
    void set_xy(Tx, Ty)(Tx nx, Ty ny) { x = nx; y = ny; }

    @property bool        mirror  () const { return _mirror; }
    @property double      rotation() const { return _rot;    }
    @property Cutbit.Mode mode    () const { return _mode;   }
    @property bool        mirror  (bool b)        { return _mirror = b;       }
    @property double      rotation(double dbl)    { return _rot = fmod(dbl,4);}
    @property Cutbit.Mode mode    (Cutbit.Mode m) { return _mode = m;         }

    @property int xf() const { return _xf; }
    @property int yf() const { return _yf; }
    @property int xf(in int new_x_frame) { return _xf = new_x_frame; }
    @property int yf(in int new_y_frame) { return _yf = new_y_frame; }

/* Wrapper functions, these return things from the Cutbit class
 * If the Graphic object is rotated, get_xl()/yl() are NOT wrappers,
 * but rotate with the Graphic object before they access the Cutbit part.
 * Same thing with get_pixel().
 *
 *  @property int xl() const
 *  @property int yl() const
 */
    @property int xfs() const { return cutbit ? cutbit.xfs : 0; }
    @property int yfs() const { return cutbit ? cutbit.yfs : 0; }

/*  bool  frameExists(int, int) const
 *  AlCol get_pixel   (int, int) const -- remember to lock target!
 *
 *  bool isLastFrame() const
 *  void draw(Torbit) const
 *  void drawToCurrentTarget() const
 *      Ignore (Topology env) and mirr/rotat; and blit immediately.
 *      Only used for mouse cursor and replay sign.
 */

private:

    int _x;
    int _y;
    bool         _mirror;
    double       _rot;
    Cutbit.Mode  _mode;

    int _xf;
    int _yf;



public:

this(
    const(Cutbit) cb,
    const(Topology) to,
    in int new_x = 0,
    in int new_y = 0
) {
    cutbit = cb;
    env    = to;
    _x     = new_x;
    _y     = new_y;
    _rot   = 0.0;
    _mode  = Cutbit.Mode.NORMAL;
}



this(in Graphic rhs)
{
    assert (rhs);
    cutbit  = rhs.cutbit;
    env     = rhs.env;
    _x      = rhs._x;
    _y      = rhs._y;
    _mirror = rhs._mirror;
    _rot    = rhs._rot;
    _mode   = rhs._mode;
    _xf     = rhs._xf;
    _yf     = rhs._yf;
}



@property int
x(in int i)
{
    _x = i;
    if (env && env.torusX)
        _x = positiveMod(_x, env.xl);
    return _x;
}

@property int
y(in int i)
{
    _y = i;
    if (env && env.torusY)
        _y = positiveMod(_y, env.yl);
    return _y;
}

@property int x(in float fl) { return x = fl.roundInt; }
@property int y(in float fl) { return y = fl.roundInt; }



@property int
xl() const
{
    return (_rot == 0 || _rot == 2) ? cutbit.xl : cutbit.yl;
}
@property int
yl() const
{
    return (_rot == 0 || _rot == 2) ? cutbit.yl : cutbit.xl;
}



bool isLastFrame() const
{
    return ! cutbit.frameExists(_xf + 1, _yf);
}



bool frameExists(in int which_xf, in int which_yf) const
{
    return cutbit.frameExists(which_xf, which_yf);
}



AlCol // deprecated("lock target or cache pixels!")
get_pixel(in int gx, in int gy) const
{
    immutable int _xl = cutbit.xl;
    immutable int _yl = cutbit.yl;
    int useX = gx;
    int useY = gy;

    // If the rotation is a multiple of a quarter turn, rotate the values
    // with the Graphic object. If the rotation is a fraction, return
    // the value from the original bitmap (treated as unrotated).
    // Lix terrain can only be rotated in quarter turns.
    int rotationInteger = to!int(_rot);
    if (rotationInteger - _rot != 0) rotationInteger = 0;

    // DTODO: check if this works still correctly, after we have
    // rewritten this class using D properties instead of getters/setters
    switch (rotationInteger) {
        case 0: useX = gx;       useY = !_mirror ? gy       : _yl-gy-1;break;
        case 1: useX = gy;       useY = !_mirror ? _yl-gx-1 : gx;      break;
        case 2: useX = _xl-gx-1; useY = !_mirror ? _yl-gy-1 : gy;      break;
        case 3: useX = _xl-gy-1; useY = !_mirror ? gx       : _yl-gx-1;break;
        default: break;
    }
    return cutbit.get_pixel(_xf, _yf, useX, useY);
}

void draw(Torbit mutableGround) const
{
    assert (env, "can't draw, no target environment specified");
    assert (env == mutableGround, format("drawing target must be == env."
        " env=%x, mutable=%x", &env, &mutableGround));

    if (mode == Cutbit.Mode.NORMAL)
        // This calls the virtual xf(), yf() instead of using _xf, _yf.
        // We want to allow Lixxie to override that with frame and ac.
        cutbit.draw(mutableGround, _x, _y, xf, yf, _mirror, _rot);
    else
        cutbit.draw(mutableGround, _x, _y, _mirror, to!int(_rot), _mode);
}

void drawToCurrentTarget() const
{
    cutbit.drawToCurrentTarget(_x, _y, _xf, _yf);
}

}
// end class
