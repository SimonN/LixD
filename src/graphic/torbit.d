module graphic.torbit;

import std.math; // fmod, abs
import std.algorithm; // minPos

import basics.alleg5;
import basics.help; // positiveMod
import graphic.color; // drawing dark, to analyze transparency
import file.filename;
import hardware.display;
import hardware.tharsis;

private immutable bool _tharsisProfilingInTorbit = false;



class Torbit {

//  this(xl, yl, torusX, torusY);
//  this(const Torbit rhs);

    @property Albit albit() { return bitmap; }

    @property int xl() const { return _xl; }
    @property int yl() const { return _yl; }

//  void resize(int, int);

    @property bool torusX(bool b) { return _tx = b; }
    @property bool torusY(bool b) { return _ty = b; }
    @property bool torusX() const { return _tx; }
    @property bool torusY() const { return _ty; }
    void setTorusXY(bool x, bool y) { _tx = x; _ty = y; }

/*  int    distanceX (in int x1, in int y2)                       const;
 *  int    distanceY (in int y1, in int y2)                       const;
 *  double hypot      (in int x1, in int y1, in int x2, in int y2) const;
 *  double hypotSquared(in int x1, in int y1, in int x2, in int y2) const;
 *
 *      Computing distances, like (1st_arg - 2nd_arg), but these check for
 *      shortcuts around the cylinder/torus if appropriate. Using hypotSquared
 *      is more efficient because the square root doesn't have to be computed.
 *
 *                              px   py   Rx   Ry   Rxl  Ryl
 *  bool isPointInRectangle(int, int, int, int, int, int) const;
 */
    // DTODODRAW: import is only here while the next is unimpl
    import file.log;
    void drawTo(Torbit, int x = 0, int y = 0) const
        { log("DTODODRAW: Torbit.drawTo(Torbit) not implemented"); }
    void drawTo(Albit,  int x = 0, int y = 0, int rxl = 0, int ryl = 0) const
        { log("DTODODRAW: Torbit.drawTo(Albit) not implemented"); }

/*  void drawFrom(Albit, x, y, bool mirr, double rot, double scal)
 *
 *      Draw the entire Albit onto (Torbit this). Can take non-integer quarter
 *      turns as (double rot).
 *
 *  void drawDarkFrom(Albit, x, y, bool mirr, int rot, AlCol col)
 *
 *      Implements the eraser piece drawing mode from class Cutbit.
 *      It's cleaner like this: Torbit knows exactly how to lock itself
 *      for maximum speed. Torbit doesn't need to know what a Cutbit is,
 *      only (AlCol col) to draw instead of the normal bitmap color.
 *
 *      This is intended for drawing terrain and steel. Integer turns are
 *      expected, and they must be already positively modded (see function
 *      in basics.help -- this will be asserted)! No scaling is possible.
 *
 *  protected void useDrawingDelegate(see below)
 *
 *      Simplifies drawing onto the torus bitmap.
 *
 *  void copyToScreen();
 *
 *  void  clear_to_color (AlCol);
 */
    void  clearToBlack () { this.clearToColor(color.black);  }
    void  clearToTransp() { this.clearToColor(color.transp); }
/*  void  setPixel     (int, int, AlCol);
 *  AlCol getPixel     (int, int) const;
 *
 *  // rectangles are given by Rx,  Ry,  Rxl, Ryl
 *  void drawRectangle      (int, int, int, int, AlCol);
 *  void drawFilledRectangle(int, int, int, int, AlCol);
 *
 *  // These methods are very slow, try not to use them each tick.
 *  // You should lock (Torbit.albit) before calling these functions,
 *  // they do not lock the bitmap themselves.
 *  void replaceColor        (AlCol, AlCol);
 *  void replaceColorInRect(int, int, int, int, AlCol, AlCol);
 *
 *  // for testing
 *  void saveToFile(in Filename);
 */

private:

    Albit bitmap;

    // height and width of bitmap ("x-length" and "y-length")
    int  _xl;
    int  _yl;

