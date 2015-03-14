module graphic.torbit;

import std.math; // fmod, abs
import std.algorithm; // minPos

import basics.alleg5;
import basics.help; // positive_mod
import hardware.display;

class Torbit {

    this(in int _xl, in int _yl, in bool _tx = false, in bool _ty = false);
    this(const Torbit rhs);

    AlBit get_albit()        { return bitmap; }
    AlBit get_al_bitmap()    { return bitmap; }

    int  get_xl()      const { return xl; }
    int  get_yl()      const { return yl; }
    bool get_torus_x() const { return tx; }
    bool get_torus_y() const { return ty; }

    void resize(int, int);

    void set_torus_x (bool b = true)  { tx = b; }
    void set_torus_y (bool b = true)  { ty = b; }
    void set_torus_xy(bool x, bool y) { tx = x; ty = y; }

    // Computing distances, like (1st_arg - 2nd_arg), but these check for
    // shortcuts around the cylinder/torus if appropriate. Using hypotsquare
    // is more efficient because the square root doesn't have to be computed.
    int    distance_x (in int x1, in int y2)                       const;
    int    distance_y (in int y1, in int y2)                       const;
    double hypot      (in int x1, in int y1, in int x2, in int y2) const;
    double hypotsquare(in int x1, in int y1, in int x2, in int y2) const;
    //                            px   py   Rx   Ry   Rxl  Ryl
    bool   get_point_in_rectangle(int, int, int, int, int, int) const;

    void draw     (Torbit, int x = 0, int y = 0) const
        { assert(false, "Torbit.draw to Torbit not implemented"); }
    void draw     (AlBit,  int x = 0, int y = 0, int rxl=0, int ryl=0) const
        { assert(false, "Torbit.draw to AlBit not implemented"); }

    void draw_from(AlBit,  int x = 0, int y = 0,
                   bool mirr = false, double rot = 0, double scal = 0);

    void copy_to_screen();

    void  clear_to_color(AlCol);
    void  set_pixel     (int, int, AlCol);
    AlCol get_pixel     (int, int) const;

    // rectangles are given by Rx,  Ry,  Rxl, Ryl
    void draw_rectangle       (int, int, int, int, AlCol);
    void draw_filled_rectangle(int, int, int, int, AlCol);

    // These methods are very slow, try not to use them each tick.
    // You should lock (Torbit.get_albit()) before calling these functions,
    // they do not lock the bitmap themselves.
    void replace_color        (AlCol, AlCol);
    void replace_color_in_rect(int, int, int, int, AlCol, AlCol);

private:

    AlBit bitmap;

    // height and width of bitmap ("x-length" and "y-length")
    int  xl;
    int  yl;

    // torus property in either direction, making edges of the bitmap loop
    bool tx;
    bool ty;

