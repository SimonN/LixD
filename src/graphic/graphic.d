module graphic.graphic;

/* A simple graphic object, i.e., an instance of Cutbit that is drawn to
 * a certain position on a torbit. This is not about graphic sets from L1,
 * ONML etc., see level/gra_set.h for that.
 */

import std.conv; // rounding/chopping double to int
import std.math;

import basics.alleg5;
import basics.help; // rounding float to a good int
import graphic.cutbit;
import graphic.torbit;

class Graphic {

/*  this(const Cutbit, Torbit, const int = 0, const int = 0);
 *  this(Graphic)
 */
    @property const(Cutbit) cutbit() const { return _cutbit; }

    @property AlBit  albit()               { return _cutbit.albit; }
    @property Torbit ground(Torbit gr)     { return _ground = gr;  }
    @property inout(Torbit) ground() inout { return _ground;       }

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
    @property int xfs() const { return cutbit.xfs; }
    @property int yfs() const { return cutbit.yfs; }

/*  bool  frame_exists(int, int) const
 *  AlCol get_pixel   (int, int) const -- remember to lock target!
 *
 *  bool is_last_frame() const
 *
 *  void draw()
 *
 *      Draw to the torbit, according to mirror and rotation.
 *      Can't be a const method because of mutable this.torbit.
 *
 *  void draw_directly_to_screen() const
 *
 *      Ignore (Torbit ground) and mirr/rotat; and blit immediately to the
 *      screen. This should only be used to draw the mouse cursor.
 */

private:

    const(Cutbit) _cutbit;
    Torbit        _ground;

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
    Torbit        gr,
    const int     new_x = 0,
    const int     new_y = 0
) {
    _cutbit = cb;
    _ground = gr;

    _x      = new_x;
    _y      = new_y;
    _mirror = false;
    _rot    = 0;
    _mode   = Cutbit.Mode.NORMAL;

    _xf = 0;
    _yf = 0;
}



this(Graphic rhs)
{
    assert (rhs);
    _cutbit = rhs._cutbit;
    _ground = rhs._ground;
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
    if (ground && ground.torus_x)
        _x = positive_mod(_x, ground.xl);
    return _x;
}

@property int
y(in int i)
{
    _y = i;
    if (ground && ground.torus_y)
        _y = positive_mod(_y, ground.yl);
    return _y;
}

@property int x(in float fl) { return x = fl.round_int; }
@property int y(in float fl) { return y = fl.round_int; }



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



bool is_last_frame() const
{
    return ! cutbit.frame_exists(_xf + 1, _yf);
}



bool frame_exists(in int which_xf, in int which_yf) const
{
    return cutbit.frame_exists(which_xf, which_yf);
}



AlCol // deprecated("lock target or cache pixels!")
get_pixel(in int gx, in int gy) const
{
    immutable int _xl = cutbit.xl;
    immutable int _yl = cutbit.yl;
    int use_x = gx;
    int use_y = gy;

    // If the rotation is a multiple of a quarter turn, rotate the values
    // with the Graphic object. If the rotation is a fraction, return
    // the value from the original bitmap (treated as unrotated).
    // Lix terrain can only be rotated in quarter turns.
    int rotation_integer = to!int(_rot);
    if (rotation_integer - _rot != 0) rotation_integer = 0;

    // DTODO: check if this works still correctly, after we have
    // rewritten this class using D properties instead of getters/setters
    switch (rotation_integer) {
        case 0: use_x = gx;       use_y = !_mirror ? gy       : _yl-gy-1;break;
        case 1: use_x = gy;       use_y = !_mirror ? _yl-gx-1 : gx;      break;
        case 2: use_x = _xl-gx-1; use_y = !_mirror ? _yl-gy-1 : gy;      break;
        case 3: use_x = _xl-gy-1; use_y = !_mirror ? gx       : _yl-gx-1;break;
        default: break;
    }
    return cutbit.get_pixel(_xf, _yf, use_x, use_y);
}



void draw()
{
    if (mode == Cutbit.Mode.NORMAL) {
        cutbit.draw(_ground, _x, _y, _xf, _yf, _mirror, _rot);
    }
    else {
        cutbit.draw(_ground, _x, _y, _mirror, to!int(_rot), _mode);
    }
}



void
draw_directly_to_screen() const
{
    cutbit.draw_directly_to_screen(_x, _y, _xf, _yf);
}

}
// end class
