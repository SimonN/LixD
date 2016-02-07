module tile.platonic;

/* Platonic Tile
 *
 * We don't dispose the cutbit at end of program right now.
 * If you ever decide that exiting without cleaning the garbage is
 * a bad idea, you might want to re-introduce dispose() and destroy
 * the cutbit's image.
 */

import std.algorithm;

import graphic.color;
import graphic.cutbit;

class Platonic {
private:
    Cutbit _cb;
    int _selboxX;  // These coordinates locate the smallest rectangle inside
    int _selboxY;  // the object's cutbit's frame (0, 0) that still holds all
    int _selboxXl; // nontransparent pixels. This refines the selection
    int _selboxYl; // with a pulled selection rectangle in the Editor.

public:
    @property const(Cutbit) cb() const { return _cb; }
    final @property selboxX()    const { return _selboxX;  }
    final @property selboxY()    const { return _selboxY;  }
    final @property selboxXl()   const { return _selboxXl; }
    final @property selboxYl()   const { return _selboxYl; }

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
        _selboxX = cb.xl; // Initializing the selbox with the smallest
        _selboxY = cb.yl; // selbox possible, starting at the wrong ends
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
                _selboxX  = min(_selboxX,  xMin);
                _selboxY  = min(_selboxY,  yMin);
                _selboxXl = max(_selboxXl, xMax - xMin + 1);
                _selboxYl = max(_selboxYl, yMax - yMin + 1);
            }
    }
}
