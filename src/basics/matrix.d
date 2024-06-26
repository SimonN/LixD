module basics.matrix;

import std.string; // format()
import std.conv; // to!string;

// This is used for the position of the exploder fuse.
// graphic.internal.initialize() sets Matrix countdown upon loading all images.

class Matrix(T) {
private:
    int _xl;
    int _yl;

    T[] data;

public:
    int xl() const pure nothrow @safe @nogc { return _xl; }
    int yl() const pure nothrow @safe @nogc { return _yl; }

    this(
        in int new_xl,
        in int new_yl
    )
    in {
        assert (new_xl > 0);
        assert (new_yl > 0);
    }
    do {
        _xl = new_xl;
        _yl = new_yl;
        data = new T[_xl * _yl];
    }

    this(const(Matrix!T) rhs)
    out {
        assert (data !is null);
        assert (data.length == _xl * _yl);
    }
    do {
        assert (rhs !is null);
        _xl = rhs.xl;
        _yl = rhs.yl;
        data = rhs.data.dup;
    }

    inout(T) get(in int x, in int y) inout pure nothrow @safe @nogc
    in {
        assert (x >= 0);
        assert (y >= 0);
        assert (x < _xl);
        assert (y < _yl);
    }
    do {
        return data[y * _xl + x];
    }

    void set(in int x, in int y, in T value) pure nothrow @safe @nogc
    in {
        assert (x >= 0);
        assert (y >= 0);
        assert (x < _xl);
        assert (y < _yl);
    }
    do {
        data[y * _xl + x] = value;
    }

    void setAllEntriesTo(in T value) pure nothrow @safe @nogc
    {
        data[] = value;
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
