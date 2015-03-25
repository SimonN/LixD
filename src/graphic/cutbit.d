module graphic.cutbit;

import basics.alleg5;
import basics.matrix; // which frames exist?
import graphic.color;
import graphic.torbit;
import graphic.textout; // write error message instead of drawing bitmap
import file.filename;
import file.language;
import file.log; // log bad filename when trying to load a bitmap

class Cutbit {

    enum Mode {
        NORMAL,
        NOOW,
        DARK,
        NOOW_EDITOR,
        DARK_EDITOR,
        DARK_SHOW_NOOW, // only for some steel mask internal drawing
        STEEL,
        STEEL_NOOW
    }

    this() {}
    this(in Cutbit);
    this(AlBit,          const bool cut = true); // takes ownership of bitmap!
    this(const Filename, const bool cut = true);
    this(AlBit[]);

    bool opEquals(const Cutbit) const;

    bool  is_valid()      const { return bitmap != null; }
    AlBit get_al_bitmap() const { return cast (AlBit) bitmap; }
    AlBit get_albit()     const { return cast (AlBit) bitmap; }

    // get size of a single frame, not necessarily size of entire bitmap
    int   get_xl()        const { return xl;       }
    int   get_yl()        const { return yl;       }
    int   get_x_frames()  const { return x_frames; }
    int   get_y_frames()  const { return y_frames; }

    // these two are slow, consider get_frame_exists() instead
    AlCol get_pixel(int px, int py)                 const;
    AlCol get_pixel(int fx, int fy, int px, int py) const;

    // Checks whether the given frame contains interesting image data, instead
    // of being marked as nonexistant by being filled with frame color.
    // This is very fast, it uses the cached data in RAM.
    bool get_frame_exists(in int fx, in int fy) const;

    // draw a cutbit onto the given Torbit
    // DTODOLANG: translate comments here to English
    void draw(Torbit,
              const int    = 0, const int = 0, // X-, Y-Position
              const int    = 0, const int = 0, // X-, Y-Frame
              const bool   = false,            // Vertikal gespiegelt?
              const double = 0,                // Vierteldrehungen?
              const double = 0,                // Strecken? Nein = 0 oder 1.
              const Mode = Mode.NORMAL) const; // Farbe malen anstatt Objekt,
                                               // gaengig: -1 fuer Loeschterr.

private:

    AlBit bitmap;

    int xl;
    int yl;
    int x_frames;
    int y_frames;

    Matrix!bool existing_frames;

    void cut_bitmap();



public:

this(in Cutbit cb)
{
    if (! cb) return;
    xl = cb.xl;
    yl = cb.yl;
    x_frames = cb.x_frames;
    y_frames = cb.y_frames;
    existing_frames = new Matrix!bool(cb.existing_frames);

    if (cb.bitmap) {
        bitmap = albit_create(al_get_bitmap_width (cast (AlBit) cb.bitmap),
                              al_get_bitmap_height(cast (AlBit) cb.bitmap));
        mixin(temp_target!"bitmap");
        al_draw_bitmap(cast (AlBit) cb.bitmap, 0, 0, 0);
        assert(bitmap);
    }
}



this(AlBit bit, const bool cut = true)
{
    bitmap = bit;
    if (! bitmap) return;

    if (cut) cut_bitmap();
    else {
        xl = al_get_bitmap_width (bitmap);
        yl = al_get_bitmap_height(bitmap);
        x_frames = 1;
        y_frames = 1;

        existing_frames = new Matrix!bool(1, 1);
        existing_frames.set(0, 0, true);
    }
}



this(const Filename fn, const bool cut = true)
{
    // Try loading the file. If not found, don't crash, but make a log entry.
    bitmap = al_load_bitmap(fn.get_rootful_z());
    if (! bitmap) {
        Log.log(Lang["log_bitmap_bad"] ~ " " ~ fn.get_rootless());
        this();
    }
    else this(bitmap, cut);
}



this(AlBit[] manybits)
{
    assert (false, "this(AlBit[] many bitmaps) not yet implemented");
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
        assert (al_get_bitmap_width (cast (AlBit) bitmap) >= xl);
        assert (al_get_bitmap_height(cast (AlBit) bitmap) >= yl);
        assert (existing_frames !is null);
    }
    else {
        assert (xl == 0);
        assert (yl == 0);
        assert (x_frames == 0);
        assert (y_frames == 0);
        assert (existing_frames is null);
    }
}



