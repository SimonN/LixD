module graphic.cutbit;

import basics.alleg5;
import basics.help; // positive_mod
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
        NOOW, // no-overwrite, draw only the pixels falling on transparent bg
        DARK, // instead of drawing a pixel, erase a pixel from the bg
        NOOW_EDITOR, // Like NOOW, but treats the editor's NOOW color as transp
        DARK_EDITOR, // like DARK, but draw a dark color, not transparent
    }

    this() { }
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
    // or lock the Cutbit's underlying Allegro bitmap yourself
    AlCol get_pixel(int px, int py)                 const;
    AlCol get_pixel(int fx, int fy, int px, int py) const;

/*  bool get_frame_exists(in int fx, in int fy) const;
 *
 *      Checks whether the given frame contains interesting image data,
 *      instead of being marked as nonexistant by being filled with the
 *      already-detected frame/grid color.
 *
 *      This is very fast, it uses the cached data in RAM. It's much better
 *      to consult this instead of querying for pixels later inside frames.
 *
 *  void draw(torbit, x, y, xf, yf, mirr, double rot, double scal) const;
 *  void draw(torbit, x, y,         mirr, int    rot, Mode   mode) const;
 *
 *      The first is intended for free-form drawing without effect on land.
 *      Interactive objects and the flying pickaxe are drawn with this.
 *
 *      The second is intended to draw terrain and steel. These can only
 *      be rotated by quarter turns, and have only one frame per piece.
 *      However, they can be drawn with one of the drawing modes, like
 *      no-overwrite or dark.
 *
 *      (rot) (either int or double) means how many quarter turns to be made.
 *      I believe they're measured counter-clockwise.
 *
 *      (double scal) can be set to 0 or 1 when one doesn't wish to rescale.
 */

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
        Log.log("Missing image: " ~ fn.get_rootless());
        this();
    }
    else {
        al_convert_mask_to_alpha(bitmap, color.pink);
        this(bitmap, cut);
    }
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



private void draw_missing_frame_error(
    Torbit torbit, in int x, in int y, in int fx, in int fy) const
{
    string str = "File N/A";
    AlCol  col = color.cb_bad_bitmap;
    if (bitmap) {
        str = format("(%d,%d)", fx, fy);
        col = color.cb_bad_frame;
    }
    mixin(temp_target!"torbit.get_albit()");
    draw_text(djvu_s, str, x, y, col);
}



void draw(
    Torbit       target_torbit,
    const int    x = 0,
    const int    y = 0,
    const int    fx = 0,
    const int    fy = 0,
    const bool   mirr = false,
    const double rot  = 0,
    const double scal = 0) const
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

        target_torbit.draw_from(sprite, x, y, mirr, rot, scal);
    }
    // no frame inside the cutbit has been specified, or the cutbit
    // has a null bitmap
    else {
        draw_missing_frame_error(target_torbit, x, y, fx, fy);
    }
}



void draw(
    Torbit    target_torbit,
    in int    x,
    in int    y,
    in bool   mirr,
    int       rot,
    in Mode   mode) const
{
    if (! bitmap) {
        draw_missing_frame_error(target_torbit, x, y, 0, 0);
        return;
    }
    // only one frame allowed, so we don't have to make sub-bitmaps
    assert (x_frames == 1);
    assert (y_frames == 1);

    rot = basics.help.positive_mod(rot, 4);
    assert (rot >= 0 || rot < 4);

    final switch (mode) {

    case Mode.NORMAL:
        // this is very much like the other draw function
        target_torbit.draw_from(cast (AlBit) bitmap, x, y, mirr, rot * 1.0f);
        break;

    case Mode.DARK:
    case Mode.DARK_EDITOR:
        // the Torbit will know what to lock for best speed, so we have
        // moved the implementation there. Here, we only choose the color.
        target_torbit.draw_dark_from(cast (AlBit) bitmap, x, y, mirr, rot,
            mode == Mode.DARK ? color.transp : color.gui_sha);
        break;

    case Mode.NOOW: {
        immutable invert_lengths = (rot % 2 == 1);
        Torbit excerpt = new Torbit(
            invert_lengths ? yl : xl,
            invert_lengths ? xl : yl);
        excerpt.clear_to_color(color.transp);
        excerpt.draw_from(cast (AlBit) bitmap, 0, 0, mirr, rot);
        target_torbit.draw     (excerpt.get_albit(), x, y);
        target_torbit.draw_from(excerpt.get_albit(), x, y);
        break; }

    case Mode.NOOW_EDITOR:
        assert (false, "DTODO: implement more drawing modes");
        /*
        else if (mode == NOOW_EDITOR) {
        for  (int ix = 0; ix < size; ++ix)
         for (int iy = 0; iy < size; ++iy) {
            const int c = target_torbit.get_pixel(x + ix, y + iy);
            const int e = excerpt      .get_pixel(    ix,     iy);
            if ((c == BLACK || c == PINK || c == GREY)
             &&  e != BLACK && e != PINK)
             target_torbit.set_pixel(x + ix, y + iy, e);
        */
    }
    // we don't have to draw the missing-frame error here; there could have
    // only been the missing-image error, and we've checked for that already.
}
// end function draw with mode

}
// end class
