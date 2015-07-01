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
 * has an immutable size camera_xl and camera_yl.
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
        bool scrollable_up()    { return _camera_y > min_y || torus_y; }
        bool scrollable_right() { return _camera_x < max_x || torus_x; }
        bool scrollable_left()  { return _camera_x > min_x || torus_x; }
        bool scrollable_down()  { return _camera_y < max_y || torus_y; }
    }

    @property bool scrollable()
    {
        return scrollable_up()   && scrollable_down()
            && scrollable_left() && scrollable_right();
    }

    @property bool scrolling_now() { return scrollable && scrolling_continues;}
    @property int  camera_xl()     { return _camera_xl; }
    @property int  camera_yl()     { return _camera_yl; }

/* New and exciting difference to A4/C++ Lix:
 * screen_x/y point to the center of the visible area. This makes computing
 * zoom easier, and copying the resulting viewed area is encapsulated in
 * draw() anyway.
 */
    @property int  camera_x() { return _camera_x; }
    @property int  camera_y() { return _camera_y; }
//  @property int  camera_x(int);
//  @property int  camera_y(int);
    void set_camera_xy(in int x, in int y) { camera_x = x; camera_y = y; }

    @property int zoom() { return _zoom; }
//  @property int zoom(in int)

/*  @property int  mouse_x();
 *  @property int  mouse_y();
 *  void calc_scrolling();
 *
 *  void draw(Torbit&);
 *
 *  void load_masked_screen_rectangle(Torbit&);
 *  void clear_screen_rectangle(AlCol);
 */

private:

    immutable int _camera_xl;
    immutable int _camera_yl;

    int  _camera_x;
    int  _camera_y;

    int  _zoom;

    int  scroll_click_x;
    int  scroll_click_y;

    bool scrolling_starts;
    bool scrolling_continues;

    // these two don't crop at the edge yet
    @property int camera_zoomed_xl() { return (_camera_xl + zoom - 1) / zoom; }
    @property int camera_zoomed_yl() { return (_camera_yl + zoom - 1) / zoom; }

    @property int min_x() { return camera_zoomed_xl / 2; }
    @property int min_y() { return camera_zoomed_yl / 2; }
    @property int max_x() { return xl - min_x; }
    @property int max_y() { return yl - min_y; }



public:

this(in Torbit like_this, in int a_camera_xl, in int a_camera_yl)
{
    assert (like_this);
    assert (a_camera_xl > 0);
    assert (a_camera_yl > 0);

    super(like_this.xl, like_this.yl, like_this.torus_x, like_this.torus_y);
    _camera_xl = a_camera_xl;
    _camera_yl = a_camera_yl;
    _zoom = 1;

    camera_x  = _camera_xl / 2;
    camera_y  = _camera_yl / 2;
}



private @property int
scroll_speed_edge()
{
    return basics.user.scroll_speed_edge;
}



private @property int
scroll_speed_click()
{
    return basics.user.scroll_speed_click;
}



@property int
camera_x(in int x)
{
    _camera_x = x;
    if (torus_x) {
        _camera_x = basics.help.positive_mod(_camera_x, xl);
    }
    else if (min_x >= max_x) {
        // this can happen on very small maps
        _camera_x = this.xl / 2;
    }
    else {
        if (_camera_x < min_x) _camera_x = min_x;
        if (_camera_x > max_x) _camera_x = max_x;
    }
    return _camera_x;
}



@property int
camera_y(in int y)
{
    _camera_y = y;
    if (torus_y) {
        _camera_y = basics.help.positive_mod(_camera_y, yl);
    }
    else if (min_y >= max_y) {
        // this can happen on very small maps
        _camera_y = this.yl / 2;
    }
    else {
        if (_camera_y < min_y) _camera_y = min_y;
        if (_camera_y > max_y) _camera_y = max_y;
    }
    return _camera_y;
}



