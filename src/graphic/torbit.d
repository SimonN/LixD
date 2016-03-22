module graphic.torbit;

import std.math; // fmod, abs
import std.algorithm; // minPos

import basics.alleg5;
import basics.help; // positiveMod
import basics.topology;
import graphic.color; // drawing dark, to analyze transparency
import file.filename;
import hardware.display;

public import basics.rect;

class Torbit : Topology {
private:
    Albit bitmap;

public:
    @property inout(Albit) albit() inout { return bitmap; }

    this(in int _xl, in int _yl, in bool _tx = false, in bool _ty = false)
    {
        super(_xl, _yl, _tx, _ty);
        bitmap = albitCreate(_xl, _yl);
    }

    this(const(Topology) topol)
    {
        super(topol);
        bitmap = albitCreate(topol.xl, topol.yl);
    }

    this(const Torbit rhs)
    {
        assert (rhs, "Don't copy-construct from a null Torbit.");
        assert (rhs.bitmap, "shouldn't ever happen, bug in Torbit");
        super(rhs);
        bitmap = al_clone_bitmap(cast (Albit) rhs.bitmap);
    }

    void copyFrom(in Torbit rhs)
    {
        assert (rhs, "can't copyFrom a null Torbit");
        assert (bitmap, "null bitmap shouldn't ever happen, bug in Torbit");
        assert (rhs.bitmap, "null rhs.bitmap shouldn't ever happen");
        assert (rhs.Topology.opEquals(this),
            "copyFrom only implemented between same size, for speedup");
        auto drata = DrawingTarget(bitmap);
        al_draw_bitmap(cast (Albit) rhs.bitmap, 0, 0, 0);
    }

    ~this() { dispose(); }
    void dispose()
    {
        if (bitmap) {
            al_destroy_bitmap(bitmap);
            bitmap = null;
        }
    }

    void copyToScreen()
    {
        auto drata = DrawingTarget(al_get_backbuffer(display));
        al_draw_bitmap(bitmap, 0, 0, 0);
    }

    void clearToBlack()  { this.clearToColor(color.black);  }
    void clearToTransp() { this.clearToColor(color.transp); }
    void clearToColor(AlCol col)
    {
        auto drata = DrawingTarget(bitmap);
        al_clear_to_color(col);
    }

    void drawRectangle(Rect rect, in AlCol col)
    {
        amend(rect.x, rect.y);
        useDrawingDelegate(delegate void(int x_at, int y_at) {
            al_draw_rectangle(x_at + 0.5, y_at + 0.5,
             x_at + rect.xl - 0.5, y_at + rect.yl - 0.5, col, 1);
        }, rect.x, rect.y);
    }

    void drawFilledRectangle(int x, int y, int rxl, int ryl, AlCol col)
    {
        amend(x, y);
        auto deg = delegate void(int x_at, int y_at)
        {
            al_draw_filled_rectangle(x_at, y_at, x_at + rxl, y_at + ryl, col);
        };
        useDrawingDelegate(deg, x, y);
    }

    void saveToFile(in Filename fn)
    {
        al_save_bitmap(fn.rootfulZ, bitmap);
    }

    // Draw the entire Albit onto (Torbit this). Can take non-integer quarter
    // turns as (double rot).
    void drawFrom(
        Albit bit,
        int x = 0,
        int y = 0,
        bool mirr = false,
        double rot = 0,
        double scal = 0
    ) {
        assert (bit, "can't blit the null bitmap onto Torbit");
        amend(x, y);
        rot = std.math.fmod(rot, 4);

        void delegate(int, int) drawFrom_at;
        assert(drawFrom_at == null);
        // Select the appropriate Allegro function and its arguments.
        // This function will be called up to 4 times for drawing (Albit bit)
        // onto (Torbit this). Only the positions vary based on torus property.
        if (rot == 0 && ! scal) {
            drawFrom_at = delegate void(int x_at, int y_at)
            {
                al_draw_bitmap(bit, x_at, y_at, ALLEGRO_FLIP_VERTICAL * mirr);
            };
        }
        else if (rot == 2 && ! scal) {
            drawFrom_at = delegate void(int x_at, int y_at)
            {
                al_draw_bitmap(bit, x_at, y_at,
                 (ALLEGRO_FLIP_VERTICAL * !mirr) | ALLEGRO_FLIP_HORIZONTAL);
            };
        }
        else {
            // Comment (C1)
            // We don't expect non-square things to be rotated by non-integer
            // amounts of quarter turns. Squares will have xdr = ydr = 0 in
            // this scope, see the variable definitions below.
            // The non-square terrain will only be rotated in steps of quarter
            // turns, and its top-left corner after rotation shall remain at
            // the specified level coordinates, no matter how it's rotated.
            // Terrain rotated by 0 or 2 quarter turns has already been managed
            // by the (if)s above. Now, we'll be doing a noncontinuous jump at
            // exactly 1 and 3 quarter turns, which will manage the terrain
            // well, and doesn't affect continuous rotations of squares anyway.
            immutable bool b = (rot == 1 || rot == 3);

            // x/y-length of the source bitmap
            immutable int xsl = al_get_bitmap_width (bit);
            immutable int ysl = al_get_bitmap_height(bit);

            // Comment (C2)
            // We don't want to rotate around the center point of the source
            // bitmap. That would only be the case if the source is a square.
            // We wish to have the top-left corner of the rotated shape at x/y
            // whenever we perform a multiple of a quarter turn.
            // DTODO: Test this on Linux and Windows, whether it generates the
            // same terrain.
            float xdr = b ? ysl/2f : xsl/2f;
            float ydr = b ? xsl/2f : ysl/2f;

            if (! scal) drawFrom_at = delegate void(int x_at, int y_at)
            {
                al_draw_rotated_bitmap(bit, xsl/2f, ysl/2f,
                    xdr + x_at, ydr + y_at,
                    rot * ALLEGRO_PI / 2,
                    mirr ? ALLEGRO_FLIP_VERTICAL : 0
                );
            };
            else drawFrom_at = delegate void(int x_at, int y_at)
            {
                // Let's recap for rot == 0:
                // (xsl, ysl) are the x- and y-length of the unscaled source.
                // (xdr, ydr) are half of that.
                // I multiply xdr, ydr in line (L3) below with scal, because
                // according to comment (C2), the drawn shape's top-left corner
                // for rot == 0 should end up at drawFrom's arguments x and y.
                al_draw_scaled_rotated_bitmap(bit,
                    xsl/2f, // (A): this point of the unscaled source bitmap
                    ysl/2f, //      is drawn to...
                    xdr * scal + x_at, // (L3) ...to this target pos...
                    ydr * scal + y_at,
                    scal, scal, // ...and then it's scaled relative to there
                    rot * ALLEGRO_PI / 2,
                    mirr ? ALLEGRO_FLIP_VERTICAL : 0
                );
            };
        }
        useDrawingDelegate(drawFrom_at, x, y);
    }

