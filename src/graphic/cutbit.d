module graphic.cutbit;

import std.algorithm; // max(-x, 0) in draw_directly_to_screen()

import basics.alleg5;
import basics.help; // positive_mod
import basics.matrix; // which frames exist?
import graphic.color;
import graphic.torbit;
import graphic.textout; // write error message instead of drawing bitmap
import file.filename;
import file.language;
import file.log; // log bad filename when trying to load a bitmap
import hardware.display; // draw_directly_to_screen()

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
    this(Albit,          const bool cut = true); // takes ownership of bitmap!
    this(const Filename, const bool cut = true);
    this(Albit[]);

    bool opEquals(const Cutbit) const;

    @property bool  valid() const { return bitmap != null; }
    @property Albit albit() const { return cast (Albit) bitmap; }

    // get size of a single frame, not necessarily size of entire bitmap
    @property int xl()  const { return _xl;  }
    @property int yl()  const { return _yl;  }
    @property int xfs() const { return _xfs; }
    @property int yfs() const { return _yfs; }

    // these two are slow, consider frame_exists() instead
    // or lock the Cutbit's underlying Allegro bitmap yourself
    AlCol get_pixel(int px, int py)                 const;
    AlCol get_pixel(int fx, int fy, int px, int py) const;

/*  bool frame_exists(in int fx, in int fy) const;
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
 *
 *  void draw_directly_to_screen(x, y, xf, yf)
 *
 *      This should only be used by the mouse cursor, which draws even on top
 *      of the gui torbit. Rotation, mirroring, and scaling is not offered.
 */

private:

    Albit bitmap;

    int _xl;
    int _yl;
    int _xfs; // number of x-frames existing: xf in the interval [0, _xfs[
    int _yfs; // number of y-frames existing

    Matrix!bool existing_frames;

    void cut_bitmap();



public:

this(in Cutbit cb)
{
    if (! cb) return;
    _xl = cb._xl;
    _yl = cb._yl;
    _xfs = cb._xfs;
    _yfs = cb._yfs;
    existing_frames = new Matrix!bool(cb.existing_frames);

    if (cb.bitmap) {
        bitmap = albit_create(al_get_bitmap_width (cast (Albit) cb.bitmap),
                              al_get_bitmap_height(cast (Albit) cb.bitmap));
        mixin(temp_target!"bitmap");
        al_draw_bitmap(cast (Albit) cb.bitmap, 0, 0, 0);
        assert(bitmap);
    }
}



this(Albit bit, const bool cut = true)
{
    bitmap = bit;
    if (! bitmap) return;

    if (cut) cut_bitmap();
    else {
        _xl = al_get_bitmap_width (bitmap);
        _yl = al_get_bitmap_height(bitmap);
        _xfs = 1;
        _yfs = 1;

        existing_frames = new Matrix!bool(1, 1);
        existing_frames.set(0, 0, true);
    }
}



this(const Filename fn, const bool cut = true)
{
    // Try loading the file. If not found, don't crash, but make a log entry.
    bitmap = al_load_bitmap(fn.rootful_z);
    if (! bitmap) {
        Log.log("Missing image: " ~ fn.rootless);
        this();
    }
    else {
        al_convert_mask_to_alpha(bitmap, color.pink);
        this(bitmap, cut);
    }
}



