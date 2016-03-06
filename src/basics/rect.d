module basics.rect;

/* Point and Rect are for 2D geometry, so that other classes' methods don't
 * have to offer 2 functions for separate coordinates.
 */

import std.string;
import basics.help;

struct Rect { int x, y, xl, yl; }

struct Point {
    int x;
    int y;
    string toString() const { return format("(%d,%d)", x, y); }

    Point opBinary(string s)(in Point rhs) const
    {
        Point ret;
        mixin("ret.x = this.x " ~ s ~ " rhs.x;");
        mixin("ret.y = this.y " ~ s ~ " rhs.y;");
        return ret;
    }

    ref Point opOpAssign(string s)(in Point rhs)
    {
        mixin("x " ~ s ~ "= rhs.x;");
        mixin("y " ~ s ~ "= rhs.y;");
        return this;
    }

    Point positiveMod(in Point rhs) const
    {
        return Point(basics.help.positiveMod(x, rhs.x),
                     basics.help.positiveMod(y, rhs.y));
    }
}

unittest {
    assert (Point(3, 4) + Point(10, 10) == Point(13, 14));
    assert (Point(    ) - Point( 4,  5) == Point(-4, -5));
    assert (Point(11, 12).positiveMod(Point(5, 5)) == Point(1, 2));
}
