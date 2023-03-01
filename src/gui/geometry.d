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
 * Font should be 20 geom high. A4 Lix allowed for 24 lines of text aligned
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

static import gui.context;

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

    this(
        in float _x  =  0, in float _y  =  0,
        in float _xl = 20, in float _yl = 20, in From _from = From.TOP_LEFT
    ) pure {
        parent = null;
        from   = _from;
        x = _x; xl = _xl;
        y = _y; yl = _yl;
    }

    this(in Geom g) pure
    {
        this(g.x, g.y, g.xl, g.yl, g.from);
    }

    const nothrow @safe @nogc {
        float xlg() pure { return xl; }
        float ylg() pure { return yl; }
        float xs() { return xg  * gui.context.stretchFactor; }
        float ys() { return yg  * gui.context.stretchFactor; }
        float xls() { return xlg * gui.context.stretchFactor; }
        float yls() { return ylg * gui.context.stretchFactor; }

        float xg()
        {
            immutable float pXg  = parent ? parent.xg  : 0;
            immutable float pXlg = parent ? parent.xlg : gui.context.screenXlg;

            switch (xFrom) {
                case From.LEFT:   return pXg + x;
                case From.CENTER: return pXg + pXlg/2 - xl/2 + x;
                case From.RIGHT:  return pXg + pXlg   - xl   - x;
                default: assert (false);
            }
        }

        float yg()
        {
            immutable float pYg  = parent ? parent.yg  : 0;
            immutable float pYlg = parent ? parent.ylg : gui.context.screenYlg;

            switch (yFrom) {
                case From.TOP:    return pYg + y;
                case From.CENTER: return pYg + pYlg/2 - yl/2 + y;
                case From.BOTTOM: return pYg + pYlg   - yl   - y;
                default: assert (false);
            }
        }

        From xFrom() pure
        {
            switch (from & 0x0F) {
                case 0x02: return From.CENTER;
                case 0x04: return From.RIGHT;
                default: return From.LEFT;
            }
        }

        From yFrom() pure
        {
            switch (from & 0xF0) {
                case 0x20: return From.CENTER;
                case 0x40: return From.BOTTOM;
                default: return From.TOP;
            }
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
