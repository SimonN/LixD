module basics.matrix;

import std.string; // format()
import std.conv; // to!string;

// This is used for the position of the exploder fuse.
// graphic.internal.initialize() sets Matrix countdown upon loading all images.

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

private:

    int _xl;
    int _yl;

    T[] data;



public:

    @property int xl() const { return _xl; }
    @property int yl() const { return _yl; }

    this(
        in int new_xl,
        in int new_yl
    )
    in {
        assert (new_xl > 0);
        assert (new_yl > 0);
    }
    body {
        _xl = new_xl;
        _yl = new_yl;
        data = new T[_xl * _yl];
    }



    this(Matrix!T rhs)
    out {
        assert (data !is null);
        assert (data.length == _xl * _yl);
    }
    body {
        assert (rhs !is null);
        _xl = rhs.xl;
        _yl = rhs.yl;
        data = rhs.data.dup;
    }



    inout(T) get(in int x, in int y) inout
    in {
        assert (x >= 0,  "x is %d, not >= 0".format(x));
        assert (y >= 0,  "y is %d, not >= 0".format(y));
        assert (x < _xl, "x is %d, not <= _xl == %d".format(x, _xl));
        assert (y < _yl, "y is %d, not <= _yl == %d".format(y, _yl));
    }
    body {
        return data[y * _xl + x];
    }



    void set(in int x, in int y, T value)
    in {
        assert (x >= 0);
        assert (y >= 0);
        assert (x < _xl);
        assert (y < _yl);
    }
    body {
        data[y * _xl + x] = value;
    }



    override bool opEquals(Object rhsObj) const
    {
        typeof(this) rhs = cast (typeof(this)) rhsObj;
        assert (rhs, "can't compare against non-Matrix");
        return _xl == rhs._xl
            && _yl == rhs._yl
            && data == rhs.data;
    }



    override string toString() const
    {
        string s = "";
        for (int y = 0; y < _yl; ++y) {
            s ~= "[ ";
            for (int x = 0; x < _xl; ++x) {
                if (x > 0) s ~= ", ";
                s ~= to!string(get(x, y));
            }
            s ~= " ]\n";
        }
        return s;
    }

}
// end class Matrix(T)
