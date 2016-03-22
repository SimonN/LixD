module graphic.map;

/* (class Map : Torbit) has a camera pointing somewhere inside the entire
 * torbit. The camera specifies the center of a rectangle. This rectangle
 * has an immutable size cameraXl and cameraYl.
 */

import std.algorithm;
import std.range;

import basics.alleg5;
import basics.help;
import basics.topology;
import graphic.color;
import graphic.torbit;

static import basics.user;
static import hardware.display;
static import hardware.keyboard;
static import hardware.mouse;

class Map : Torbit {

/*  this(in int xl, int yl, int srceen_xl, int screen_yl)
 *
 *      Deduct from the real screen xl/yl the GUI elements' yl, then pass the
 *      remainder to this constructor.
 */
    @property bool scrollableUp()   const { return _cameraY > minY || torusY; }
    @property bool scrollableRight()const { return _cameraX < maxX || torusX; }
    @property bool scrollableLeft() const { return _cameraX > minX || torusX; }
    @property bool scrollableDown() const { return _cameraY < maxY || torusY; }

    @property bool scrollable() const
    {
        return scrollableUp()   || scrollableDown()
            || scrollableLeft() || scrollableRight();
    }

    @property bool scrollingNow() const { return scrollingContinues;}
    @property int  cameraXl()     const { return _cameraXl; }
    @property int  cameraYl()     const { return _cameraYl; }

/* New and exciting difference to A4/C++ Lix:
 * screen_x/y point to the center of the visible area. This makes computing
 * zoom easier, and copying the resulting viewed area is encapsulated in
 * draw() anyway.
 */
    @property int  cameraX() const { return _cameraX; }
    @property int  cameraY() const { return _cameraY; }
    void set_cameraXY(in int x, in int y) { cameraX = x; cameraY = y; }

    @property int zoom() const { return _zoom; }

private:

    immutable int _cameraXl;
    immutable int _cameraYl;

    int  _cameraX;
    int  _cameraY;

    int  _zoom;

    int  scrollGrabbedX;
    int  scrollGrabbedY;

    bool scrollingStarts;
    bool scrollingContinues;

    @property int divByZoom(int i) const
    {
        assert (i >= 0);
        return (i + _zoom - 1) / _zoom;
    }

    // these two don't crop at the edge yet
    @property int cameraZoomedXl() const { return divByZoom(_cameraXl); }
    @property int cameraZoomedYl() const { return divByZoom(_cameraYl); }

