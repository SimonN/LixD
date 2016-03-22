module tile.platonic;

/* Platonic Tile
 *
 * We don't dispose the cutbit at end of program right now.
 * If you ever decide that exiting without cleaning the garbage is
 * a bad idea, you might want to re-introduce dispose() and destroy
 * the cutbit's image.
 */

import std.algorithm;

import basics.rect;
import graphic.color;
import graphic.cutbit;

class Platonic {
private:
    Cutbit _cb;
    Rect _selbox; // Smallest rectangle, relative to the cutbit's (0, 0),
                  // that still contains all nontransparent pixels.

public:
          @property const(Cutbit) cb() const { return _cb;     }
    final @property Rect      selbox() const { return _selbox; }

protected:
    this(Cutbit aCb)
    {
        assert (aCb);
        _cb = aCb; // take ownership
    }

    // Call this only while the cutbit is locked in memory for reading!
    // Otherwise, the pixels will be fetched from VRAM one by one, which
    // is insanely slow. This should be called once during subclass this().
    void findSelboxAssumeLocked()
    {
        assert (cb);
        _selbox.x = cb.xl; // Initializing the selbox with the smallest
        _selbox.y = cb.yl; // selbox possible, starting at the wrong ends
        for (int xf = 0; xf < cb.xfs; ++xf)
            for (int yf = 0; yf < cb.yfs; ++yf) {
                int  xMin = -1;
                int  xMax = cb.xl;
                int  yMin = -1;
                int  yMax = cb.yl;

                WHILE_X_MAX: while (xMax >= 0) {
                    xMax -= 1;
                    for (int y = 0; y < cb.yl; y += 1)
                        if (cb.get_pixel(xf, yf, xMax, y) != color.transp)
                            break WHILE_X_MAX;
                }
                WHILE_X_MIN: while (xMin < xMax) {
                    xMin += 1;
                    for (int y = 0; y < cb.yl; y += 1)
                        if (cb.get_pixel(xf, yf, xMin, y) != color.transp)
                            break WHILE_X_MIN;
                }
                WHILE_Y_MAX: while (yMax >= 0) {
                    yMax -= 1;
                    for (int x = 0; x < cb.xl; x += 1)
                        if (cb.get_pixel(xf, yf, x, yMax) != color.transp)
                            break WHILE_Y_MAX;
                }
                WHILE_Y_MIN: while (yMin < yMax) {
                    yMin += 1;
                    for (int x = 0; x < cb.xl; x += 1)
                        if (cb.get_pixel(xf, yf, x, yMin) != color.transp)
                            break WHILE_Y_MIN;
                }
                _selbox.x  = min(_selbox.x,  xMin);
                _selbox.y  = min(_selbox.y,  yMin);
                _selbox.xl = max(_selbox.xl, xMax - xMin + 1);
                _selbox.yl = max(_selbox.yl, yMax - yMin + 1);
            }
    }
}
