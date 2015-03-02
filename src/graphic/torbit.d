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
        // everything will be much simpler for these values of r, we don't
        // have to fix rounding mistakes then
        bool b = (rot == 0 || rot == 2);

        // x/y-length of the source bitmap
        immutable int xsl = al_get_bitmap_width (bit);
        immutable int ysl = al_get_bitmap_height(bit);
        int xdr = xsl/2;
        int ydr = ysl/2;

        // fixed sind die Allegro-Typen, die die Sprite-Funktionen wollen
        draw_from_at =
         delegate void(int x_at, int y_at)
        {
            al_draw_scaled_rotated_bitmap(bit,
                xdr,
                ydr,
                x_at + xdr,
                y_at + ydr,
                scal ? scal : 1,
                scal ? scal : 1,
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

/*

        // rotate_sprite dreht leider um das Zentrum und hat obendrein
        // wuselige Angewohnheiten, wann bei ungeraden Laengen nach vorn
        // oder hinten gerundet wird. Mein Algorithmus faengt das auf.

        // Wir koennen Truemmer trotzdem mit dieser Methode zeichnen!
        // Fuer xl == yl liefert dies gerade wieder das Urspruengliche!

        //  draw position   move the center     correct rounding mistakes
        int xdr = b ? 0  :  0 - xsl/2 + ysl/2 - ((xsl + ysl)%2 && xsl < ysl);
        int ydr = b ? 0  :  0 - ysl/2 + xsl/2 - ((xsl + ysl)%2 && ysl < xsl);

        // fixing additional, very stupid rounding mistakes from Allegro 4,
        // these brought desyncs between the Linux and Windows versions
        if (!b && xsl%2 == 1 && ysl%2 == 0 && ysl < xsl) {
            --xdr;
            ++ydr;
        }
        else if (!b && xsl%2 == 0 && ysl%2 == 1 && xsl < ysl) {
            ++xdr;
            --ydr;
        }
*/



void copy_to_screen()
{
    AlBit last_target = al_get_target_bitmap();
    scope (exit) al_set_target_bitmap(last_target);

    al_set_target_backbuffer(alleg5.display);

    al_draw_bitmap(bitmap, 0, 0, 0);
}



}
// end class