    void drawFromPreservingAspectRatio(in Torbit from)
    {
        auto drata = DrawingTarget(bitmap);
        immutable float scaleX = 1.0f * xl / from.xl;
        immutable float scaleY = 1.0f * yl / from.yl;
        // draw (from) as large as possible onto (this), which requires that
        // the strongest restriction is followed, i.e.,
        // we scale by the smallest scaling factor.
        int destXl = xl, destYl = yl;
        if (scaleX < scaleY)
            destYl = (yl * scaleX/scaleY).roundInt;
        else
            destXl = (xl * scaleY/scaleX).roundInt;
        assert (destXl <= xl && destYl == yl
            ||  destYl <= yl && destXl == xl);
        al_draw_scaled_bitmap(cast (Albit) from.bitmap,
            0, 0, from.xl, from.yl,
            (xl-destXl)/2, (yl-destYl)/2, destXl, destYl, 0);
    }

    void drawFromPixel(in Albit from,
        in int fromX, in int fromY,
        int x, int y
    ) {
        assert (this.bitmap == al_get_target_bitmap(),
            "drawFromSinglePixel is designed for high-speed drawing."
            "Set the target bitmap manually to the target torbit's bitmap.");
        assert (from);
        assert (fromX >= 0);
        assert (fromY >= 0);
        assert (fromX < al_get_bitmap_width (cast (Albit) from));
        assert (fromY < al_get_bitmap_height(cast (Albit) from));
        amend(x, y);
        al_draw_bitmap_region(cast (Albit) from, fromX, fromY, 1, 1, x, y, 0);
    }

    // These methods (getPixel, setPixel) are very slow on VRAM bitmaps.
    // You should lock (Torbit.albit) before calling these functions,
    // they do not lock the bitmap themselves.
    // Even then, minimize accessing individual pixels, it's slow.
    AlCol getPixel(int x, int y) const
    {
        assert(bitmap);
        // when checking for pixels behind the border, we're repeating the last
        // pixel inside the bitmap at the border. If it's a torus, of course we
        // don't do this and loop normally.

        // From the Allegro docs: this is slow on video bitmaps,
        // consider locking manually in the class calling this method.
        return al_get_pixel(cast (Albit) bitmap,
            torusX  ? positiveMod(x, xl) :
            x < 0   ? 0                  :
            x >= xl ? xl - 1             : x,
            torusY  ? positiveMod(y, yl) :
            y < 0   ? 0                  :
            y >= yl ? yl - 1             : y);
    }

    // See comment for getPixel.
    void setPixel(int x, int y, AlCol col)
    {
        assert(bitmap);
        // Here, don't draw outside of the boundaries, unlike the reading in
        // Torbit.get_pixel. Again, it's slow on video bitmaps.
        assert (this.bitmap == al_get_target_bitmap(),
            "Torbit.setPixel is designed for high-speed drawing."
            "Set the target bitmap manually to the target torbit's bitmap.");
        if (   (torusX || (x >= 0 && x < xl))
            && (torusY || (y >= 0 && y < yl))
        )
            al_put_pixel(torusX ? positiveMod(x, xl) : x,
                         torusY ? positiveMod(y, yl) : y, col);
    }

protected:
    final override void onResize()
    out {
        assert (bitmap);
        assert (xl == al_get_bitmap_width (bitmap));
        assert (yl == al_get_bitmap_height(bitmap));
    }
    body {
        if (bitmap)
            al_destroy_bitmap(bitmap);
        bitmap = albitCreate(xl, yl);
    }

private:
    // This differs from Phymap.amend! Maybe reword Phymap.amend to
    // Phymap.amendForReading, and put Torbit.amend as a final method
    // into Topology?
    void amend(ref int x, ref int y) const
    {
        if (torusX) x = positiveMod(x, xl);
        if (torusY) y = positiveMod(y, yl);
    }

    void useDrawingDelegate(
        void delegate(int, int) drawing_delegate,
        int x,
        int y
    ) {
        assert (bitmap);
        assert (drawing_delegate != null);

        // We don't lock the bitmap; drawing with high-level primitives
        // and blitting other VRAM bitmaps is best without locking
        auto drata = DrawingTarget(bitmap);
        {
            drawing_delegate(x, y);
        }
        if (torusX          ) drawing_delegate(x - xl, y     );
        if (          torusY) drawing_delegate(x,      y - yl);
        if (torusX && torusY) drawing_delegate(x - xl, y - yl);
    }
}
// end class Torbit
