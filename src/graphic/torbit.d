import std.math; // fmod
import std.conv; // convert double to int

import alleg5;
import help; // positive_mod

class Torbit {

private:

    AlBit bitmap;

    int  xl;
    int  yl;
    bool tx;
    bool ty;

public:

    this(int xl, int yl, bool tx = false, bool ty = false);
    this(const Torbit rhs);

    AlBit get_albit()        { return bitmap; }
    AlBit get_al_bitmap()    { return bitmap; }

    int  get_xl()      const { return xl; }
    int  get_yl()      const { return yl; }
    bool get_torus_x() const { return tx; }
    bool get_torus_y() const { return ty; }

    void set_torus_x (bool b = true)  { tx = b; }
    void set_torus_y (bool b = true)  { ty = b; }
    void set_torus_xy(bool x, bool y) { tx = x; ty = y; }

    // drawing functions
    void draw_from(AlBit, int x = 0, int y = 0,
                   bool mirr = false, double rot = 0, double scal = 0);

    void copy_to_screen();



public:

this(
    int _xl,
    int _yl,
    bool _tx = false,
    bool _ty = false
) {
    xl = _xl;
    yl = _yl;
    tx = _tx;
    ty = _ty;
    bitmap = albit_create(xl, yl);
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



private void use_drawing_delegate(
    void delegate(int, int) drawing_delegate,
    int x,
    int y
) {
    assert (bitmap);
    assert (xl == al_get_bitmap_width (cast (AlBit) bitmap));
    assert (yl == al_get_bitmap_height(cast (AlBit) bitmap));
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
            immutable int xsl = al_get_bitmap_width (bit);
            immutable int ysl = al_get_bitmap_height(bit);
            al_draw_rectangle(x_at + 0.5, y_at + 0.5, x_at + xsl - 0.5, y_at + ysl - 0.5, AlCol(0.6, 0.6, 0, 1), 3);
            al_draw_rectangle(x_at + 0.5, y_at + 0.5, x_at + xsl - 0.5, y_at + ysl - 0.5, AlCol(0, 0.5, 1, 1), 1);
            al_draw_bitmap(bit, x_at, y_at, ALLEGRO_FLIP_VERTICAL * mirr);
            al_draw_pixel(x_at, y_at, AlCol(1,1,1,1));
        };
    }
    else if (rot == 2 && ! scal) {
        draw_from_at =
         delegate void(int x_at, int y_at)
        {
            immutable int xsl = al_get_bitmap_width (bit);
            immutable int ysl = al_get_bitmap_height(bit);
            al_draw_rectangle(x_at + 0.5, y_at + 0.5, x_at + xsl - 0.5, y_at + ysl - 0.5, AlCol(0.6, 0.6, 0, 1), 3);
            al_draw_rectangle(x_at + 0.5, y_at + 0.5, x_at + xsl - 0.5, y_at + ysl - 0.5, AlCol(0, 0.5, 1, 1), 1);
            al_draw_bitmap(bit, x_at, y_at,
             (ALLEGRO_FLIP_VERTICAL * !mirr) | ALLEGRO_FLIP_HORIZONTAL);
            al_draw_pixel(x_at, y_at, AlCol(1,1,1,1));
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
        // TODO: Test this on Linux and Windows, whether it generates the same
        // terrain.
        float xdr = b ? ysl/2.0 : xsl/2.0;
        float ydr = b ? xsl/2.0 : ysl/2.0;

        if (! scal) draw_from_at =
         delegate void(int x_at, int y_at)
        {
            al_draw_rectangle(x_at + 0.5, y_at + 0.5, x_at + xsl - 0.5, y_at + ysl - 0.5, AlCol(0.6, 0.6, 0, 1), 3);
            al_draw_rectangle(x_at + 0.5, y_at + 0.5, x_at + xsl - 0.5, y_at + ysl - 0.5, AlCol(0, 0.5, 1, 1), 1);
            al_draw_rotated_bitmap(bit,
                xsl/2.0,
                ysl/2.0,
                xdr + x_at,
                ydr + y_at,
                rot * ALLEGRO_PI / 2,
                mirr ? ALLEGRO_FLIP_VERTICAL : 0
            );
            al_draw_pixel(x_at, y_at, AlCol(1,1,1,1));
        };
        else draw_from_at =
         delegate void(int x_at, int y_at)
        {
            al_draw_scaled_rotated_bitmap(bit,
                xsl/2.0,
                ysl/2.0,
                xdr + x_at,
                ydr + y_at,
                scal,
                scal,
                rot * ALLEGRO_PI / 2,
                mirr ? ALLEGRO_FLIP_VERTICAL : 0
            );
        };
        // end delegate
    }

    // Perform the drawing now
    assert (draw_from_at != null);
    mixin(alleg5.temp_target!"bitmap");
    if (true    ) draw_from_at(x,      y     );
    if (tx      ) draw_from_at(x - xl, y     );
    if (      ty) draw_from_at(x,      y - yl);
    if (tx && ty) draw_from_at(x - xl, y - yl);
}



void copy_to_screen()
{
    AlBit last_target = al_get_target_bitmap();
    scope (exit) al_set_target_bitmap(last_target);
    al_set_target_backbuffer(alleg5.display);

    al_draw_bitmap(bitmap, 0, 0, 0);
}



}
// end class