@property int
zoom(in int z)
{
    assert (z > 0);
    _zoom = z;
    camera_x = _camera_x; // move back onto visible area if we have zoomed out
    camera_y = _camera_y;
    return _zoom;
}



@property int
mouse_x()
{
    int ret = _camera_x - min_x + (hardware.mouse.get_mx() / zoom);
    if (! torus_x && _camera_xl > xl * zoom) {
        // small non-torus maps are centered on the camera.
        // Compute the left frame width (1/2 of missing x-length)
        ret -= _camera_xl - xl * zoom / 2;
    }
    if (torus_x)
        ret = basics.help.positive_mod(ret, xl);
    return ret;
}



@property int
mouse_y()
{
    int ret = _camera_y - min_y + (hardware.mouse.get_my() / zoom);
    if (! torus_y && _camera_yl > yl * zoom) {
        // small non-torus maps are drawn at the lower edge of the camera
        ret -= camera_yl - yl * zoom;
    }
    if (torus_y)
        ret = basics.help.positive_mod(ret, yl);
    return ret;
}



void
calc_scrolling()
{
    if (basics.user.scroll_edge) {
        int scrd = this.scroll_speed_edge;
        if (hardware.mouse.get_mrh()) scrd *= 4;
        if (zoom > 1) {
            scrd += zoom - 1;
            scrd /= zoom;
        }
        immutable edge_r = hardware.display.display_xl - 1;
        immutable edge_u = hardware.display.display_yl - 1;
        // we don't care about this.mouse_x/y, because we want to scroll
        // at the edge of the screen, not the edge of the map
        if (hardware.mouse.get_my() == 0)      camera_y = _camera_y - scrd;
        if (hardware.mouse.get_mx() == edge_r) camera_x = _camera_x + scrd;
        if (hardware.mouse.get_my() == edge_u) camera_y = _camera_y + scrd;
        if (hardware.mouse.get_mx() == 0)      camera_x = _camera_x - scrd;
    }

    // scrolling with held right/middle mouse button
    bool scroll_now = (hardware.mouse.get_mrh() && basics.user.scroll_right)
                   || (hardware.mouse.get_mmh() && basics.user.scroll_middle)
                   ||  hardware.keyboard.key_hold(basics.user.key_scroll);
    scrolling_starts    = scroll_now && ! scrolling_continues;
    scrolling_continues = scroll_now;

    if (scrolling_starts) {
        // remember old position of the mouse
        scroll_click_x = hardware.mouse.get_mx();
        scroll_click_y = hardware.mouse.get_my();
    }
    if (scrolling_continues) {
        immutable bool xp = scrollable_right();
        immutable bool xm = scrollable_left();
        immutable bool yp = scrollable_down();
        immutable bool ym = scrollable_up();
        // now scroll the screen and possibly freeze the mouse
        if ((xm && hardware.mouse.get_mx      () <= scroll_click_x
                && hardware.mouse.get_mickey_x() <  0)
         || (xp && hardware.mouse.get_mx      () >= scroll_click_x
                && hardware.mouse.get_mickey_x() >  0))
        {
            camera_x = _camera_x + hardware.mouse.get_mickey_x()
                                 * this.scroll_speed_click / 4;
            hardware.mouse.freeze_mouse_x();
        }
        if ((ym && hardware.mouse.get_my      () <= scroll_click_y
                && hardware.mouse.get_mickey_y() <  0)
         || (yp && hardware.mouse.get_my      () >= scroll_click_y
                && hardware.mouse.get_mickey_y() >  0))
        {
            camera_y = camera_y + hardware.mouse.get_mickey_y()
                                * this.scroll_speed_click / 4;
            hardware.mouse.freeze_mouse_y();
        }
    }
    // end right-click scrolling
}
// end calc_scrolling()



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
    if (! torus_x && xl * zoom < camera_xl)
        less_x = _camera_xl - xl * zoom;
    if (! torus_y && yl * zoom < camera_yl)
        less_y = _camera_yl - yl * zoom;

    mixin(temp_target!"target_albit");

    for     (int x = less_x/2; x < _camera_xl-less_x/2; x += xl * zoom) {
        for (int y = less_y;   y < _camera_yl;          y += yl * zoom) {
            // max_xl, max_yl describe the size of the image to be drawn
            // in this iteration of the double-for loop. This should always
            // be as much as possible. Only in the last iteration of the loop,
            // a smaller rectangle is better.
            immutable int max_xl = min(xl * zoom, _camera_xl - x);
            immutable int max_yl = min(yl * zoom, _camera_yl - y);
            draw_camera_with_target_corner(x, y, max_xl, max_yl);
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
                                 color.screen_border);
    }
    if (less_x) {
        draw_border(0,                    0, less_x/2,             camera_yl);
        draw_border(camera_xl - less_x/2, 0, less_x/2,             camera_yl);
    }
    if (less_y)
        draw_border(less_x/2,             0, camera_xl - less_x,   less_y);
}