bool opEquals(const Cutbit rhs) const
{
    return bitmap == rhs.bitmap;
}



private void cut_bitmap()
{
    mixin(temp_lock!"bitmap");

    immutable int x_max = al_get_bitmap_width (bitmap);
    immutable int y_max = al_get_bitmap_height(bitmap);

    // This is called when the constructor was invoked with bool cut == true.
    // To cut a bitmap into frames, check the top left 2x2 block. The three
    // pixels of it touching the edge shall be of one color, and the inner
    // pixel must be of a different color, to count as a frame grid.
    AlCol c = al_get_pixel(bitmap, 0, 0);
    if (x_max > 1 && y_max > 1
     && al_get_pixel(bitmap, 0, 1) == c
     && al_get_pixel(bitmap, 1, 0) == c
     && al_get_pixel(bitmap, 1, 1) != c) {
        // find the end of the first frame in each direction
        for (xl = 2; xl < x_max; ++xl) {
            if (al_get_pixel(bitmap, xl, 1) == c) {
                --xl;
                break;
            }
        }
        for (yl = 2; yl < y_max; ++yl) {
            if (al_get_pixel(bitmap, 1, yl) == c) {
                --yl;
                break;
            }
        }

        // don't cut the bitmap if at most 1-by-1 frame is possible
        if (xl * 2 > x_max && yl * 2 > y_max) {
            xl = x_max;
            yl = y_max;
            x_frames = 1;
            y_frames = 1;
        }
        // ...otherwise compute the number of frames in each direction
        else {
            for (x_frames = 0; (x_frames+1)*(xl+1) < x_max; ++x_frames) {}
            for (y_frames = 0; (y_frames+1)*(yl+1) < y_max; ++y_frames) {}
        }
    }

    // no frame apparent in the top left 2x2 block of pixels
    else {
        xl = x_max;
        yl = y_max;
        x_frames = 1;
        y_frames = 1;
    }

    // done cutting, now generate matrix. The bitmap is still locked.
    existing_frames = new Matrix!bool(x_frames, y_frames);
    if (x_frames == 1 && y_frames == 1) {
        existing_frames.set(0, 0, true);
    }
    else {
        for (int yf = 0; yf < y_frames; ++yf)
         for (int xf = 0; xf < x_frames; ++xf) {
            immutable bool has_frame_color = (get_pixel(xf, yf, 0, 0) == c);
            existing_frames.set(xf, yf, ! has_frame_color);
        }
    }
    // done making the matrix
}



AlCol get_pixel(int px, int py) const
{
    return get_pixel(0, 0, px, py);
}



AlCol get_pixel(int fx, int fy,
                int px, int py) const
{
    // frame doesn't exist, or pixel doesn't exist in the frame
    if  (fx < 0 || fy < 0 || fx >= x_frames || fy >= y_frames
     ||  px < 0 || py < 0 || px >= xl       || py >= yl) {
        return color.bad;
    }
    // otherwise, return the found color
    else if (x_frames == 1 && y_frames == 1)
         return al_get_pixel(cast (AlBit) bitmap, px, py);
    else return al_get_pixel(cast (AlBit) bitmap, fx * (xl+1) + 1 + px,
                                                  fy * (yl+1) + 1 + py);
}



bool get_frame_exists(in int fx, in int fy) const
{
    if (fx < 0 || fx >= x_frames
     || fy < 0 || fy >= y_frames) return false;
    else return existing_frames.get(fx, fy);
}



