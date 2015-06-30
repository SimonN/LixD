module basics.matrix;

import std.string; // format()
import std.conv; // to!string;

// This is used for the position of the exploder fuse.
// graphic.gralib.initialize() sets Matrix countdown upon loading all images.

struct XY {

    int x;
    int y;

    this(in int _x, in int _y)
    {
        x = _x;
        y = _y;
    }

    string toString()
    {
        return format("(%d,%d)", x, y);
    }

}



class Matrix(T) {

public:

/*  this(in int _xl, in int _yl);
 *  this(in Matrix!T);
 *  ~this() { }
 *
 *  T    get(in int x, in int y) const;
 *  void set(in int x, in int y, in T value);
 *
 *  override string toString() const; -- exists, see below
 */

private:

    int xl;
    int yl;

    T[] data;



public:

this(
    in int _xl,
    in int _yl
)
in {
    assert (_xl > 0);
    assert (_yl > 0);
}
body {
    xl = _xl;
    yl = _yl;
    data = new T[xl * yl];
}



this(in Matrix!T rhs)
out {
    assert (data !is null);
    assert (data.length == xl * yl);
}
body {
    assert (rhs !is null);
    xl = rhs.xl;
    yl = rhs.yl;
    data = rhs.data.dup;
}



T get(in int x, in int y) const
in {
    assert (x >= 0);
    assert (y >= 0);
    assert (x < xl);
    assert (y < yl);
}
body {
    return data[y * xl + x];
}



void set(in int x, in int y, in T value)
in {
    assert (x >= 0);
    assert (y >= 0);
    assert (x < xl);
    assert (y < yl);
}
body {
    data[y * xl + x] = value;
}



override string toString() const
{
    string s = "";
    for (int y = 0; y < yl; ++y) {
        s ~= "[ ";
        for (int x = 0; x < xl; ++x) {
            if (x > 0) s ~= ", ";
            s ~= to!string(get(x, y));
        }
        s ~= " ]\n";
    }
    return s;
}

}
// end class
