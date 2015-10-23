module graphic.map;

import std.algorithm; // min

import basics.alleg5;
import basics.help;
import graphic.color;
import graphic.torbit;

static import basics.user;
static import hardware.display;
static import hardware.keyboard;
static import hardware.mouse;

/* (class Map : Torbit) has a camera pointing somewhere inside the entire
 * torbit. The camera specifies the center of a rectangle. This rectangle
 * has an immutable size cameraXl and cameraYl.
 */

class Map : Torbit {

/*  this(in int xl, int yl, int srceen_xl, int screen_yl)
 *
 *      Deduct from the real screen xl/yl the GUI elements, then pass the
 *      remainder to this constructor.
 *
 *  void resize(int, int);
 */
    @property {
        bool scrollableUp()    { return _cameraY > minY || torusY; }
        bool scrollableRight() { return _cameraX < maxX || torusX; }
        bool scrollableLeft()  { return _cameraX > minX || torusX; }
        bool scrollableDown()  { return _cameraY < maxY || torusY; }
    }

    @property bool scrollable()
    {
        return scrollableUp()   || scrollableDown()
            || scrollableLeft() || scrollableRight();
    }

    @property bool scrollingNow() { return scrollable && scrollingContinues;}
    @property int  cameraXl()     { return _cameraXl; }
    @property int  cameraYl()     { return _cameraYl; }

/* New and exciting difference to A4/C++ Lix:
 * screen_x/y point to the center of the visible area. This makes computing
 * zoom easier, and copying the resulting viewed area is encapsulated in
 * draw() anyway.
 */
    @property int  cameraX() { return _cameraX; }
    @property int  cameraY() { return _cameraY; }
//  @property int  cameraX(int);
//  @property int  cameraY(int);
    void set_cameraXY(in int x, in int y) { cameraX = x; cameraY = y; }

    @property int zoom() { return _zoom; }
//  @property int zoom(in int)

/*  @property int mouseOnLandX();
 *  @property int mouseOnLandY();
 *  void calcScrolling();
 *
 *  void draw(Torbit&);
 *
 *  void load_masked_screen_rectangle(Torbit&);
 *  void clear_screen_rectangle(AlCol);
 */

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

    // these two don't crop at the edge yet
    @property int cameraZoomedXl() { return (_cameraXl + zoom - 1) / zoom; }
    @property int cameraZoomedYl() { return (_cameraYl + zoom - 1) / zoom; }