void draw(
    Torbit       target_torbit,
    const int    x = 0,
    const int    y = 0,
    const int    fx = 0,
    const int    fy = 0,
    const bool   mirr = false,
    const double rot  = 0,
    const double scal = 0,
    const Mode   mode = Mode.NORMAL) const
{
    AlBit target = target_torbit.get_al_bitmap();

    if (bitmap && fx >= 0 && fy >= 0 && fx < x_frames && fy < y_frames) {
        // Create a sub-bitmap based on the wanted frames. If (Cutbit this)
        // doesn't have frames, don't compute +1 for the outermost frame.
        AlBit sprite;
        if (x_frames == 1 && y_frames == 1)
             sprite = al_create_sub_bitmap(cast (AlBit) bitmap, 0, 0, xl, yl);
        else sprite = al_create_sub_bitmap(cast (AlBit) bitmap, fx * (xl+1)+1,
                                                   fy * (yl+1) + 1, xl, yl);
        scope (exit) al_destroy_bitmap(sprite);

        if (mode == Mode.NORMAL) {
            target_torbit.draw_from(sprite, x, y, mirr, rot, scal);
        }
        // DTODO: implement the remainin drawing modes
        else assert (false, "DTODO: implement more drawing modes");
        /*
        else {
            const int PINK  = color[COL_PINK];
            const int BLACK = color[COL_BLACK];
            const int GREY  = color[COL_EDITOR_DARK];
            const int size  = xl > yl ? xl : yl;
            Torbit excerpt(size, size);
            excerpt.clear_to_color(PINK);
            excerpt.draw_from(sprite, 0, 0, mirr, rot, scal);
            if (mode == NOOW) {
                target_torbit.draw     (excerpt.get_al_bitmap(), x, y);
                target_torbit.draw_from(excerpt.get_al_bitmap(), x, y);
            }
            else if (mode == NOOW_EDITOR) {
                for  (int ix = 0; ix < size; ++ix)
                 for (int iy = 0; iy < size; ++iy) {
                    const int c = target_torbit.get_pixel(x + ix, y + iy);
                    const int e = excerpt      .get_pixel(    ix,     iy);
                    if ((c == BLACK || c == PINK || c == GREY)
                     &&  e != BLACK && e != PINK)
                     target_torbit.set_pixel(x + ix, y + iy, e);
            }   }
            else if (mode == DARK
                  || mode == DARK_EDITOR
                  || mode == DARK_SHOW_NOOW) {
                for  (int ix = 0; ix < size; ++ix)
                 for (int iy = 0; iy < size; ++iy)
                 if (excerpt      .get_pixel(  ix,   iy) != PINK
                 && (target_torbit.get_pixel(x+ix, y+iy) == PINK
                                                 || mode != DARK_SHOW_NOOW))
                 target_torbit.set_pixel(x+ix, y+iy,
                 mode == DARK ? PINK : GREY);
            }
            else if (mode == STEEL || mode == STEEL_NOOW) {
                // Fuer stahlfarbiges Zeichnen auf pinken Hintergrund
                for  (int ix = 0; ix < size; ++ix)
                 for (int iy = 0; iy < size; ++iy)
                 if (excerpt      .get_pixel(  ix,   iy) != PINK
                 && (target_torbit.get_pixel(x+ix, y+iy) == PINK
                                                 || mode != STEEL_NOOW))
                     target_torbit.set_pixel(x+ix, y+iy,
                      color[COL_STEEL_MASK]);
            }
        }
        */
    }

    // no frame inside the cutbit has been specified, or the cutbit
    // has a null bitmap
    else {
        string str = "File N/A";
        AlCol  col = color.cb_bad_bitmap;
        if (bitmap) {
            str = format("(%d,%d)", fx, fy);
            col = color.cb_bad_frame;
        }
        drtx(target_torbit, str, x, y, col);
    }
}

}
// end class