this(Albit[] manybits)
{
    assert (false, "this(Albit[] many bitmaps) not yet implemented");
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
        assert (al_get_bitmap_width (cast (Albit) bitmap) >= _xl);
        assert (al_get_bitmap_height(cast (Albit) bitmap) >= _yl);
        assert (existing_frames !is null);
    }
    else {
        assert (_xl == 0);
        assert (_yl == 0);
        assert (_xfs == 0);
        assert (_yfs == 0);
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
        for (_xl = 2; _xl < x_max; ++_xl) {
            if (al_get_pixel(bitmap, _xl, 1) == c) {
                --_xl;
                break;
            }
        }
        for (_yl = 2; _yl < y_max; ++_yl) {
            if (al_get_pixel(bitmap, 1, _yl) == c) {
                --_yl;
                break;
            }
        }

        // don't cut the bitmap if at most 1-by-1 frame is possible
        if (_xl * 2 > x_max && _yl * 2 > y_max) {
            _xl = x_max;
            _yl = y_max;
            _xfs = 1;
            _yfs = 1;
        }
        // ...otherwise compute the number of frames in each direction
        else {
            for (_xfs = 0; (_xfs+1)*(_xl+1) < x_max; ++_xfs) {}
            for (_yfs = 0; (_yfs+1)*(_yl+1) < y_max; ++_yfs) {}
        }
    }

    // no frame apparent in the top left 2x2 block of pixels
    else {
        _xl = x_max;
        _yl = y_max;
        _xfs = 1;
        _yfs = 1;
    }

    // done cutting, now generate matrix. The bitmap is still locked.
    existing_frames = new Matrix!bool(_xfs, _yfs);
    if (_xfs == 1 && _yfs == 1) {
        existing_frames.set(0, 0, true);
    }
    else {
        for (int yf = 0; yf < _yfs; ++yf)
         for (int xf = 0; xf < _xfs; ++xf) {
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
    if  (fx < 0 || fy < 0 || fx >= _xfs || fy >= _yfs
     ||  px < 0 || py < 0 || px >= _xl  || py >= _yl) {
        return color.bad;
    }
    // otherwise, return the found color
    else if (_xfs == 1 && _yfs == 1)
         return al_get_pixel(cast (Albit) bitmap, px, py);
    else return al_get_pixel(cast (Albit) bitmap, fx * (_xl+1) + 1 + px,
                                                  fy * (_yl+1) + 1 + py);
}



bool frame_exists(in int fx, in int fy) const
{
    if (fx < 0 || fx >= _xfs
     || fy < 0 || fy >= _yfs) return false;
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
    mixin(temp_target!"torbit.albit");
    draw_text(djvu_s, str, x, y, col);
}



// this is used by the first draw(), and by draw_directly_to_screen()
private Albit
create_sub_bitmap_for_frame(
    in int xf, in int yf,
    in int xec = 0, // extra cutting from top or left
    in int yec = 0) const
in {
    assert (xf >= 0 && xf < _xfs);
    assert (yf >= 0 && yf < _yfs);
    assert (xec >= 0 && xec < _xl); // _xl, _yl are either all the bitmap, or
    assert (yec >= 0 && yec < _xl); // the size of a single frame without grid
}
body {
    // Create a sub-bitmap based on the wanted frames. If (Cutbit this)
    // doesn't have frames, don't compute +1 for the outermost frame.
    if (_xfs == 1 && _yfs == 1)
        return al_create_sub_bitmap(cast (Albit) bitmap,
         xec, yec, _xl - xec, _yl - yec);
    else
        return al_create_sub_bitmap(cast (Albit) bitmap,
         1 + xf * (_xl+1) + xec,
         1 + yf * (_yl+1) + yec,
         _xl - xec, _yl - yec);
}



void draw(
    Torbit       target_torbit,
    const int    x = 0,
    const int    y = 0,
    const int    xf = 0,
    const int    yf = 0,
    const bool   mirr = false,
    const double rot  = 0,
    const double scal = 0) const
{
    assert (target_torbit, "trying to draw onto null torbit");
    Albit target = target_torbit.albit;

    if (bitmap && xf >= 0 && yf >= 0 && xf < _xfs && yf < _yfs) {
        Albit sprite = create_sub_bitmap_for_frame(xf, yf);
        scope (exit) al_destroy_bitmap(sprite);
        target_torbit.draw_from(sprite, x, y, mirr, rot, scal);
    }
    // no frame inside the cutbit has been specified, or the cutbit
    // has a null bitmap
    else {
        draw_missing_frame_error(target_torbit, x, y, xf, yf);
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
    assert (target_torbit, "trying to draw onto null torbit");

    if (! bitmap) {
        draw_missing_frame_error(target_torbit, x, y, 0, 0);
        return;
    }
    // only one frame allowed, so we don't have to make sub-bitmaps
    assert (_xfs == 1);
    assert (_yfs == 1);

    rot = basics.help.positive_mod(rot, 4);
    assert (rot >= 0 || rot < 4);

    final switch (mode) {

    case Mode.NORMAL:
        // this is very much like the other draw function
        target_torbit.draw_from(cast (Albit) bitmap, x, y, mirr, rot * 1.0f);
        break;

    case Mode.DARK:
    case Mode.DARK_EDITOR:
        // the Torbit will know what to lock for best speed, so we have
        // moved the implementation there. Here, we only choose the color.
        target_torbit.draw_dark_from(cast (Albit) bitmap, x, y, mirr, rot,
            mode == Mode.DARK ? color.transp : color.gui_sha);
        break;

    case Mode.NOOW: {
        immutable invert_lengths = (rot % 2 == 1);
        Torbit excerpt = new Torbit(
            invert_lengths ? _yl : _xl,
            invert_lengths ? _xl : _yl);
        excerpt.clear_to_color(color.transp);
        excerpt.draw_from(cast (Albit) bitmap, 0, 0, mirr, rot);
        target_torbit.draw_to  (excerpt.albit, x, y);
        target_torbit.draw_from(excerpt.albit, x, y);
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



void
draw_directly_to_screen(in int x, in int y, in int xf = 0, in int yf = 0) const
{
    assert (display);
    if (xf < 0 || xf >= _xfs
     || yf < 0 || yf >= _yfs) return;

    Albit backbuffer = al_get_backbuffer(display);
    mixin(temp_target!"backbuffer");

    // usually, select only the correct frame. If we'd draw off the screen
    // to the left or top, instead do extra cutting by passing > 0 to the
    // latter two args.
    Albit sprite = create_sub_bitmap_for_frame(xf, yf, max(-x, 0), max(-y, 0));
    scope (exit) al_destroy_bitmap(sprite);

    al_draw_bitmap(sprite, max(0, x), max(0, y), 0);
}
// end function draw_directly_to_screen()

}
// end class
