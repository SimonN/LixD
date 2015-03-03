module graphic.cutbit;

import basics.alleg5;
import graphic.color;
import graphic.torbit;
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
    this(const Cutbit);
    this(AlBit,          const bool cut); // takes ownership of bitmap!
    this(const Filename, const bool cut);
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

    AlCol get_pixel(int px, int py)                 const;
    AlCol get_pixel(int fx, int fy, int px, int py) const;

    // Cutbit zeichnen auf die angegebene Unterlage
    // DTODO: translate comments here to English
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

    void cut_bitmap();



public:

this(const Cutbit cb)
{
    xl = cb.xl;
    yl = cb.yl;
    x_frames = cb.x_frames;
    y_frames = cb.y_frames;

    if (cb.bitmap) {
        bitmap = albit_create(al_get_bitmap_width (cast (AlBit) cb.bitmap),
                              al_get_bitmap_height(cast (AlBit) cb.bitmap));
        mixin(temp_target!"bitmap");
        al_draw_bitmap(cast (AlBit) cb.bitmap, 0, 0, 0);
        assert(bitmap);
    }
}



this(AlBit bit, const bool cut)
{
    bitmap = bit;
    if (!bitmap) return;

    if (cut) cut_bitmap();
    else {
        xl = al_get_bitmap_width (bitmap);
        yl = al_get_bitmap_height(bitmap);
        x_frames = 1;
        y_frames = 1;
    }
}



this(const Filename fn, const bool cut)
{
    // Try loading the file. If not found, don't crash, but make a log entry.
    bitmap = al_load_bitmap(fn.get_rootful());
    if (!bitmap) {
        Log.log(Language["log_bitmap_bad"] ~ " " ~ fn.get_rootless());
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
    }
    else {
        assert (xl == 0);
        assert (yl == 0);
        assert (x_frames == 0);
        assert (y_frames == 0);
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
     && c == al_get_pixel(bitmap, 0, 1)
     && c == al_get_pixel(bitmap, 1, 0)
     && c != al_get_pixel(bitmap, 1, 1)) {
        // find the end of the first frame in each direction
        for (xl = 2; xl < x_max; ++xl) {
            if (equals(c, al_get_pixel(bitmap, xl, 1))) {
                --xl;
                break;
            }
        }
        for (yl = 2; yl < y_max; ++yl) {
            if (equals(c, al_get_pixel(bitmap, 1, yl))) {
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
    // done cutting
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
        assert (false, "DTODO: implement printing message for nonexistant frame");
        /*
        int          col_text = makecol(255, 255, 255);
        int          col_back = makecol( 64,  64,  64);
        if (!bitmap) col_back = makecol(255,  64,  64);
        std::ostringstream str;
        str << "( " << fx << " | " << fy << " )";
        textout_ex(target, font, "Frame?!?!", x, y,        col_text, col_back);
        textout_ex(target, font, str.str().c_str(), x, y+8,col_text, col_back);
        */
    }
}

}
// end class
