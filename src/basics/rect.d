module basics.rect;

/* Point and Rect are for 2D geometry, so that other classes' methods don't
 * have to offer 2 functions for separate coordinates.
 */

import std.string;
import basics.help;

struct Rect {
    int x, y, xl, yl;

    this(in int ax, in int ay, in int axl, in int ayl)
    {
        x  = ax;
        y  = ay;
        xl = axl;
        yl = ayl;
    }

    this(in Point p, in int axl, in int ayl)
    {
        this(p.x, p.y, axl, ayl);
    }

    @property Point topLeft() const { return Point(x, y);   }
    @property Point len()     const { return Point(xl, yl); }

    // Translate the rectangle, keeping its length
    Rect opBinary(string s)(in Point p) const
        if (s == "+" || s == "-")
    {
        mixin("return Rect(x " ~ s ~ " p.x, y " ~ s ~ " p.y, xl, yl);");
    }
}

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

    Point opBinary(string s)(in int scalar) const
        if (s == "*" || s == "/")
    {
        Point ret;
        mixin("ret.x = this.x " ~ s ~ " scalar;");
        mixin("ret.y = this.y " ~ s ~ " scalar;");
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

    // When rounding to multiples of 8,
    // we round -12, -11, ..., -5          all to -8.
    // we round -4, -3, -2, -1, 0, 1, 2, 3 all to  0.
    // We round +4, +5, ..., +11           all to +8.
    Point roundTo(int grid) const
    {
        if (grid == 1)
            return this;
        assert (grid > 1);
        return Point(x + grid/2 - basics.help.positiveMod(x + grid/2, grid),
                     y + grid/2 - basics.help.positiveMod(y + grid/2, grid));
    }
}

unittest {
    assert (Point(3, 4) + Point(10, 10) == Point(13, 14));
    assert (Point(    ) - Point( 4,  5) == Point(-4, -5));
    assert (Point(11, 12).positiveMod(Point(5, 5)) == Point(1, 2));

    assert (Point(0, 0).roundTo(2) == Point(0, 0));
    assert (Point(1, 3).roundTo(2) == Point(2, 4));
    assert (Point(-5, 5).roundTo(10) == Point(0, 10));
    assert (Point(-6, 4).roundTo(10) == Point(-10, 0));
}