    @property int minX() const { return cameraZoomedXl / 2; }
    @property int minY() const { return cameraZoomedYl / 2; }
    @property int maxX() const { return xl - cameraZoomedXl + minX; }
    @property int maxY() const { return yl - cameraZoomedYl + minY; }
    // Why not simply maxX = xl - minX? If cameraZoomedXl is odd, dividing
    // by 2 discards length, and we want (maxX - minX) == cameraZoomedXl
    // exactly. This prevents scrolling too far on strong zoom.



public:

this(in Topology topology, in int a_cameraXl, in int a_cameraYl)
{
    assert (a_cameraXl > 0);
    assert (a_cameraYl > 0);
    super(topology);
    _cameraXl = a_cameraXl;
    _cameraYl = a_cameraYl;
    _zoom = 1;
    cameraX  = _cameraXl / 2;
    cameraY  = _cameraYl / 2;
}

invariant()
{
    assert (_zoom > 0);
}



private int cameraSetter(ref int camera, in int newCamera, in bool torus,
                         in int torbitLength, in int min, in int max)
{
    camera = newCamera;
    if (torus) {
        camera = basics.help.positiveMod(camera, torbitLength);
    }
    else if (min >= max) {
        // this can happen on very small maps
        camera = torbitLength / 2;
    }
    else {
        if (camera < min) camera = min;
        if (camera > max) camera = max;
    }
    return camera;
}

@property int
cameraX(in int a)
{
    return cameraSetter(_cameraX, a, torusX, xl, minX, maxX);
}

@property int
cameraY(in int a)
{
    return cameraSetter(_cameraY, a, torusY, yl, minY, maxY);
}

void centerOnAverage(Rx, Ry)(Rx rangeX, Ry rangeY)
    if (isInputRange!Rx && isInputRange!Ry)
{
    cameraX = super.torusAverageX(rangeX);
    cameraY = super.torusAverageY(rangeY);
}

// By how much is the camera larger than the map?
// These are 0 on torus maps, only > 0 for small non-torus maps.
// If something > 0 is returned, we will draw a dark border around the level.
// The border is split into two equally thick sides in the x direction.
private @property int borderOneSideXl() const
{
    if (torusX || xl * zoom >= cameraXl)
        return 0;
    return (_cameraXl - xl * _zoom) / 2;
}

private @property int borderUpperSideYl() const
{
    if (torusY || yl * zoom >= cameraYl)
        return 0;
    return _cameraYl - yl * _zoom;
}

@property Point
mouseOnLand() const
{
    pure int f(
        ref const(int) camera, in int torbitL, in int torus,
        in int borderL,
        in int min, in int mousePos
    ) {
        immutable int firstDrawnPixel   = (borderL > 0) ? 0 : (camera - min);
        immutable int mouseOffsetOnLand = (mousePos - borderL) / _zoom;
        immutable int ret               = firstDrawnPixel + mouseOffsetOnLand;
        if (torus) {
            assert (borderL == 0);
            return basics.help.positiveMod(ret, torbitL);
        }
        return ret;
    }
    return Point(
        f(_cameraX, xl, torusX, borderOneSideXl, minX, hardware.mouse.mouseX),
        f(_cameraY, yl, torusY, borderUpperSideYl,minY,hardware.mouse.mouseY));
}

@property int
zoom(in int z)
{
    assert (z > 0);
    _zoom = z;
    cameraX = _cameraX; // move back onto visible area if we have zoomed out
    cameraY = _cameraY;
    return _zoom;
}



void
calcScrolling()
{
    if (! scrollable) {
        scrollingStarts = false;
        scrollingContinues = false;
        return;
    }

    if (basics.user.scrollEdge) {
        int scrd = basics.user.scrollSpeedEdge;
        if (hardware.mouse.mouseHeldRight())
            scrd *= 4;
        if (_zoom > 1) {
            scrd += _zoom - 1;
            scrd /= _zoom;
        }
        if (scrd < 1)
            scrd = 1;
        immutable edgeR = hardware.display.displayXl - 1;
        immutable edgeU = hardware.display.displayYl - 1;
        // we don't care about this.mouseX/y, because we want to scroll
        // at the edge of the screen, not the edge of the map
        if (hardware.mouse.mouseY() == 0)     cameraY = _cameraY - scrd;
        if (hardware.mouse.mouseX() == edgeR) cameraX = _cameraX + scrd;
        if (hardware.mouse.mouseY() == edgeU) cameraY = _cameraY + scrd;
        if (hardware.mouse.mouseX() == 0)     cameraX = _cameraX - scrd;
    }

    // scrolling with held right/middle mouse button
    bool scrollNow =
           (hardware.mouse.mouseHeldRight()  && basics.user.scrollRight)
        || (hardware.mouse.mouseHeldMiddle() && basics.user.scrollMiddle)
        ||  hardware.keyboard.keyHeld(basics.user.keyScroll);
    scrollingStarts    = scrollNow && ! scrollingContinues;
    scrollingContinues = scrollNow;

    if (scrollingStarts) {
        // remember old position of the mouse
        scrollGrabbedX = hardware.mouse.mouseX();
        scrollGrabbedY = hardware.mouse.mouseY();
    }
    if (scrollingContinues) {
        int clickScrollingOneDimension(in bool minus, in bool plus,
            in int grabbed, in int mouse, in int mickey, in int cameraCurrent,
            void function() freeze
        ) {
            int ret = cameraCurrent;
            if (   (minus && mouse <= grabbed && mickey < 0)
                || (plus  && mouse >= grabbed && mickey > 0)
            ) {
                ret += mickey * basics.user.scrollSpeedClick / _zoom
                    / 4; // the factor /4 comes from C++ Lix
                freeze();
            }
            return ret;
        }
        cameraX = clickScrollingOneDimension(scrollableLeft, scrollableRight,
            scrollGrabbedX, hardware.mouse.mouseX, hardware.mouse.mouseMickeyX,
            _cameraX, &hardware.mouse.freezeMouseX);

        cameraY = clickScrollingOneDimension(scrollableUp, scrollableDown,
            scrollGrabbedY, hardware.mouse.mouseY, hardware.mouse.mouseMickeyY,
            _cameraY, &hardware.mouse.freezeMouseY);
    }
    // end right-click scrolling
}
// end calcScrolling()



// ############################################################################
// ########################################################### drawing routines
// ############################################################################



void
drawCamera() // ...onto the current drawing target, most likely the screen
{
    immutable overallMaxX = _cameraXl - borderOneSideXl;

    for (int x = borderOneSideXl; x < overallMaxX; x += xl * _zoom) {
        for (int y = borderUpperSideYl; y < _cameraYl; y += yl * _zoom) {
            // maxXl, maxYl describe the size of the image to be drawn
            // in this iteration of the double-for loop. This should always
            // be as much as possible, i.e., the first argument to min().
            // Only in the last iteration of the loop,
            // a smaller rectangle is better.
            immutable int maxXl = min(xl * _zoom, overallMaxX - x);
            immutable int maxYl = min(yl * _zoom, _cameraYl   - y);
            drawCamera_with_target_corner(x, y, maxXl, maxYl);
            if (borderUpperSideYl != 0) break;
        }
        if (borderOneSideXl != 0) break;
    }

    // To tell apart air from areas outside of the map, color screen borders.
    void draw_border(in int ax, in int ay, in int axl, in int ayl)
    {
        // we assume the correct target bitmap is set.
        // D/A5 Lix doesn't make screen border coloring optional
        al_draw_filled_rectangle(ax, ay, ax + axl, ay + ayl,
                                 color.screenBorder);
    }
    if (borderOneSideXl > 0) {
        draw_border(0, 0, borderOneSideXl, cameraYl);
        draw_border(cameraXl - borderOneSideXl, 0, borderOneSideXl, cameraYl);
    }
    if (borderUpperSideYl > 0)
        draw_border(borderOneSideXl, 0, cameraXl - 2 * borderOneSideXl,
                                        borderUpperSideYl);
}

// This rectangle describes a portion of the source torbit, considering zoom.
private Rect cameraRectangle()
out (rect) {
    // The rectangle never wraps over a torus seam, but instead is cut off.
    // Callers who what to draw a full screen rectangle must compute the
    // remainder behind the seam themselves.
    assert (rect.x >= 0);
    assert (rect.y >= 0);
    assert (rect.x + rect.xl >= 0);
    assert (rect.y + rect.yl >= 0);
    assert (rect.x + rect.xl <= this.xl);
    assert (rect.y + rect.yl <= this.yl);
}
body {
    Rect rect;
    immutable int x_tmp = _cameraX - cameraZoomedXl / 2;
    immutable int y_tmp = _cameraY - cameraZoomedYl / 2;

    rect.x  = torusX ? positiveMod(x_tmp, this.xl) : max(x_tmp, 0);
    rect.y  = torusY ? positiveMod(y_tmp, this.yl) : max(y_tmp, 0);
    rect.xl = min(cameraZoomedXl, this.xl - rect.x);
    rect.yl = min(cameraZoomedYl, this.yl - rect.y);
    return rect;
}

private void
drawCamera_with_target_corner(
    in int tcx, // x coordinate of target corner
    in int tcy,
    in int maxTcxl, // length, away from (tcx, tcy). Draw at most this much
    in int maxTcyl  // to the target.
) {
    immutable r = cameraRectangle();
    // Source length of the non-wrapped portion. (Target len = this * zoom.)
    immutable sxl1 = min(r.xl, divByZoom(maxTcxl));
    immutable syl1 = min(r.yl, divByZoom(maxTcyl));
    // target corner coordinates and size of the wrapped-around torus portion
    immutable tcx2 = tcx + r.xl * _zoom;
    immutable tcy2 = tcy + r.yl * _zoom;
    // source length of the wrapped-around torus portion
    immutable sxl2 = min(cameraZoomedXl - r.xl, divByZoom(maxTcxl) - sxl1);
    immutable syl2 = min(cameraZoomedYl - r.yl, divByZoom(maxTcyl) - syl1);

    void blitOnce(in int sx,  in int sy,  // source x, y
                  in int sxl, in int syl, // length on the source
                  in int tx,  in int ty)  // start of the target
    {
        if (zoom == 1)
            al_draw_bitmap_region(albit, sx, sy, sxl, syl, tx, ty, 0);
        else
            al_draw_scaled_bitmap(albit, sx, sy, sxl,       syl,
                                         tx, ty, _zoom*sxl, _zoom*syl, 0);
    }
    immutable drtx = torusX && sxl2 > 0;
    immutable drty = torusY && syl2 > 0;
                      blitOnce(r.x, r.y, sxl1, syl1, tcx,  tcy);
    if (drtx        ) blitOnce(0,   r.y, sxl2, syl1, tcx2, tcy);
    if (        drty) blitOnce(r.x, 0,   sxl1, syl2, tcx,  tcy2);
    if (drtx && drty) blitOnce(0,   0,   sxl2, syl2, tcx2, tcy2);
}

void
loadCameraRect(in Torbit src)
{
    assert (src.albit);
    assert (this.xl == src.xl);
    assert (this.yl == src.yl);

    // We don't use a drawing delegate with the Torbit base cless.
    // That would be like stamping the thing 4x entirelly onto the torbit.
    // We might want to copy less than 4 entire stamps. Let's implement it.
    immutable Rect r = cameraRectangle();

    immutable bool drtx = torusX && r.xl < cameraZoomedXl;
    immutable bool drty = torusY && r.yl < cameraZoomedYl;

    auto drata = DrawingTarget(this.albit);

    void drawHere(int ax, int ay, int axl, int ayl)
    {
        al_draw_bitmap_region(cast (Albit) (src.albit),
            ax, ay, axl, ayl, ax, ay, 0);
    }
    if (true        ) drawHere(r.x, r.y, r.xl, r.yl);
    if (drtx        ) drawHere(0,   r.y, cameraZoomedXl - r.xl, r.yl);
    if (        drty) drawHere(r.x, 0,   r.xl, cameraZoomedYl - r.yl);
    if (drtx && drty) drawHere(0,   0,   cameraZoomedXl - r.xl,
                                         cameraZoomedYl - r.yl);
}

void
clearScreenRect(AlCol col)
{
    Rect r = cameraRectangle();
    r.xl = cameraZoomedXl;
    r.yl = cameraZoomedYl;
    this.drawFilledRectangle(r, col);
}

}
// end class Map
