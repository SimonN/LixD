module graphic.cutbit;

import std.algorithm; // max(-x, 0) in drawDirectlyToScreen()
import std.exception : assumeUnique;
import std.string; // format

public import basics.rect;

import basics.alleg5;
import basics.help; // positiveMod
import basics.matrix; // which frames exist?
import graphic.color;
import graphic.torbit;
import gui; // strange, but we'll write error message instead of drawing bitmap
import file.filename;
import file.language;
import file.log; // log bad filename when trying to load a bitmap

/*
 * These were member functions, but should work even for null Cutbits.
 * Often, we do things only if the cutbit is not null and its bitmap exists.
 */
pure nothrow @nogc {
    bool valid(in Cutbit cb) @safe { return cb && cb.bitmap; }

    inout(Albit) albit(inout Cutbit cb)
    {
        return cb ? cast(inout Albit) cb.bitmap : null;
    }
}

final class Cutbit { // Final keyword only for speed. Remove as needed.
private:
    Albit bitmap;
    CutResult _cutting;
    immutable(Matrix!bool) _existingFramesOrNullIfAllExist;

public:
    enum Cut : bool { no = false, ifGridExists = true }

    this(Cutbit cb)
    {
        if (! cb) {
            return;
        }
        _cutting = cb._cutting;
        _existingFramesOrNullIfAllExist = cb._existingFramesOrNullIfAllExist;
        if (cb.bitmap) {
            bitmap = albitCreate(al_get_bitmap_width (cb.bitmap),
                                 al_get_bitmap_height(cb.bitmap));
            auto target = TargetBitmap(bitmap);
            al_draw_bitmap(cast (Albit) cb.bitmap, 0, 0, 0);
            assert(bitmap);
        }
    }

    // Takes ownership of the argument bitmap!
    this(Albit bit, in Cut cut)
    {
        bitmap = bit;
        if (! bitmap)
            return;
        if (cut == Cut.ifGridExists) {
            auto lock = LockReadOnly(bitmap);
            _cutting = cutIntoFrames_AssumesReadLocked(bitmap);
            _existingFramesOrNullIfAllExist = makeMatrix_AssumesReadLocked();
        }
        else {
            _cutting = CutResult(1, 1,
                al_get_bitmap_width (bitmap),
                al_get_bitmap_height(bitmap));
            _existingFramesOrNullIfAllExist = null;
        }
    }

    this(const Filename fn, in Cut cut)
    {
        // Try loading the file. If not found, don't crash, but log.
        bitmap = al_load_bitmap(fn.stringForReading.toStringz);
        if (bitmap) {
            bitmap.convertPinkToAlpha();
        }
        this(bitmap, cut);
    }

    ~this() { dispose(); }

    void dispose()
    {
        if (bitmap) {
            albitDestroy(bitmap);
            bitmap = null;
        }
    }

    bool opEquals(const Cutbit rhs) const { return bitmap == rhs.bitmap; }

    const pure nothrow @safe @nogc {
        // get size of a single frame, not necessarily size of entire bitmap
        int xl() { return _cutting.xl;  }
        int yl() { return _cutting.yl;  }
        Point len() { return Point(_cutting.xl, _cutting.yl); }
        int xfs() { return _cutting.xfs; }
        int yfs() { return _cutting.yfs; }
    }

    // These two are slow, consider frameExists() instead
    // or lock the Cutbit's underlying Allegro bitmap yourself.
    Alcol get_pixel(in Point pixel) const { return get_pixel(0, 0, pixel); }
    Alcol get_pixel(int fx, int fy, in Point p) const
    {
        // frame doesn't exist, or pixel doesn't exist in the frame
        if (fx < 0 || fy  < 0 || fx >= _cutting.xfs || fy >= _cutting.yfs
            || p.x < 0 || p.y < 0 || p.x >= _cutting.xl || p.y >= _cutting.yl
        ) {
            return color.bad;
        }
        // otherwise, return the found color
        else if (_cutting.xfs == 1 && _cutting.xfs == 1)
             return al_get_pixel(cast (Albit) bitmap, p.x, p.y);
        else return al_get_pixel(cast (Albit) bitmap,
            fx * (_cutting.xl + 1) + 1 + p.x,
            fy * (_cutting.yl + 1) + 1 + p.y);
    }

