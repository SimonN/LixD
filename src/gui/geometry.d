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
 *  this(Geom g);
 *
 *      Constructs a Geom with parent = null. The parent will usually be set
 *      via the method gui.element.Element.addChild().
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
 *  @property From xFrom, yFrom
 *
 *      Return LEFT, CENTER, RIGHT for xFrom, or TOP, CENTER, BOTTOM for
 *      yFrom. These functions examine only one nibble of (From from).
 *
 *  static void setScreenXYls(in int _xl, in int _yl)
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

    private static float _screenXlg = 640;
    private static const _screenYlg = 480f; // others will change, this won't
    private static float _screenXls = 640;
    private static float _screenYls = 480;
    private static float _stretchFactor   = 1.0;
    private static int   screenThickness = 2;

    @property static int   thickg() { return 2; }
    @property static int   thicks() { return screenThickness; }

    @property static float screenXlg() { return _screenXlg; }
    @property static float screenYlg() { return _screenYlg; }
    @property static float screenXls() { return _screenXls; }
    @property static float screenYls() { return _screenYls; }
    @property static float stretchFactor() { return _stretchFactor; }

    @property static float
    mapYls()
    out (result) {
        assert (result >= 0);
        assert (result <= screenYls);
    }
    body {
        // 1 / (return value) is the ratio of vertical space occupied by the
        // game/editor panels. Higher values mean less y-space for panels.
        int panelYlgDivisor()
        {
            return _screenXlg > 700 ? 5  // widescreen
                                    : 6; // 4:3 screen or taller
        }
        // The remaining pixels (for the map above the panel) should be a
        // multiple of the max zoom level, to make the zoom look nice.
        enum int multipleForZoom = 4;
        float mapYls = _screenYls - (_screenYls / panelYlgDivisor);
        mapYls = floor(mapYls / multipleForZoom) * multipleForZoom;
        return mapYls;
    }

    @property static float panelYls() { return screenYls - mapYls;        }
    @property static float panelYlg() { return panelYls / _stretchFactor; }

    // this function is called from gui.root, when that is initialized
    static void
    setScreenXYls(in int _xl, in int _yl)
    {
        _screenXls     = _xl;
        _screenYls     = _yl;
        _stretchFactor = _screenYls / _screenYlg;
        _screenXlg     = _screenXls / _stretchFactor;

        screenThickness = std.math.floor(2.0 * _stretchFactor).to!int;

        graphic.gralib.setScaleFromGui(_stretchFactor);
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

    this(in Geom g)
    {
        this(g.x, g.y, g.xl, g.yl, g.from);
    }



    @property From xFrom() const { return to!From(from & 0x0F | 0x20); }
    @property From yFrom() const { return to!From(from & 0xF0 | 0x02); }

    @property float xlg() const { return xl; }
    @property float ylg() const { return yl; }

    @property float xs()  const { return xg  * _stretchFactor; }
    @property float ys()  const { return yg  * _stretchFactor; }
    @property float xls() const { return xlg * _stretchFactor; }
    @property float yls() const { return ylg * _stretchFactor; }



    @property float xg() const
    {
        immutable float pXg  = parent ? parent.xg  : 0;
        immutable float pXlg = parent ? parent.xlg : _screenXlg;

        switch (xFrom) {
            case From.LEFT:   return pXg + x;
            case From.CENTER: return pXg + pXlg/2 - xl/2 + x;
            case From.RIGHT:  return pXg + pXlg   - xl   - x;
            default: assert (false);
        }
    }

    @property float yg() const
    {
        immutable float pYg  = parent ? parent.yg  : 0;
        immutable float pYlg = parent ? parent.ylg : _screenYlg;

        switch (yFrom) {
            case From.TOP:    return pYg + y;
            case From.CENTER: return pYg + pYlg/2 - yl/2 + y;
            case From.BOTTOM: return pYg + pYlg   - yl   - y;
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
