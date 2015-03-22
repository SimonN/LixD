module graphic.graphic;

import std.conv; // rounding double to int
import std.math;

import basics.alleg5;
import basics.help;
import graphic.cutbit;
import graphic.torbit;

/* A simple graphic object, i.e., an instance of Cutbit that is drawn to
 * a certain position on a torbit. This is not about graphic sets from L1,
 * ONML etc., see level/gra_set.h for that.
 */

class Graphic {

    this(const Cutbit, Torbit, const int = 0, const int = 0);
    ~this() { }
    // invariant() -- exists, see below

    const(Cutbit) get_cutbit() const          { return cutbit; }

    AlBit  get_albit()     { return cutbit.get_albit(); }
    AlBit  get_al_bitmap() { return cutbit.get_albit(); }
    Torbit get_ground()    { return ground;             }
    void   set_ground(Torbit gr)  { ground = gr;        }

    int  get_x () const { return x; }
    int  get_y () const { return y; }
    void set_x (const int);
    void set_y (const int);
    void set_xy(int nx, int ny) { set_x(nx); set_y(ny); }

    bool        get_mirror  () const { return mirror;   }
    double      get_rotation() const { return rotation; }
    Cutbit.Mode get_mode    () const { return mode;     }
    void set_mode(Cutbit.Mode m)     { mode   = m;      }
    void set_mirror(bool b = true)   { mirror = b;      }
    void set_rotation(double);

    int  get_x_frame() const { return x_frame; }
    int  get_y_frame() const { return y_frame; }
    void set_x_frame(int new_x_frame) { x_frame = new_x_frame; }
    void set_y_frame(int new_y_frame) { y_frame = new_y_frame; }

    // Wrapper functions, these return things from the Cutbit class
    // If the Graphic object is rotated, get_xl()/yl() are NOT wrappers,
    // but rotate with the Graphic object before they access the Cutbit part.
    // Same thing with get_pixel().
    int  get_xl() const;
    int  get_yl() const;
    int  get_x_frames()  const { return cutbit.get_x_frames(); }
    int  get_y_frames()  const { return cutbit.get_y_frames(); }
    bool get_frame_exists(in int, in int) const;
    AlCol get_pixel      (in int, in int) const; // warning: very slow!

    // bool is_last_frame() const; -- exists, see below

    // void draw(); -- exists, see below

private:

    const(Cutbit) cutbit;
    Torbit        ground;

    int x;
    int y;
    bool         mirror;
    double       rotation;
    Cutbit.Mode  mode;

    int x_frame;
    int y_frame;



public:

this(
    const(Cutbit) cb,
    Torbit        gr,
    const int     new_x,
    const int     new_y
) {
    cutbit  = cb;
    ground  = gr;

    x       = new_x;
    y       = new_y;
    mirror  = false;
    rotation= 0;
    mode    = Cutbit.Mode.NORMAL;

    x_frame = 0;
    y_frame = 0;
}



invariant()
{
    assert(cutbit, "graphic object's Cutbit doesn't exist");
    assert(ground, "graphic object's ground Torbit doesn't exist");
    assert(ground.get_xl() > 0);
    assert(ground.get_yl() > 0);
}



void set_x(const int i)
{
    x = i;
    if (ground.get_torus_x()) x = positive_mod(x, ground.get_xl());
}
void set_y(const int i)
{
    y = i;
    if (ground.get_torus_y()) y = positive_mod(y, ground.get_yl());
}



void set_rotation(double dbl)
{
    rotation = std.math.fmod(dbl, 4);
}



int get_xl() const
{
    return (rotation == 0 || rotation == 2)
     ? cutbit.get_xl() : cutbit.get_yl();
}
int get_yl() const
{
    return (rotation == 0 || rotation == 2)
     ? cutbit.get_yl() : cutbit.get_xl();
}



bool is_last_frame() const
{
    return ! cutbit.get_frame_exists(x_frame + 1, y_frame);
}



bool get_frame_exists(in int xf, in int yf) const
{
    return cutbit.get_frame_exists(xf, yf);
}



AlCol get_pixel(in int gx, in int gy) const
{
    immutable int xl = cutbit.get_xl();
    immutable int yl = cutbit.get_yl();
    int use_x = gx;
    int use_y = gy;

    // If the rotation is a multiple of a quarter turn, rotate the values
    // with the Graphic object. If the rotation is a fraction, return
    // the value from the original bitmap (treated as unrotated).
    // Lix terrain can only be rotated in quarter turns.
    int rotation_integer = to!int(rotation);
    if (rotation_integer - rotation != 0) rotation_integer = 0;

    switch (rotation_integer) {
        case 0: use_x = gx;      use_y = !mirror ? gy      : yl-gy-1; break;
        case 1: use_x = gy;      use_y = !mirror ? yl-gx-1 : gx;      break;
        case 2: use_x = xl-gx-1; use_y = !mirror ? yl-gy-1 : gy;      break;
        case 3: use_x = xl-gy-1; use_y = !mirror ? gx      : yl-gx-1; break;
        default: break;
    }
    // DTODOVRAM
    return cutbit.get_pixel(x_frame, y_frame, use_x, use_y);
}



void draw()
{
    cutbit.draw(ground, x, y, x_frame, y_frame, mirror, rotation, 0, mode);
}

}
// end class
