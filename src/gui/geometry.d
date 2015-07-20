module gui.geometry;

/* class Geom assumes coordinates in the range 0 .. 480 vertically, and
 * advises to think that there's 640 geoms in horizontal direction, but there
 * can be more x-geoms on a Widescreen.
 *
 * The measurement unit of Geom is called "geom" throughout the source code.
 * Therefore, the screen is always 480 geom high, no matter what resolution
 * it has. If necessary, x-geom and y-geom refer to the measurements in the
 * separate directions.
 *
 *  static float get_screen_xl();
 *  static float get_screen_yl();
 *
 * Returns the number of x-geoms. y-geoms are always 480.
 *
 * Fonts should be 20 geom high. A4 Lix allowed for 24 lines of text aligned
 * vertically, this encouraged terseness. I like that.
 *
 *  this(x, y, xl = 20, yl = 20);
 *  this(Geom, ...);
 *
 *      Constructs a Geom with parent = null. The parent will usually be set
 *      via the method gui.element.Element.add_child().
 *
 *  float x, y, xl, yl;
 *
 *      Publicly settable position in geoms. Use From from and Geom parent
 *      to specify from where x/y should be measured. xl/yl are not affected.
 *
 *  @property int
 *  xg, yg, xlg, ylg
 *
 *      Convert the geometry from (geoms, from) to absolute geometry
 *      coordinates, measured from the top-left corner. I.e., if (this.from)
 *      is From.TOP_LEFT, then these return x, y, xl, yl unchanged.
 *
 *      Since the length in geoms doesn't depend on (this.from), xl, yl
 *      are always returned unchanged.
 *
 *  @property float
 *  xs, ys, xls, yls
 *
 *      Convert the geometry from (geoms, from) to absolute screen coordinates.
 *
 *  @property From x_from, y_from
 *
 *      Return LEFT, CENTER, RIGHT for x_from, or TOP, CENTER, BOTTOM for
 *      y_from. These functions examine only one nibble of (From from).
 *
 *  static void set_screen_xyls(in int _xl, in int _yl)
 *
 *      Should be called only by the display changing function.
 *
 *  override string toString() const
 *
 *      For testing purposes, you might want to look at this string,
 *      describing all the computed numbers.
 *
 */

import std.math;
import std.conv;
import std.string; // for testing output in toString()
import std.typecons; // rebindable

import graphic.gralib; // to inform it about the screen scaling factor,
                       // so it can return scaled-drawn bitmaps later

alias From = Geom.From;

class Geom {

    Rebindable!(const Geom) parent;
    From from;

    float x;
    float y;
    float xl;
    float yl;

    enum From {
        TOP_LEFT    = 0x11,     TOP    = 0x12,     TOP_RIGHT    = 0x14,
        LEFT        = 0x21,     CENTER = 0x22,     RIGHT        = 0x24,
        BOTTOM_LEFT = 0x41,     BOTTOM = 0x42,     BOTTOM_RIGHT = 0x44,

        // for convenience
        TOP_LEF = TOP_LEFT,    TOP_RIG = TOP_RIGHT,
        BOT_LEF = BOTTOM_LEFT, BOT_RIG = BOTTOM_RIGHT,
    }

    private static float _screen_xlg = 640;
    private static const _screen_ylg = 480f; // others will change, this won't
    private static float _screen_xls = 640;
    private static float _screen_yls = 480;
    private static float stretch_factor   = 1.0;
    private static int   screen_thickness = 2;

    @property static int   thickg() { return 2; }
    @property static int   thicks() { return screen_thickness; }

    @property static float screen_xlg() { return _screen_xlg; }
    @property static float screen_ylg() { return _screen_ylg; }
    @property static float screen_xls() { return _screen_xls; }
    @property static float screen_yls() { return _screen_yls; }

    // this function is called from gui.root, when that is initialized
    static void set_screen_xyls(in int _xl, in int _yl)
    {
        _screen_xls     = _xl;
        _screen_yls     = _yl;
        stretch_factor  = _screen_yls / _screen_ylg;
        _screen_xlg     = _screen_xls / stretch_factor;

        screen_thickness = std.math.floor(2.0 * stretch_factor).to!int;

        graphic.gralib.set_scale_from_gui(stretch_factor);
    }



    this(
        in float _x  =  0, in float _y  =  0,
        in float _xl = 20, in float _yl = 20, in From _from = From.TOP_LEFT
    ) {
        parent = null;
        from   = _from;
        x = _x; xl = _xl;
        y = _y; yl = _yl;
    }



    @property From x_from() const { return to!From(from & 0x0F | 0x20); }
    @property From y_from() const { return to!From(from & 0xF0 | 0x02); }

    @property float xlg() const { return xl; }
    @property float ylg() const { return yl; }

    @property float xs()  const { return xg  * stretch_factor; }
    @property float ys()  const { return yg  * stretch_factor; }
    @property float xls() const { return xlg * stretch_factor; }
    @property float yls() const { return ylg * stretch_factor; }



    @property float xg() const
    {
        immutable float p_xg  = parent ? parent.xg  : 0;
        immutable float p_xlg = parent ? parent.xlg : _screen_xlg;

        switch (x_from) {
            case From.LEFT:   return p_xg + x;
            case From.CENTER: return p_xg + p_xlg/2 - xl/2 - x;
            case From.RIGHT:  return p_xg + p_xlg   - xl   - x;
            default: assert (false);
        }
    }

    @property float yg() const
    {
        immutable float p_yg  = parent ? parent.yg  : 0;
        immutable float p_ylg = parent ? parent.ylg : _screen_ylg;

        switch (y_from) {
            case From.TOP:    return p_yg + y;
            case From.CENTER: return p_yg + p_ylg/2 - yl/2 - y;
            case From.BOTTOM: return p_yg + p_ylg   - yl   - y;
            default: assert (false);
        }
    }

    override string toString() const
    {
        int fl(float a) { return std.math.floor(a).to!int; }

        return format("from=0x%x x=%d y=%d xl=%d yl=%d\n",
                      from, fl(x), fl(y), fl(xl), fl(yl))
             ~ format("geoms: xg=%d yg=%d\n", fl(xg), fl(yg))
             ~ format("scren: xs=%d ys=%d xls=%d yls=%d",
                      fl(xs), fl(ys), fl(xls), fl(yls));
    }

}
// end class Geom