    @property int minX() { return cameraZoomedXl / 2; }
    @property int minY() { return cameraZoomedYl / 2; }
    @property int maxX() { return xl - minX; }
    @property int maxY() { return yl - minY; }



public:

this(in Torbit like_this, in int a_cameraXl, in int a_cameraYl)
{
    assert (like_this);
    assert (a_cameraXl > 0);
    assert (a_cameraYl > 0);

    super(like_this.xl, like_this.yl, like_this.torusX, like_this.torusY);
    _cameraXl = a_cameraXl;
    _cameraYl = a_cameraYl;
    _zoom = 1;

    cameraX  = _cameraXl / 2;
    cameraY  = _cameraYl / 2;
}



private @property int
scrollSpeedEdge()
{
    return basics.user.scrollSpeedEdge;
}



private @property int
scrollSpeedClick()
{
    return basics.user.scrollSpeedClick;
}



@property int
cameraX(in int x)
{
    _cameraX = x;
    if (torusX) {
        _cameraX = basics.help.positiveMod(_cameraX, xl);
    }
    else if (minX >= maxX) {
        // this can happen on very small maps
        _cameraX = this.xl / 2;
    }
    else {
        if (_cameraX < minX) _cameraX = minX;
        if (_cameraX > maxX) _cameraX = maxX;
    }
    return _cameraX;
}



@property int
cameraY(in int y)
{
    _cameraY = y;
    if (torusY) {
        _cameraY = basics.help.positiveMod(_cameraY, yl);
    }
    else if (minY >= maxY) {
        // this can happen on very small maps
        _cameraY = this.yl / 2;
    }
    else {
        if (_cameraY < minY) _cameraY = minY;
        if (_cameraY > maxY) _cameraY = maxY;
    }
    return _cameraY;
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



@property int
mouseOnLandX()
{
    int ret = _cameraX - minX + (hardware.mouse.mouseX() / zoom);
    if (! torusX && _cameraXl > xl * zoom) {
        // small non-torus maps are centered on the camera.
        // Compute the left frame width (1/2 of missing x-length)
        ret -= _cameraXl - xl * zoom / 2;
    }
    if (torusX)
        ret = basics.help.positiveMod(ret, xl);
    return ret;
}



@property int
mouseOnLandY()
{
    int ret = _cameraY - minY + (hardware.mouse.mouseY() / zoom);
    if (! torusY && _cameraYl > yl * zoom) {
        // small non-torus maps are drawn at the lower edge of the camera
        ret -= cameraYl - yl * zoom;
    }
    if (torusY)
        ret = basics.help.positiveMod(ret, yl);
    return ret;
}



void
calcScrolling()
{
    if (basics.user.scrollEdge) {
        int scrd = this.scrollSpeedEdge;
        if (hardware.mouse.mouseHeldRight()) scrd *= 4;
        if (zoom > 1) {
            scrd += zoom - 1;
            scrd /= zoom;
        }
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
        immutable bool xp = scrollableRight();
        immutable bool xm = scrollableLeft();
        immutable bool yp = scrollableDown();
        immutable bool ym = scrollableUp();
        // now scroll the screen and possibly freeze the mouse
        if ((xm && hardware.mouse.mouseX      () <= scrollGrabbedX
                && hardware.mouse.mouseMickeyX() <  0)
         || (xp && hardware.mouse.mouseX      () >= scrollGrabbedX
                && hardware.mouse.mouseMickeyX() >  0))
        {
            cameraX = _cameraX + hardware.mouse.mouseMickeyX()
                                 * this.scrollSpeedClick / 4;
            hardware.mouse.freezeMouseX();
        }
        if ((ym && hardware.mouse.mouseY      () <= scrollGrabbedY
                && hardware.mouse.mouseMickeyY() <  0)
         || (yp && hardware.mouse.mouseY      () >= scrollGrabbedY
                && hardware.mouse.mouseMickeyY() >  0))
        {
            cameraY = cameraY + hardware.mouse.mouseMickeyY()
                              * this.scrollSpeedClick / 4;
            hardware.mouse.freezeMouseY();
        }
    }
    // end right-click scrolling
}
// end calcScrolling()



// ############################################################################
// ########################################################### drawing routines
// ############################################################################



void
draw_camera(Albit target_albit)
{
    // less_x/y: By how much is the camera larger than the map?
    //           These are 0 on torus maps, only > 0 for small non-torus maps.
    int less_x = 0;
    int less_y = 0;
    if (! torusX && xl * zoom < cameraXl)
        less_x = _cameraXl - xl * zoom;
    if (! torusY && yl * zoom < cameraYl)
        less_y = _cameraYl - yl * zoom;

    auto drata = DrawingTarget(target_albit);

    for     (int x = less_x/2; x < _cameraXl-less_x/2; x += xl * zoom) {
        for (int y = less_y;   y < _cameraYl;          y += yl * zoom) {
            // maxXl, maxYl describe the size of the image to be drawn
            // in this iteration of the double-for loop. This should always
            // be as much as possible. Only in the last iteration of the loop,
            // a smaller rectangle is better.
            immutable int maxXl = min(xl * zoom, _cameraXl - x);
            immutable int maxYl = min(yl * zoom, _cameraYl - y);
            draw_camera_with_target_corner(x, y, maxXl, maxYl);
            if (less_y != 0) break;
        }
        if (less_x != 0) break;
    }

    // To tell apart air from areas outside of the map, color screen borders.
    void draw_border(in int ax, in int ay, in int axl, in int ayl)
    {
        // we assume the correct target bitmap is set.
        // D/A5 Lix doesn't make screen border coloring optional
        al_draw_filled_rectangle(ax, ay, ax + axl, ay + ayl,
                                 color.screenBorder);
    }
    if (less_x) {
        draw_border(0,                    0, less_x/2,             cameraYl);
        draw_border(cameraXl - less_x/2, 0, less_x/2,             cameraYl);
    }
    if (less_y)
        draw_border(less_x/2,             0, cameraXl - less_x,   less_y);
}



private static struct Rect { int x, y, xl, yl; }

private Rect cameraRectangle()
{
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
draw_camera_with_target_corner(
    in int tcx,
    in int tcy,
    in int max_tcxl,
    in int max_tcyl
) {
    immutable r    = cameraRectangle();
    immutable drtx = r.xl < cameraZoomedXl && r.xl < max_tcxl && torusX;
    immutable drty = r.yl < cameraZoomedYl && r.yl < max_tcyl && torusY;

    // size of the non-wrapped portion
    immutable xl1 = min(r.xl, max_tcxl);
    immutable yl1 = min(r.yl, max_tcyl);

    // these two are the size of the wrapped-around torus portion
    immutable xl2 = min(cameraZoomedXl - r.xl, max_tcxl - r.xl);
    immutable yl2 = min(cameraZoomedYl - r.yl, max_tcyl - r.yl);

    void blit_once(int sx,  int sy,  // source x, y
                   int sxl, int syl, // length on the source
                   int tx,  int ty)  // start of the target
    {
        if (zoom == 1)
            al_draw_bitmap_region(albit, sx, sy, sxl, syl, tx, ty, 0);
        else
            al_draw_scaled_bitmap(albit, sx, sy, sxl,      syl,
                                         tx, ty, zoom*sxl, zoom*syl, 0);
    }
                      blit_once(r.x, r.y, xl1, yl1, tcx,        tcy);
    if (drtx        ) blit_once(0,   r.y, xl2, yl1, tcx + r.xl, tcy);
    if (        drty) blit_once(r.x, 0,   xl1, yl2, tcx,        tcy + r.yl);
    if (drtx && drty) blit_once(0,   0,   xl2, yl2, tcx + r.xl, tcy + r.yl);
}



void
loadCameraRectangle(Torbit src)
{
    assert (src.albit);
    assert (this.xl == src.xl);
    assert (this.yl == src.yl);
    // this doesn't care for the zoom

    // We don't use a drawing delegate with the Torbit base cless.
    // That would be like stamping the thing 4x entirelly onto the torbit.
    // We might want to copy less than 4 entire stamps. Let's implement it.
    immutable Rect r = cameraRectangle();

    immutable bool drtx = torusX && r.xl < cameraZoomedXl;
    immutable bool drty = torusY && r.yl < cameraZoomedYl;

    auto drata = DrawingTarget(this.albit);

    void drawHere(int ax, int ay, int axl, int ayl)
    {
        al_draw_bitmap_region(src.albit, ax, ay, axl, ayl, ax, ay, 0);
    }
    if (true        ) drawHere(r.x, r.y, r.xl, r.yl);
    if (drtx        ) drawHere(0,   r.y, cameraZoomedXl - r.xl, r.yl);
    if (        drty) drawHere(r.x, 0,   r.xl, cameraZoomedYl - r.yl);
    if (drtx && drty) drawHere(0,   0,   cameraZoomedXl - r.xl,
                                         cameraZoomedYl - r.yl);
}



void
clear_screen_rectangle(AlCol col)
{
    Rect r = cameraRectangle();
    this.drawFilledRectangle(r.x, r.y, cameraZoomedXl, cameraZoomedYl, col);
}

}
// end class Map
