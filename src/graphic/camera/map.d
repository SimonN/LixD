module graphic.camera.mapncam;

/* (class Map : Torbit) has a camera pointing somewhere inside the entire
 * torbit. The camera specifies the center of a rectangle.
 */

import std.algorithm;
import std.conv;
import std.math;
import std.range;

// Don't import all of alleg5, because that imports xl(Albit) which interferes
// with our (alias torbit this).xl.
import basics.alleg5 : al_draw_filled_rectangle, al_draw_bitmap_region,
                       al_draw_scaled_bitmap, Albit;
import basics.help;
import basics.topology;
import graphic.camera.camera;
import graphic.camera.zoom;
import graphic.color;
import graphic.torbit;

static import file.option;
static import hardware.display;
static import hardware.keyboard;
static import hardware.mouse;

class MapAndCamera {
private:
    Point _scrollGrabbed;
    bool _isHoldScrolling;
    bool _suggestTooltip;

    Camera _cam;

    // We have two ground torbits, because we must choose at their creation
    // whether we want nearest-neighbor scaling or blurry linear interpolation.
    Torbit _nearestNeighbor;
    Torbit _blurryScaling;

public:
    @property const pure {
        bool scrollable()
        {
            return _cam.mayScrollUp() || _cam.mayScrollDown()
                || _cam.mayScrollLeft() || _cam.mayScrollRight();
        }
        bool isHoldScrolling() { return _isHoldScrolling; }
        bool suggestHoldScrollingTooltip() { return _suggestTooltip; }
        float zoom() { return _cam.zoom; }
    }

