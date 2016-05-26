module tile.abstile;

/* AbstractTile: Represents a single tile, may it be terrain or gadget,
 * loaded from the image directory. This has subclasses for terrain tiles
 * and for gadget tiles. When you have 10 bricks in the level that all look
 * the same, you have one Tile, but 10 Occurrences.
 *
 * We don't dispose the cutbit at end of program right now.
 * If you ever decide that exiting without cleaning the garbage is
 * a bad idea, you might want to re-introduce dispose() and destroy
 * the cutbit's image. A Tile owns its Cutbit.
 *
 * Tile was named Object in C++/A4 Lix. Object is not only the base class
 * in D that gets inherited by all classes, but it's a horrible name for
 * a non-universal class in general. Tile is a splendid name instead.
 */

import std.algorithm;

import basics.rect;
import graphic.color;
import graphic.cutbit;

abstract class AbstractTile {
private:
    Cutbit _cb;
    Rect _selbox; // Smallest rectangle, relative to the cutbit's (0, 0),
                  // that still contains all nontransparent pixels.
public:
          @property const(Cutbit) cb() const { return _cb;     }
    final @property Rect      selbox() const { return _selbox; }

protected:
    this(Cutbit aCb) { assert (aCb); _cb = aCb; } // take ownership
    void findSelboxAssumeLocked() { _selbox = .findSelboxAssumeLocked(_cb); }
}

// Call this only while the cutbit is locked in memory for reading!
// Otherwise, the pixels will be fetched from VRAM one by one, which
// is insanely slow. This should be called once during subclass this().
Rect findSelboxAssumeLocked(in Cutbit cb)
{
    assert (cb);
    Rect selbox;
    selbox.x = cb.xl; // Initializing the selbox with the smallest
    selbox.y = cb.yl; // selbox possible, starting at the wrong ends
    for (int xf = 0; xf < cb.xfs; ++xf)
        for (int yf = 0; yf < cb.yfs; ++yf) {
            int  xMin = -1;
            int  xMax = cb.xl;
            int  yMin = -1;
            int  yMax = cb.yl;

            WHILE_X_MAX: while (xMax >= 0) {
                xMax -= 1;
                for (Point p = Point(xMax, 0); p.y < cb.yl; p.y += 1)
                    if (cb.get_pixel(xf, yf, p) != color.transp)
                        break WHILE_X_MAX;
            }
            WHILE_X_MIN: while (xMin < xMax) {
                xMin += 1;
                for (Point p = Point(xMin, 0); p.y < cb.yl; p.y += 1)
                    if (cb.get_pixel(xf, yf, p) != color.transp)
                        break WHILE_X_MIN;
            }
            WHILE_Y_MAX: while (yMax >= 0) {
                yMax -= 1;
                for (Point p = Point(0, yMax); p.x < cb.xl; p.x += 1)
                    if (cb.get_pixel(xf, yf, p) != color.transp)
                        break WHILE_Y_MAX;
            }
            WHILE_Y_MIN: while (yMin < yMax) {
                yMin += 1;
                for (Point p = Point(0, yMin); p.x < cb.xl; p.x += 1)
                    if (cb.get_pixel(xf, yf, p) != color.transp)
                        break WHILE_Y_MIN;
            }
            selbox.x  = min(selbox.x,  xMin);
            selbox.y  = min(selbox.y,  yMin);
            selbox.xl = max(selbox.xl, xMax - xMin + 1);
            selbox.yl = max(selbox.yl, yMax - yMin + 1);
        }
    return selbox;
}