    // Checks whether the given frame contains interesting image data,
    // instead of being marked as nonexistant by being filled with the
    // already-detected frame/grid color.
    // This is very fast, it uses the cached data in RAM. It's much better
    // to consult this instead of querying for pixels later inside frames.
    bool frameExists(in int fx, in int fy) const
    {
        if (fx < 0 || fx >= _cutting.xfs || fy < 0 || fy >= _cutting.yfs) {
            return false;
        }
        if (_existingFramesOrNullIfAllExist is null) {
            return true;
        }
        return _existingFramesOrNullIfAllExist.get(fx, fy);
    }

    // Intended for free-form drawing without effect on land.
    // Interactive objects and the flying pickaxe are drawn with this.
    // (rot) (either int or double) means how many ccw quarter turns.
    // (scal) can be set to 0 or 1 when one doesn't wish to rescale. 0 is fast
    void draw(
        const Point  targetCorner = Point(0, 0),
        const int    xf = 0,
        const int    yf = 0,
        const bool   mirr = false,
        const double rot  = 0,
        const double scal = 0) const
    {
        if (bitmap && xf >= 0 && yf >= 0
            && xf < _cutting.xfs && yf < _cutting.yfs
        ) {
            Albit sprite = create_sub_bitmap_for_frame(xf, yf);
            scope (exit)
                albitDestroy(sprite);
            sprite.drawToTargetTorbit(targetCorner, mirr, rot, scal);
        }
        // no frame inside the cutbit has been specified, or the cutbit
        // has a null bitmap
        else {
            drawMissingFrameError(targetCorner, xf, yf);
        }
    }

    // This should only be used by the mouse cursor, which draws even on top
    // of the gui torbit. Rotation, mirroring, and scaling is not offered.
    void drawToCurrentAlbitNotTorbit(in Point targetCorner,
        in int xf = 0, in int yf = 0) const
    {
        if (! bitmap || xf < 0 || xf >= _cutting.xfs
                     || yf < 0 || yf >= _cutting.yfs
        ) {
            drawMissingFrameError(targetCorner, xf, yf);
            return;
        }
        // usually, select only the correct frame. If we'd draw off the screen
        // to the left or top, instead do extra cutting by passing > 0 to the
        // latter two args.
        Albit sprite = create_sub_bitmap_for_frame(xf, yf,
            max(-targetCorner.x, 0), max(-targetCorner.y, 0));
        scope (exit)
            albitDestroy(sprite);
        al_draw_bitmap(sprite, max(0, targetCorner.x),
                               max(0, targetCorner.y), 0);
    }

private:
    void drawMissingFrameError(in Point toCorner, in int fx, in int fy) const
    {
        string str = "File N/A";
        Alcol col = color.cbBadBitmap;
        if (bitmap) {
            str = format("(%d,%d)", fx, fy);
            col = color.cbBadFrame;
        }
        drawText(djvuS, str, toCorner.x, toCorner.y, col);
    }