    alias torbit this;
    @property inout(Torbit) torbit() inout pure
    {
        assert (_nearestNeighbor);
        assert (_blurryScaling);
        return _cam.preferNearestNeighbor ? _nearestNeighbor : _blurryScaling;
    }

/*
 * Deduct from the real screen xl/yl the GUI elements' yl, then pass the
 * remainder to this constructor.
 */
this(in Topology tp, in int aCameraXl, in int aCameraYl)
{
    _cam = new Camera(tp, Point(aCameraXl, aCameraYl));
    auto cfg = Torbit.Cfg(tp);
    _nearestNeighbor = new Torbit(cfg);
    cfg.smoothlyScalable = true;
    _blurryScaling = new Torbit(cfg);
}

void dispose()
{
    if (_nearestNeighbor) {
        _nearestNeighbor.dispose();
        _nearestNeighbor = null;
    }
    if (_blurryScaling) {
        _blurryScaling.dispose();
        _blurryScaling = null;
    }
}

// This function shall intercept calls to Torbit.resize.
void resize(in int newXl, in int newYl)
{
    if (xl == newXl && yl == newYl)
        // the Torbits would get no-op calls, but we shouldn't reset zoom.
        return;
    _nearestNeighbor.resize(newXl, newYl);
    _blurryScaling.resize(newXl, newYl);
    immutable Point oldFocus = _cam.focus;
    _cam = new Camera(torbit, Point(_cam.targetXl, _cam.targetYl));
    _cam.focus = oldFocus;
}

void centerOnAverage(Rx, Ry)(Rx rangeX, Ry rangeY)
    if (isInputRange!Rx && isInputRange!Ry)
{
    _cam.focus = Point(torusAverageX(rangeX), torusAverageY(rangeY));
}

void zoomIn() { _cam.zoomInKeepingSourcePointFixed(mouseOnLand); }
void zoomOut() { _cam.zoomOutKeepingSourcePointFixed(mouseOnLand); }
void zoomOutToSeeEntireMap() { _cam.zoomOutToSeeEntireSource(); }
void snapToBoundary() { _cam.snapToBoundary(); }

// By how much is the camera larger than the map?
// These are 0 on torus maps, only > 0 for small non-torus maps.
// If something > 0 is returned, we will draw a dark border around the level.
// The border is split into two equally thick sides in the x direction.
private @property int borderOneSideXl() const
{
    if (torusX || xl * zoom >= _cam.targetXl)
        return 0;
    return (_cam.targetXl - xl * zoom).ceil.roundInt / 2;
}

private @property int borderUpperSideYl() const
{
    if (torusY || yl * zoom >= _cam.targetYl)
        return 0;
    return (_cam.targetYl - yl * zoom).ceil.roundInt;
}

@property Point
mouseOnLand() const
{
    immutable Point mouseOnTarget = hardware.mouse.mouseOnScreen
        - Point(borderOneSideXl, borderUpperSideYl);
    return _cam.sourceOf(mouseOnTarget);
}

void calcScrolling()
{
    calcEdgeScrolling();
    calcHoldScrolling();
}

private void calcEdgeScrolling()
{
    _suggestTooltip = false;
    if (! scrollable || ! hardware.mouse.hardwareMouseInsideWindow
        || file.option.scrollSpeedEdge.value <= 0)
        return;

    float scrd = file.option.scrollSpeedEdge;
    if (hardware.mouse.mouseHeldRight())
        scrd *= 4;
    scrd /= zoom;
    if (scrd < 1)
        scrd = 1;
    immutable dxl = hardware.display.displayXl - 1;
    immutable dyl = hardware.display.displayYl - 1;
    immutable int a = scrd.roundInt;
    void msg(bool b) { _suggestTooltip = _suggestTooltip || b; }

    with (hardware.mouse) {
        Point mov = Point(0, 0);
        // Deliberately, we suggest the tooltip when we could scroll into
        // the opposite direction, not into the scrolling direction. The idea
        // is that I don't want the tooltip at the bottom edge when you can't
        // scroll down, but tooltip should persist after scrolled all the way.
        if (mouseX == 0)   { mov -= Point(a, 0); msg(_cam.mayScrollRight); }
        if (mouseX == dxl) { mov += Point(a, 0); msg(_cam.mayScrollLeft); }
        if (mouseY == 0)   { mov -= Point(0, a); msg(_cam.mayScrollDown); }
        if (mouseY == dyl) { mov += Point(0, a); msg(_cam.mayScrollUp); }
        _cam.focus = _cam.focus + mov;
    }
}

private void calcHoldScrolling()
{
    if (! scrollable) {
        _isHoldScrolling = false;
        return;
    }
    if (file.option.keyScroll.keyHeld && ! _isHoldScrolling) {
        // first frame of scrolling
        _scrollGrabbed = hardware.mouse.mouseOnScreen;
    }
    _isHoldScrolling = file.option.keyScroll.keyHeld;
    if (! _isHoldScrolling)
        return;

    int clickScrollingOneDimension(in bool minus, in bool plus,
        in int grabbed, in int mouse, in int mickey,
        void function() freeze
    ) {
        immutable dir = file.option.holdToScrollInvert.value ? -1 : 1;
        immutable uninvertedScrollingAllowed =
               (minus && mouse <= grabbed && mickey < 0)
            || (plus  && mouse >= grabbed && mickey > 0);
        if (dir == 1 && uninvertedScrollingAllowed
            || dir == -1 && (plus || minus)
        ) {
            immutable ret = roundInt(mickey * file.option.holdToScrollSpeed
                    * dir / zoom / 4); // the factor /4 comes from C++ Lix
            freeze();
            return ret;
        }
        return 0;
    }
    _cam.focus = _cam.focus + Point(
        clickScrollingOneDimension(_cam.mayScrollLeft, _cam.mayScrollRight,
        _scrollGrabbed.x, hardware.mouse.mouseX,
        hardware.mouse.mouseMickey.x, &hardware.mouse.freezeMouseX)
        ,
        clickScrollingOneDimension(_cam.mayScrollUp, _cam.mayScrollDown,
        _scrollGrabbed.y, hardware.mouse.mouseY,
        hardware.mouse.mouseMickey.y, &hardware.mouse.freezeMouseY));
}



// ############################################################################
// ########################################################### drawing routines
// ############################################################################



void drawCamera()
{
    drawBorders();
    drawCameraBorderless();
}

// To tell apart air from areas outside of the map, color screen borders.
private void drawBorders()
{
    void draw_border(in int ax, in int ay, in int axl, in int ayl)
    {
        // we assume the correct target bitmap is set.
        // D/A5 Lix doesn't make screen border coloring optional
        al_draw_filled_rectangle(ax, ay, ax + axl, ay + ayl,
                                 color.screenBorder);
    }
    if (borderOneSideXl > 0) {
        // Left edge.
        draw_border(0, 0, borderOneSideXl, _cam.targetYl);
        // Right edge. With fractional zoom, drawCameraBorderless might draw
        // a smaller rectangle than its plusX (see drawCameraBorderless).
        // To prevent leftover pixel rows from the last frame, make the border
        // thicker by 1 pixel here. The camera will draw over it.
        draw_border(_cam.targetXl - borderOneSideXl - 1, 0,
            borderOneSideXl + 1, _cam.targetYl);
    }
    if (borderUpperSideYl > 0) {
        draw_border(borderOneSideXl, 0, _cam.targetXl - 2 * borderOneSideXl,
            borderUpperSideYl);
    }
}

// Draw camera (maybe several times next to itself)
// to the current drawing target, most likely the screen
private void drawCameraBorderless()
{
    immutable int overallMaxX = _cam.targetXl - borderOneSideXl;
    immutable int plusX = (xl * zoom).ceil.to!int;
    immutable int plusY = (yl * zoom).ceil.to!int;
    for (int x = borderOneSideXl; x < overallMaxX; x += plusX) {
        for (int y = borderUpperSideYl; y < _cam.targetYl; y += plusY) {
            // maxXl, maxYl describe the size of the image to be drawn
            // in this iteration of the double-for loop. This should always
            // be as much as possible, i.e., the first argument to min().
            // Only in the last iteration of the loop,
            // a smaller rectangle is better.
            immutable maxXl = min(plusX, overallMaxX - x);
            immutable maxYl = min(plusY, _cam.targetYl - y);
            drawCamera_with_target_corner(x, y, maxXl, maxYl);
            if (borderUpperSideYl != 0) break;
        }
        if (borderOneSideXl != 0) break;
    }
}

private void
drawCamera_with_target_corner(
    in int tcx, // x coordinate of target corner
    in int tcy,
    in int maxTcxl, // length, away from (tcx, tcy). Draw at most this much
    in int maxTcyl  // to the target.
) {
    immutable Rect r = _cam.sourceSeenBeforeFirstTorusSeam();
    // Source length of the non-wrapped portion. (Target len = this * zoom.)
    immutable sxl1 = min(r.xl, _cam.divByZoom(maxTcxl));
    immutable syl1 = min(r.yl, _cam.divByZoom(maxTcyl));
    // target corner coordinates and size of the wrapped-around torus portion
    immutable tcx2 = tcx + r.xl * zoom;
    immutable tcy2 = tcy + r.yl * zoom;
    // source length of the wrapped-around torus portion
    immutable sxl2 = min(_cam.sourceSeen.xl - r.xl,
                         _cam.divByZoom(maxTcxl) - sxl1);
    immutable syl2 = min(_cam.sourceSeen.yl - r.yl,
                         _cam.divByZoom(maxTcyl) - syl1);

    void blitOnce(in int sx,  in int sy,  // source x, y
                  in int sxl, in int syl, // length on the source
                  in float tx, in float ty)  // start of the target
    {
        if (zoom == 1)
            al_draw_bitmap_region(torbit.albit, sx, sy, sxl, syl, tx, ty, 0);
        else
            al_draw_scaled_bitmap(torbit.albit, sx, sy, sxl, syl,
                                  tx, ty, zoom * sxl, zoom * syl, 0);
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
    immutable Rect r = _cam.sourceSeenBeforeFirstTorusSeam();

    immutable bool drtx = torusX && r.xl < _cam.sourceSeen.xl;
    immutable bool drty = torusY && r.yl < _cam.sourceSeen.yl;

    auto targetTorbit = TargetTorbit(this);
    if (file.option.paintTorusSeams.value)
        drawTorusSeams();

    void drawHere(int ax, int ay, int axl, int ayl)
    {
        al_draw_bitmap_region(cast (Albit) (src.albit),
            ax, ay, axl, ayl, ax, ay, 0);
    }
    if (true        ) drawHere(r.x, r.y, r.xl, r.yl);
    if (drtx        ) drawHere(0,   r.y, _cam.sourceSeen.xl - r.xl, r.yl);
    if (        drty) drawHere(r.x, 0,   r.xl, _cam.sourceSeen.xl - r.yl);
    if (drtx && drty) drawHere(0,   0,   _cam.sourceSeen.xl - r.xl,
                                         _cam.sourceSeen.yl - r.yl);
}

void
clearSourceThatWouldBeBlitToTarget(Alcol col)
{
    this.drawFilledRectangle(_cam.sourceSeen, col);
}

void drawTorusSeams()
{
    if (torusX) {
        al_draw_filled_rectangle(xl - 1, 0, xl, yl, color.torusSeamL);
        al_draw_filled_rectangle(0,      0, 1,  yl, color.torusSeamD);
    }
    if (torusY) {
        al_draw_filled_rectangle(0, yl - 1, xl, yl, color.torusSeamL);
        al_draw_filled_rectangle(0, 0,      xl, 1,  color.torusSeamD);
    }
    if (torusX && torusY)
        al_draw_filled_rectangle(xl - 1, 0, xl, 1, color.torusSeamL);
}

}
// end class Map