private static struct Rect { int x, y, xl, yl; }

private Rect get_camera_rect()
{
    Rect rect;
    immutable int x_tmp = _camera_x - camera_zoomed_xl / 2;
    immutable int y_tmp = _camera_y - camera_zoomed_yl / 2;

    rect.x  = torus_x ? positive_mod(x_tmp, this.xl) : max(x_tmp, 0);
    rect.y  = torus_y ? positive_mod(y_tmp, this.yl) : max(y_tmp, 0);
    rect.xl = min(camera_zoomed_xl, this.xl - rect.x);
    rect.yl = min(camera_zoomed_yl, this.yl - rect.y);
    return rect;
}



private void
draw_camera_with_target_corner(
    in int tcx,
    in int tcy,
    in int max_tcxl,
    in int max_tcyl
) {
    immutable r    = get_camera_rect();
    immutable drtx = r.xl < camera_zoomed_xl && r.xl < max_tcxl && torus_x;
    immutable drty = r.yl < camera_zoomed_yl && r.yl < max_tcyl && torus_y;

    // size of the non-wrapped portion
    immutable xl1 = min(r.xl, max_tcxl);
    immutable yl1 = min(r.yl, max_tcyl);

    // these two are the size of the wrapped-around torus portion
    immutable xl2 = min(camera_zoomed_xl - r.xl, max_tcxl - r.xl);
    immutable yl2 = min(camera_zoomed_yl - r.yl, max_tcyl - r.yl);

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
load_camera_rectangle(Torbit src)
{
    assert (src.albit);
    assert (this.xl == src.xl);
    assert (this.yl == src.yl);
    // this doesn't care for the zoom

    // We don't use a drawing delegate with the Torbit base cless.
    // That would be like stamping the thing 4x entirelly onto the torbit.
    // We might want to copy less than 4 entire stamps. Let's implement it.
    immutable Rect r = get_camera_rect();

    immutable bool drtx = torus_x && r.xl < camera_zoomed_xl;
    immutable bool drty = torus_y && r.yl < camera_zoomed_yl;

    mixin(temp_target!"this.albit");
    void draw_here(int ax, int ay, int axl, int ayl)
    {
        al_draw_bitmap_region(src.albit, ax, ay, axl, ayl, ax, ay, 0);
    }
    if (true        ) draw_here(r.x, r.y, r.xl, r.yl);
    if (drtx        ) draw_here(0,   r.y, camera_zoomed_xl - r.xl, r.yl);
    if (        drty) draw_here(r.x, 0,   r.xl, camera_zoomed_yl - r.yl);
    if (drtx && drty) draw_here(0,   0,   camera_zoomed_xl - r.xl,
                                          camera_zoomed_yl - r.yl);
}



void
clear_screen_rectangle(AlCol col)
{
    Rect r = get_camera_rect();
    draw_filled_rectangle(r.x, r.y, camera_zoomed_xl,
                                    camera_zoomed_yl, col);
}

}
// end class Map
