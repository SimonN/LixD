module basics.rect;

/* Point and Rect are for 2D geometry, so that other classes' methods don't
 * have to offer 2 functions for separate coordinates.
 */

import std.algorithm;
import std.string;

import basics.help;

// a one-dimensional rectangle
struct Side {
    int start, len;

    string toString() const { return format("(%d;%d)", start, len); }

pure:
@nogc:
    static Side smallestContainer(in Side a, in Side b)
    {
        return Side(
            min(a.start, b.start),
            max(a.start + a.len, b.start + b.len) - min(a.start, b.start)
        );
    }
}

struct Rect {
    union {
        struct { int x, y, xl, yl;   }
        struct { Point topLeft, len; }
    }
    static assert (Point.sizeof == 2 * int.sizeof);
    static assert (Rect .sizeof == 4 * int.sizeof);

    string toString() const { return format("(%d,%d;%d,%d)", x, y, xl, yl); }

pure:
@nogc:
    this(in int ax, in int ay, in int axl, in int ayl)
    {
        x  = ax;
        y  = ay;
        xl = axl;
        yl = ayl;
    }

    this(in Point p, in int axl, in int ayl)
    {
        topLeft = p; this(p.x, p.y, axl, ayl);
    }

    this(Side xs, Side ys)
    {
        x  = xs.start;
        y  = ys.start;
        xl = xs.len;
        yl = ys.len;
    }

    @property Point center() const { return topLeft + len / 2; }
    @property Side  sideX()  const { return Side(x, xl); }
    @property Side  sideY()  const { return Side(y, yl); }

    // Translate the rectangle, keeping its length
    Rect opBinary(string s)(in Point p) const
        if (s == "+" || s == "-")
    {
        mixin("return Rect(x " ~ s ~ " p.x, y " ~ s ~ " p.y, xl, yl);");
    }

    static Rect smallestContainer(in Rect a, in Rect b)
    {
        return Rect(Side.smallestContainer(a.sideX, b.sideX),
                    Side.smallestContainer(a.sideY, b.sideY));
    }
}

unittest {
    assert (Rect(3, 4, 20, 30).center == Point(13, 19));
    assert ([ Rect(3, 5, 10, 10), Rect(5, 5, 9, 9), Rect(1, 1, 1, 1) ]
        .reduce!(Rect.smallestContainer) == Rect(1, 1, 13, 14));
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

    Point opUnary(string s)() const
        if (s == "+" || s == "-")
    {
        Point ret;
        mixin("ret.x = " ~ s ~ "this.x;");
        mixin("ret.y = " ~ s ~ "this.y;");
        return ret;
    }

    Point opBinary(string s)(in int scalar) const
        if (s == "*" || s == "/" || s == "%")
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
    Point roundTo(int grid) const pure
    {
        return (grid == 1) ? this : Point(basics.help.roundTo(x, grid),
                                          basics.help.roundTo(y, grid));
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
