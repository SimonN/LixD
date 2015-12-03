module game.phymap;

/* A lookup table for quick land/steel detection and backwards correspondence
 * of playfield positions to interactive objects.
 *
 * Right now, this doesn't store pointers to objects. Thus, it can be checked
 * whether there is fire or water or steel at a given position, but it cannot
 * tell what exact interactive object instance sits there. If this behavior
 * is desired, the object in question must be looked up manually in the list
 * of objects of its type.
 */

import basics.alleg5;
import basics.help;
import file.filename;

alias Phybitset = short;
enum  Phybit    : Phybitset {
    terrain = 0x0001,
    steel   = 0x0002,
    goal    = 0x0010,
    fire    = 0x0040,
    water   = 0x0080,
    trap    = 0x0100,
    fling   = 0x0200,
    trampo  = 0x0400,
    all     = 0x7FFF,
}



class Phymap {

    @property int  xl()     const { return _xl; }
    @property int  yl()     const { return _yl; }
    @property bool torusX() const { return _tx; }
    @property bool torusY() const { return _ty; }

    this(
        in int a_xl, in int a_yl, in bool a_tx = false, in bool a_ty = false
    ) {
        resize(a_xl, a_yl, a_tx, a_ty);
    }

    this(in typeof(this) rhs)
    {
        assert (rhs !is null);

        _xl = rhs._xl;
        _yl = rhs._yl;
        _tx = rhs._tx;
        _ty = rhs._ty;
        lt  = rhs.lt.dup;
    }

    Phymap clone() const { return new Phymap(this); }



    // commenting out the invariant to test PhysicsDrawer performance
    // even during debugging mode
    /+
    invariant()
    {
        if (_xl > 0 || _yl > 0 || lt !is null) {
            assert (_xl > 0);
            assert (_yl > 0);
            assert (lt !is null);
            assert (lt.length == _xl * _yl);
        }
        else {
            assert (lt is null);
        }
    }
    +/



    void resize(in int a_xl, in int a_yl, in bool a_tx, in bool a_ty)
    in {
        assert (a_xl > 0);
        assert (a_yl > 0);
    }
    body {
        _xl = a_xl;
        _yl = a_yl;
        _tx = a_tx;
        _ty = a_ty;
        lt = new Phybitset[_xl * _yl];
    }



    Phybitset get(int x, int y) const
    {
        amend(x, y);
        return getAt(x, y);
    }



    bool get(int x, int y, Phybitset n) const
    {
        return (get(x, y) & n) != 0;
    }



    bool getSolid(int x, int y) const
    {
        return get(x, y, Phybit.terrain);
    }



    bool getSolidEven(int x, int y) const
    {
        assert (xl % 2 == 0, "can't call getSolidEven on an odd-xl Phymap");
        amend(x, y);
        // x & ~1 makes numbers even by zeroing the last bit
        // x |  1 makes numbers odd
        return ((getAt(x &~ 1, y)
               | getAt(x |  1, y)) & Phybit.terrain) != 0;
    }



    bool getSteel(int x, int y) const
    {
        if (get(x, y, Phybit.steel)) {
            assert (getSolid(x, y));
            return true;
        }
        else
            return false;
    }



    void rm(int x, int y, Phybitset n)
    {
        if (! amendIfInside(x, y)) return;
        rmAt(x, y, n);
    }



    void add(int x, int y, Phybitset n)
    {
        if (! amendIfInside(x, y)) return;
        addAt(x, y, n);
    }



    void rect(alias func, Args...)(
        int x, int y, int xr, int yr, Args args
    ) {
        for     (int ix = 0; ix < xr; ++ix)
            for (int iy = 0; iy < yr; ++iy)
                func(x + ix, y + iy, args);
    }

    int rectSum(alias func, Args...)(
        int x, int y, int xr, int yr, Args args)
    {
        int ret = 0;
        for     (int ix = 0; ix < xr; ++ix)
            for (int iy = 0; iy < yr; ++iy)
                ret += ! ! func(x + ix, y + iy, args);
        return ret;
    }



    void setSolid(int x, int y)
    {
        if (! amendIfInside(x, y)) return;
        addAt(x, y, Phybit.terrain);
    }



    bool setAirCountSteel(int x, int y)
    {
        if (! amendIfInside(x, y)) {
            return getSteel(x, y);
        }
        else if (getAt(x, y) & Phybit.steel) {
            assert (getAt(x, y) & Phybit.terrain);
            return true;
        }
        else {
            rmAt(x, y, Phybit.terrain);
            return false;
        }
    }



    // for testing
    public void saveToFile(in Filename fn) const
    {
        Albit outputBitmap = albitMemoryCreate(_xl, _yl);
        scope (exit)
            al_destroy_bitmap(outputBitmap);
        auto drata = DrawingTarget(outputBitmap);

        foreach (y; 0 .. _yl) foreach (x; 0 .. _xl) {
            immutable int red   = get(x, y, Phybit.terrain);
            immutable int green = get(x, y, Phybit.steel);
            immutable int blue  = get(x, y, Phybit.goal | Phybit.fire
                | Phybit.water | Phybit.trap | Phybit.fling | Phybit.trampo);
            al_put_pixel(x, y, AlCol(red, blue, green, 1));
        }
        al_save_bitmap(fn.rootfulZ, outputBitmap);
    }



private:

    int _xl;
    int _yl;

    bool _tx;
    bool _ty;

    // "lt" == "lookup table", aligned as row, row, row, row, ...
    // I don't use the matrix class here, the code was already
    // written in C++ without it and works well
    Phybitset[] lt;

    Phybitset getAt(int x, int y) const    { return lt[y * _xl + x]; }
    void  addAt(int x, int y, Phybitset n) { lt[y * _xl + x] |= n;   }
    void  rmAt (int x, int y, Phybitset n) { lt[y * _xl + x] &= ~n;  }

    void amend(ref int x, ref int y) const
    {
        x = _tx ? positiveMod(x, _xl)
          : x >= _xl ? _xl - 1
          : x <  0   ? 0 : x;
        y = _ty ? positiveMod(y, _yl)
          : y >= _yl ? _yl - 1
          : y <  0   ? 0 : y;
    }

    // Is the given point on the map?
    bool amendIfInside(ref int x, ref int y) const
    {
        if (! _tx && (x < 0 || x >= _xl)) return false;
        if (! _ty && (y < 0 || y >= _yl)) return false;
        amend(x, y);
        return true;
    }

}
// end class Phymap