    // torus property in either direction, making edges of the bitmap loop
    bool _tx;
    bool _ty;



public:

this(
    in int a_xl,
    in int a_yl,
    in bool a_tx = false,
    in bool a_ty = false
) {
    _xl = a_xl;
    _yl = a_yl;
    _tx = a_tx;
    _ty = a_ty;
    bitmap = albitCreate(_xl, _yl);
    assert (bitmap);
}



this(const Torbit rhs)
{
    assert (rhs.bitmap);
    bitmap = al_clone_bitmap(cast (Albit) rhs.bitmap);
    if (bitmap) {
        _xl = rhs._xl;
        _yl = rhs._yl;
        _tx = rhs._tx;
        _ty = rhs._ty;
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
        assert (_xl == al_get_bitmap_width (cast (Albit) bitmap));
        assert (_yl == al_get_bitmap_height(cast (Albit) bitmap));
    }
}



void resize(int a_xl, int a_yl)
{
    if (bitmap) al_destroy_bitmap(bitmap);
    _xl = a_xl;
    _yl = a_yl;
    bitmap = albitCreate(_xl, _yl);
    assert (bitmap);
}



int distanceX(in int x1, in int x2) const
{
    if (! _tx) return x2 - x1;
    else {
        int[] possible = [x2-x1, x2-x1-_xl, x2-x1+_xl];
        return std.algorithm.minPos!"abs(a) < abs(b)"(possible)[0];
    }
}



int distanceY(in int y1, in int y2) const
{
    if (! _ty) return y2 - y1;
    else {
        int[] possible = [y2-y1, y2-y1-_yl, y2-y1+_yl];
        return std.algorithm.minPos!"abs(a) < abs(b)"(possible)[0];
    }
}



double hypot(in int x1, in int y1, in int x2, in int y2) const
{
    return std.math.sqrt(this.hypotSquared(x1, y1, x2, y2));
}



double hypotSquared(in int x1, in int y1, in int x2, in int y2) const
{
    immutable int dx = distanceX(x2, x1);
    immutable int dy = distanceY(y2, y1);
    return (dx * dx + dy * dy);
}



bool isPointInRectangle(
    int px, int py, int rx, int ry, int rxl, int ryl) const
{
    if (_tx) {
        px = positiveMod(px, _xl);
        rx = positiveMod(rx, _xl);
        // the following (if) omits the need for a 4-subrectangle-check
        if (px < rx) px += _xl;
    }
    if (_ty) {
        py = positiveMod(py, _yl);
        ry = positiveMod(ry, _yl);
        if (py < ry) py += _yl;
    }
    return (px >= rx && px < rx + rxl)
        && (py >= ry && py < ry + ryl);
}



protected void useDrawingDelegate(
    void delegate(int, int) drawing_delegate,
    int x,
    int y
) {
    assert (bitmap);
    assert (drawing_delegate != null);

    static if (_tharsisProfilingInTorbit)
        auto zone1 = Zone(profiler, "torbit-deleg-func");

    // We don't lock the bitmap; drawing with high-level primitives
    // and blitting other VRAM bitmaps is best without locking
    auto drata = DrawingTarget(bitmap);

    {
        static if (_tharsisProfilingInTorbit)
            auto zone2 = Zone(profiler, "torbit-deleg-once");
        drawing_delegate(x, y);
    }

    if (_tx       ) drawing_delegate(x - _xl, y      );
    if (       _ty) drawing_delegate(x,       y - _yl);
    if (_tx && _ty) drawing_delegate(x - _xl, y - _yl);
}



void drawFrom(
    Albit bit,
    int x = 0,
    int y = 0,
    bool mirr = false,
    double rot = 0,
    double scal = 0
) {
    static if (_tharsisProfilingInTorbit)
        auto myZone = Zone(profiler, "torbit-draw-from");

    assert (bit);

    // DTODO: test whether these mods can be shifted into use_delegate.
    if (_tx) x = positiveMod(x, _xl);
    if (_ty) y = positiveMod(y, _yl);
    rot = std.math.fmod(rot, 4);

    void delegate(int, int) drawFrom_at;
    assert(drawFrom_at == null);

    // Select the appropriate Allegro function and its arguments.
    // This function will be called up to 4 times for drawing (Albit bit) onto
    // (Torbit this). Only the positions vary based on the torus properties.

    if (rot == 0 && ! scal) {
        drawFrom_at =
         delegate void(int x_at, int y_at)
        {
            al_draw_bitmap(bit, x_at, y_at, ALLEGRO_FLIP_VERTICAL * mirr);
        };
    }
    else if (rot == 2 && ! scal) {
        drawFrom_at =
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

        if (! scal) drawFrom_at =
         delegate void(int x_at, int y_at)
        {
            al_draw_rotated_bitmap(bit, xsl/2.0, ysl/2.0,
                xdr + x_at, ydr + y_at,
                rot * ALLEGRO_PI / 2,
                mirr ? ALLEGRO_FLIP_VERTICAL : 0
            );
        };
        else drawFrom_at =
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

    useDrawingDelegate(drawFrom_at, x, y);
}



void drawDarkFrom(
    Albit bit,
    int x,
    int y,
    in bool mirr,
    in int rot, // must be one of 0, 1, 2, 3, that will be asserted.
    AlCol opaqueToThisCol
) {
    assert (bit);
    assert (bitmap);
    assert (rot >= 0 && rot < 4);

    static if (_tharsisProfilingInTorbit)
        auto myZone = Zone(profiler, "torbit-draw-dark-from");

    if (_tx) x = positiveMod(x, _xl);
    if (_ty) y = positiveMod(y, _yl);

    immutable int bxl = al_get_bitmap_width (bit);
    immutable int byl = al_get_bitmap_height(bit);
    immutable int txl = ((rot & 1) == 0 ? bxl : byl);
    immutable int tyl = ((rot & 1) == 0 ? byl : bxl);

    assert (txl > 0);
    assert (tyl > 0);

    // Don't draw anything if we're outside of the bitmap. A full torus
    // won't ever have us outside of it.
    if (x >= _xl     || y >= _yl    ) return;
    if (0 >= x + txl || 0 >= y + tyl) return;

    // Transform a point in the bitmap according to mirr and rot,
    // where the bitmap has coordinates ranging from 0, 0 to its bxl, byl.
    // Since we're transforming unrotated/unmirrored coordinates to mirrored
    // /rotated ones, source and range are either the same, or swapped,
    // for ix in 0 .. bxl and iy in 0 .. byl.
    import file.log;
    import basics.matrix;

    XY transfIxy(int ix, int iy)
    in {
        assert (ix >= 0);
        assert (iy >= 0);
        assert (ix < txl);
        assert (iy < tyl);
    }
    out (ret) {
        assert (ret.x >= 0);
        assert (ret.y >= 0);
        assert (ret.x < bxl);
        assert (ret.y < byl);
    }
    body {
        XY ret;
        switch (rot) {
            // Keep in mind we're transforming back onto the unrotated bitmap,
            // so cases 1 and 3 should be interchanged from what you'd expect.
            // But I confused myself a lot here, and have changed them back:
            case 0: ret.x = ix;       ret.y = iy;       break;
            case 1: ret.x = iy;       ret.y = txl-1-ix; break;
            case 2: ret.x = txl-1-ix; ret.y = tyl-1-iy; break;
            case 3: ret.x = tyl-1-iy; ret.y = ix;       break;
            default: assert (false);
        }
        // drawing first mirrors, then rotates. When we are computing
        // backwards, rotate first, then flip now.
        if (mirr) {
            if (rot & 1) ret.x = bxl-1-ret.x;
            else         ret.y = byl-1-ret.y;
        }
        return ret;
    }

    // ddf_at means "drawDarkFrom_at".
    // This function will be called with rectangles, fully specified by
    // their top left corner and txl/tyl of the current scope.
    // but by start and end coordinates. Its coordinates are not guaranteed
    // to be on the screen, but it will fix that.
    void ddf_at(
        int startX, int startY    // where to draw on the torbit
    ) {
        int bitStartX = 0; // where to start iteration on (bit)
        int bitStartY = 0;
        int endX = startX + txl;
        int endY = startY + tyl;

        if (startX < 0)  { bitStartX = -startX; startX = 0; }
        if (startY < 0)  { bitStartY = -startY; startY = 0; }
        if (endX   > _xl) endX = _xl;
        if (endY   > _yl) endY = _yl;
        if (startX >= endX || startY >= endY) return;

        // I'm afraid to call the following Allegro 5 function with off-bitmap
        // coordinates, that's why I've fixed everything and returned above.
        ALLEGRO_LOCKED_REGION* locked_region = al_lock_bitmap_region(
            bitmap, startX, startY,
            endX - startX,
            endY - startY,
            ALLEGRO_PIXEL_FORMAT.ALLEGRO_PIXEL_FORMAT_ANY, // is fastest
            ALLEGRO_LOCK_READWRITE);
        scope (exit)
            al_unlock_bitmap(bitmap);

        auto drata = DrawingTarget(bitmap);
        foreach  (int targetX; startX .. endX)
         foreach (int targetY; startY .. endY) {
            immutable int ix = targetX - startX + bitStartX;
            immutable int iy = targetY - startY + bitStartY;
            immutable XY    transf = transfIxy(ix, iy);
            immutable AlCol srcCol = al_get_pixel(bit, transf.x, transf.y);
            if (srcCol != color.transp)
                al_put_pixel(targetX, targetY, opaqueToThisCol);
        }
        // end foreach
    }
    // end local function

    auto lockBit = LockReadWrite(bit);
                    ddf_at(x,       y);
    if (_tx       ) ddf_at(x - _xl, y);
    if (       _ty) ddf_at(x,       y - _yl);
    if (_tx && _ty) ddf_at(x - _xl, y - _yl);
}



void copyToScreen()
{
    auto drata = DrawingTarget(al_get_backbuffer(display));
    al_draw_bitmap(bitmap, 0, 0, 0);
}



void clearToColor(AlCol col)
{
    auto drata = DrawingTarget(bitmap);
    al_clear_to_color(col);
}



AlCol getPixel(int x, int y) const
{
    assert(bitmap);
    // when checking for pixels behind the border, we're repeating the last
    // pixel inside the bitmap at the border. If it's a torus, of course we
    // don't do this and loop normally.

    // From the Allegro docs: this is slow on video bitmaps, consider locking
    // manually in the class calling this method.
    return al_get_pixel(cast (Albit) bitmap,
     _tx      ? positiveMod(x, _xl) :
     x < 0    ? 0                    :
     x >= _xl ? _xl - 1              : x,
     _ty      ? positiveMod(y, _yl) :
     y < 0    ? 0                    :
     y >= _yl ? _yl - 1              : y);
}



void setPixel(int x, int y, AlCol col)
{
    assert(bitmap);
    // Here, don't draw outside of the boundaries, unlike the reading in
    // Torbit.get_pixel. Again, it's slow on video bitmaps.
    auto drata = DrawingTarget(bitmap);
    if ((_tx || (x >= 0 && x < _xl))
     && (_ty || (y >= 0 && y < _yl)) ) al_put_pixel(
     _tx ? positiveMod(x, _xl) : x,
     _ty ? positiveMod(y, _yl) : y, col);
}



void drawRectangle(int x, int y, int rxl, int ryl, AlCol col)
{
    static if (_tharsisProfilingInTorbit)
        auto myZone = Zone(profiler, "torbit-draw-rect");

    // DTODO: test whether the mod can be moved into the delegate invoker.
    if (_tx) x = positiveMod(x, _xl);
    if (_ty) y = positiveMod(y, _yl);
    useDrawingDelegate(delegate void(int x_at, int y_at) {
        al_draw_rectangle(x_at + 0.5, y_at + 0.5,
         x_at + rxl - 0.5, y_at + ryl - 0.5, col, 1);
    }, x, y);
}



void drawFilledRectangle(int x, int y, int rxl, int ryl, AlCol col)
{
    // DTODO: test whether the mod can be moved into the delegate invoker.
    if (_tx) x = positiveMod(x, _xl);
    if (_ty) y = positiveMod(y, _yl);

    auto deg = delegate void(int x_at, int y_at)
    {
        al_draw_filled_rectangle(x_at, y_at, x_at + rxl, y_at + ryl, col);
    };
    useDrawingDelegate(deg, x, y);
}



void replaceColor(AlCol c_old, AlCol c_new)
{
    replaceColorInRect(0, 0, _xl, _yl, c_old, c_new);
}



void replaceColorInRect(
    int rx, int ry, int rxl, int ryl, AlCol c_old, AlCol c_new
) {
    assert (false, "DTODO: do we even need this function? uncomment it then");
/*
    if (! bitmap) return;
    if (tx) rx = positiveMod(rx, xl);
    if (ty) ry = positiveMod(ry, yl);

    auto deg = delegate void(int at_x, int at_y)
    {
        // don't draw outside the boundaries
        immutable int startX = max(at_x, 0);
        immutable int startY = max(at_y, 0);
        immutable int endX = min(at_x + rxl, xl);
        immutable int endY = min(at_y + ryl, yl);

        // these functions are slow, so replaceColorInRect should lock
        // the bitmap before passing this delegate DTODO, no locking yet
        foreach (x; startX .. endX)
         foreach (y; startY .. endY)
         if (al_get_pixel(bitmap, x, y) == c_old) al_put_pixel(x, y, c_new);
    };

    //mixin(temp_lock!"bitmap");
    useDrawingDelegate(deg, rx, ry);
*/
}



void saveToFile(in Filename fn)
{
    al_save_bitmap(fn.rootfulZ, bitmap);
}

}
// end class