    void use_drawing_delegate(void delegate(int, int), int x, int y);



public:

this(
    in int _xl,
    in int _yl,
    in bool _tx = false,
    in bool _ty = false
) {
    xl = _xl;
    yl = _yl;
    tx = _tx;
    ty = _ty;
    bitmap = albit_create(xl, yl);
    assert (bitmap);
}



this(const Torbit rhs)
{
    assert (rhs.bitmap);
    bitmap = al_clone_bitmap(cast (AlBit) rhs.bitmap);
    if (bitmap) {
        xl = rhs.xl;
        yl = rhs.yl;
        tx = rhs.tx;
        ty = rhs.ty;
    }
}



~this()
{
    if (bitmap) {
        al_destroy_bitmap(bitmap);
        bitmap = null;
    }
}



invariant()
{
    if (bitmap) {
        assert (xl == al_get_bitmap_width (cast (AlBit) bitmap));
        assert (yl == al_get_bitmap_height(cast (AlBit) bitmap));
    }
}



void resize(int _xl, int _yl)
{
    if (bitmap) al_destroy_bitmap(bitmap);
    xl = _xl;
    yl = _yl;
    bitmap = albit_create(xl, yl);
    assert (bitmap);
}



int distance_x(in int x1, in int x2) const
{
    if (! tx) return x2 - x1;
    else {
        int[] possible = [x2-x1, x2-x1-xl, x2-x1+xl];
        return std.algorithm.minPos!"abs(a) < abs(b)"(possible)[0];
    }
}



int distance_y(in int y1, in int y2) const
{
    if (! ty) return y2 - y1;
    else {
        int[] possible = [y2-y1, y2-y1-yl, y2-y1+yl];
        return std.algorithm.minPos!"abs(a) < abs(b)"(possible)[0];
    }
}



double hypot(in int x1, in int y1, in int x2, in int y2) const
{
    return std.math.sqrt(this.hypotsquare(x1, y1, x2, y2));
}



double hypotsquare(in int x1, in int y1, in int x2, in int y2) const
{
    immutable int dx = distance_x(x2, x1);
    immutable int dy = distance_y(y2, y1);
    return (dx * dx + dy * dy);
}



bool get_point_in_rectangle(
    int px, int py, int rx, int ry, int rxl, int ryl) const
{
    if (tx) {
        px = positive_mod(px, xl);
        rx = positive_mod(rx, xl);
        // the following (if) omits the need for a 4-subrectangle-check
        if (px < rx) px += xl;
    }
    if (ty) {
        py = positive_mod(py, yl);
        ry = positive_mod(ry, yl);
        if (py < ry) py += yl;
    }
    return (px >= rx && px < rx + rxl)
        && (py >= ry && py < ry + ryl);
}



private void use_drawing_delegate(
    void delegate(int, int) drawing_delegate,
    int x,
    int y
) {
    assert (bitmap);
    assert (drawing_delegate != null);

    mixin(temp_target!"bitmap");
    if (true    ) drawing_delegate(x,      y     );
    if (tx      ) drawing_delegate(x - xl, y     );
    if (      ty) drawing_delegate(x,      y - yl);
    if (tx && ty) drawing_delegate(x - xl, y - yl);
}



void draw_from(
    AlBit bit,
    int x = 0,
    int y = 0,
    bool mirr = false,
    double rot = 0,
    double scal = 0
) {
    assert (bit);

    // DTODO: test whether these mods can be shifted into use_delegate.
    if (tx) x = positive_mod(x, xl);
    if (ty) y = positive_mod(y, yl);
    rot = std.math.fmod(rot, 4);

    void delegate(int, int) draw_from_at;
    assert(draw_from_at == null);

    // Select the appropriate Allegro function and its arguments.
    // This function will be called up to 4 times for drawing (AlBit bit) onto
    // (Torbit this). Only the positions vary based on the torus properties.

    if (rot == 0 && ! scal) {
        draw_from_at =
         delegate void(int x_at, int y_at)
        {
            al_draw_bitmap(bit, x_at, y_at, ALLEGRO_FLIP_VERTICAL * mirr);
        };
    }
    else if (rot == 2 && ! scal) {
        draw_from_at =
         delegate void(int x_at, int y_at)
        {
            al_draw_bitmap(bit, x_at, y_at,
             (ALLEGRO_FLIP_VERTICAL * !mirr) | ALLEGRO_FLIP_HORIZONTAL);
        };
    }
    else {
        // We don't expect non-square things to be rotated by non-integer
        // amounts of quarter turns. Squares will have xdr = ydr = 0 in this
        // scope, see the variable definitions below.
        // The non-square terrain will only be rotated in steps of quarter
        // turns, and its top-left corner after rotation shall remain at
        // the specified level coordinates, no matter how it's rotated.
        // Terrain rotated by 0 or 2 quarter turns has already been managed
        // by the (if)s above. Now, we'll be doing a noncontinuous jump at
        // exactly 1 and 3 quarter turns, which will manage the terrain well,
        // and doesn't affect continuous rotations of squares anyway.
        immutable bool b = (rot == 1 || rot == 3);

        // x/y-length of the source bitmap
        immutable int xsl = al_get_bitmap_width (bit);
        immutable int ysl = al_get_bitmap_height(bit);

        // We don't want to rotate around the center point of the source
        // bitmap. That would only be the case if the source is a square.
        // We wish to have the top-left corner of the rotated shape at x/y
        // whenever we perform a multiple of a quarter turn.
        // DTODO: Test this on Linux and Windows, whether it generates the same
        // terrain.
        float xdr = b ? ysl/2.0 : xsl/2.0;
        float ydr = b ? xsl/2.0 : ysl/2.0;

        if (! scal) draw_from_at =
         delegate void(int x_at, int y_at)
        {
            al_draw_rotated_bitmap(bit, xsl/2.0, ysl/2.0,
                xdr + x_at, ydr + y_at,
                rot * ALLEGRO_PI / 2,
                mirr ? ALLEGRO_FLIP_VERTICAL : 0
            );
        };
        else draw_from_at =
         delegate void(int x_at, int y_at)
        {
            al_draw_scaled_rotated_bitmap(bit, xsl/2.0, ysl/2.0,
                xdr + x_at, ydr + y_at,
                scal, scal,
                rot * ALLEGRO_PI / 2,
                mirr ? ALLEGRO_FLIP_VERTICAL : 0
            );
        };
        // end delegate
    }

    use_drawing_delegate(draw_from_at, x, y);
}



void copy_to_screen()
{
    AlBit last_target = al_get_target_bitmap();
    scope (exit) al_set_target_bitmap(last_target);
    al_set_target_backbuffer(display);

    al_draw_bitmap(bitmap, 0, 0, 0);
}



void clear_to_color(AlCol col)
{
    mixin(temp_target!"bitmap");
    al_clear_to_color(col);
}



AlCol get_pixel(int x, int y) const
{
    assert(bitmap);
    // when checking for pixels behind the border, we're repeating the last
    // pixel inside the bitmap at the border. If it's a torus, of course we
    // don't do this and loop normally.

    // From the Allegro docs: this is slow on video bitmaps, consider locking
    // manually in the class calling this method.
    return al_get_pixel(cast (AlBit) bitmap,
     tx      ? positive_mod(x, xl) :
     x < 0   ? 0                   :
     x >= xl ? xl - 1              : x,
     ty      ? positive_mod(y, yl) :
     y < 0   ? 0                   :
     y >= yl ? yl - 1              : y);
}



void set_pixel(int x, int y, AlCol col)
{
    assert(bitmap);
    // Here, don't draw outside of the boundaries, unlike the reading in
    // Torbit.get_pixel. Again, it's slow on video bitmaps.
    mixin(temp_target!"bitmap");
    if ((tx || (x >= 0 && x < xl))
     && (ty || (y >= 0 && y < yl)) ) al_put_pixel(
     tx ? positive_mod(x, xl) : x,
     ty ? positive_mod(y, yl) : y, col);
}



void draw_rectangle(int x, int y, int rxl, int ryl, AlCol col)
{
    // DTODO: test whether the mod can be moved into the delegate invoker.
    if (tx) x = positive_mod(x, xl);
    if (ty) y = positive_mod(y, yl);
    use_drawing_delegate(delegate void(int x_at, int y_at) {
        al_draw_rectangle(x_at + 0.5, y_at + 0.5,
         x_at + rxl - 0.5, y_at + ryl - 0.5, col, 1);
    }, x, y);
}



void draw_filled_rectangle(int x, int y, int rxl, int ryl, AlCol col)
{
    // DTODO: test whether the mod can be moved into the delegate invoker.
    if (tx) x = positive_mod(x, xl);
    if (ty) y = positive_mod(y, yl);

    auto deg = delegate void(int x_at, int y_at)
    {
        al_draw_filled_rectangle(x_at + 0.5, y_at + 0.5,
         x_at + rxl - 0.5, y_at + ryl - 0.5, col);
    };
    use_drawing_delegate(deg, x, y);
}



void replace_color(AlCol c_old, AlCol c_new)
{
    replace_color_in_rect(0, 0, xl, yl, c_old, c_new);
}



void replace_color_in_rect(
    int rx, int ry, int rxl, int ryl, AlCol c_old, AlCol c_new
) {
    if (! bitmap) return;
    if (tx) rx = positive_mod(rx, xl);
    if (ty) ry = positive_mod(ry, yl);

    auto deg = delegate void(int at_x, int at_y)
    {
        // don't draw outside the boundaries
        immutable int start_x = max(at_x, 0);
        immutable int start_y = max(at_y, 0);
        immutable int end_x = min(at_x + rxl, xl);
        immutable int end_y = min(at_y + ryl, yl);

        // these functions are slow, so replace_color_in_rect should lock
        // the bitmap before passing this delegate DTODO, no locking yet
        foreach (x; start_x .. end_x)
         foreach (y; start_y .. end_y)
         if (al_get_pixel(bitmap, x, y) == c_old) al_put_pixel(x, y, c_new);
    };

    //mixin(temp_lock!"bitmap");
    use_drawing_delegate(deg, rx, ry);
}

}
// end class