    // this is used by the first draw(), and by drawDirectlyToScreen()
    Albit create_sub_bitmap_for_frame(
        in int xf, in int yf,
        in int xec = 0, // extra cutting from top or left
        in int yec = 0) const
    in {
        assert (xf >= 0 && xf < _cutting.xfs);
        assert (yf >= 0 && yf < _cutting.yfs);
        assert (xec >= 0 && xec < _cutting.xl);
        assert (yec >= 0 && yec < _cutting.xl);
    }
    do {
        // Create a sub-bitmap based on the wanted frames. If (Cutbit this)
        // doesn't have frames, don't compute +1 for the outermost frame.
        if (_cutting.xfs == 1 && _cutting.yfs == 1)
            return al_create_sub_bitmap(cast (Albit) bitmap,
             xec, yec, _cutting.xl - xec, _cutting.yl - yec);
        else
            return al_create_sub_bitmap(cast (Albit) bitmap,
             1 + xf * (_cutting.xl + 1) + xec,
             1 + yf * (_cutting.yl + 1) + yec,
             _cutting.xl - xec,
             _cutting.yl - yec);
    }

    immutable(Matrix!bool) makeMatrix_AssumesReadLocked() // may return null
    {
        if (_cutting.xfs == 1 && _cutting.yfs == 1) {
            return null;
        }
        immutable Point corner = Point(0, 0);
        immutable Alcol frameColor = al_get_pixel(bitmap, 0, 0);
        for (int yf = 0; yf < _cutting.yfs; ++yf) {
            for (int xf = 0; xf < _cutting.xfs; ++xf) {
                if (get_pixel(xf, yf, corner) == frameColor) {
                    return makeNonzeroMatrix_AssumesReadLocked();
                }
            }
        }
        return null;
    }

    immutable(Matrix!bool) makeNonzeroMatrix_AssumesReadLocked()
    {
        Matrix!bool[1] ret; // Because assumeUnique will only work on arrays.
        ret[0] = new Matrix!bool(_cutting.xfs, _cutting.yfs);
        immutable Point corner = Point(0, 0);
        immutable Alcol frameColor = al_get_pixel(bitmap, 0, 0);
        for (int yf = 0; yf < _cutting.yfs; ++yf) {
            for (int xf = 0; xf < _cutting.xfs; ++xf) {
                ret[0].set(xf, yf, get_pixel(xf, yf, corner) != frameColor);
            }
        }
        return ret.assumeUnique[0];
    }
}

struct CutResult {
    int xfs; // x-frames: Number of frames horiz. next to each other, >= 1
    int yfs; // y-frames: Number of frames vertically under each other, >= 1
    int xl; // Width of a single frame. If xf == yf == 1, it's bitmap->w.
    int yl; // Height of a single frame. If xf == yf == 1, it's bitmap->w.
}

CutResult cutIntoFrames_AssumesReadLocked(Albit bitmap) @nogc
{
    immutable int xMax = al_get_bitmap_width (bitmap);
    immutable int yMax = al_get_bitmap_height(bitmap);
    if (xMax <= 1 || yMax <= 1) {
        return CutResult(1, 1, xMax, yMax);
    }
    // Cut a bitmap into frames, check the top left 2x2 block. The three
    // pixels of it touching the edge shall be of one color, and the inner
    // pixel must be of a different color, to count as a frame grid.
    immutable Alcol c = al_get_pixel(bitmap, 0, 0);
    if (   al_get_pixel(bitmap, 0, 1) != c
        || al_get_pixel(bitmap, 1, 0) != c
        || al_get_pixel(bitmap, 1, 1) == c
    ) {
        // no frame apparent in the top left 2x2 block of pixels
        return CutResult(1, 1, xMax, yMax);
    }
    // find the end of the first frame in each direction
    immutable int xl = () {
        for (int x = 2; x < xMax; ++x)
            if (al_get_pixel(bitmap, x, 1) == c)
                return x - 1;
        return xMax;
    }();
    immutable int yl = () {
        for (int y = 2; y < yMax; ++y)
            if (al_get_pixel(bitmap, 1, y) == c)
                return y - 1;
        return yMax;
    }();
    immutable xf = max(1, (xMax - 1) / (xl + 1));
    immutable yf = max(1, (yMax - 1) / (yl + 1));
    return (xf > 1 || yf > 1)
        ? CutResult(xf, yf, xl, yl)
        : CutResult(1, 1, xMax, yMax);
}
