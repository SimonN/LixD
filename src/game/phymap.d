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

import std.string; // format assert errors

import basics.alleg5;
import basics.help;
import basics.topology;
import file.filename;
import game.mask;

alias Phybitset = short;
enum  Phybit    : Phybitset {
    terrain = 0x0001,
    steel   = 0x0002,
    needCol = 0x0004, // Recently added terrain that need yet to be colored.
                      // Doesn't affect physics.
    goal    = 0x0010,
    fire    = 0x0040,
    water   = 0x0080,
    trap    = 0x0100,
    fling   = 0x0200,
    trampo  = 0x0400,
    all     = 0x7FFF,
}



class Phymap : Topology {

    this(
        in int xl, in int yl, in bool _tx = false, in bool _ty = false
    ) {
        super(xl, yl, _tx, _ty);
        lt = new Phybitset[xl * yl];
    }

    this(in typeof(this) rhs)
    {
        assert (rhs !is null);
        super(rhs);
        lt = rhs.lt.dup;
    }

    Phymap clone() const { return new Phymap(this); }

    void copyFrom(in typeof(this) rhs)
    {
        assert (rhs);
        assert (rhs.Topology.opEquals(this),
            "copy is implemented only between same size for speedup");
        assert (rhs.lt.length == lt.length);
        lt[] = rhs.lt[];
    }

    override void onResize()
    {
        lt = new Phybitset[xl * yl];
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

    bool getNeedsColoring(int x, int y) const
    {
        amend(x, y);
        return (getAt(x, y) & Phybit.needCol) != 0;
    }

    bool getSteelUnlessMaskIgnores(int ex, int ey, in Mask mask) const
    {
        with (mask)
            foreach (int y; 0 .. solid.yl)
                foreach (int x; 0 .. solid.xl)
                    if (solid.get(x, y)
                        && (ignoreSteel is null || ! ignoreSteel.get(x, y))
                        && getSteel(ex + x - offsetX, ey + y - offsetY))
                        return true;
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

    void setSolidAlreadyColored(int x, int y)
    {
        if (! amendIfInside(x, y)) return;
        addAt(x, y, Phybit.terrain);
    }

    void setSolidNeedsColoring(int x, int y)
    {
        if (! amendIfInside(x, y)) return;
        if (getAt(x, y) & Phybit.terrain) return;
        addAt(x, y, Phybit.terrain | Phybit.needCol);
    }

    void setDoneColoring(int x, int y)
    {
        string assertMsg()
        {
            return "x=%d, y=%d, terrain=%d, needCol=%d".format(x, y,
                getAt(x, y) & Phybit.terrain, getAt(x, y) & Phybit.needCol);
        }
        if (! amendIfInside(x, y)) return;
        assert (getAt(x, y) & Phybit.terrain, assertMsg);
        assert (getAt(x, y) & Phybit.needCol, assertMsg);
        rmAt(x, y, Phybit.needCol);
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
            rmAt(x, y, Phybit.terrain | Phybit.needCol);
            return false;
        }
    }

    // this is called not with lix's ex, ey, but with the top-left coordinate
    // of where the mask should be applied. Thus, during this function,
    // never refer to mask.offsetX/Y.
    int setAirCountSteelEvenWhereMaskIgnores(
        int topLeftX, int topLeftY, in Mask mask
    ) {
        assert (mask.solid);
        int steelHit = 0;
        foreach (int iy; 0 .. mask.solid.yl) {
            int y = topLeftY + iy;
            foreach (int ix; 0 .. mask.solid.xl) {
                int x = topLeftX + ix;
                if (mask.solid.get(ix, iy))
                    steelHit += setAirCountSteel(ix + topLeftX, iy + topLeftY);
            }
        }
        return steelHit;
    }

    // for testing
    public void saveToFile(in Filename fn) const
    {
        Albit outputBitmap = albitMemoryCreate(xl, yl);
        scope (exit)
            al_destroy_bitmap(outputBitmap);
        auto drata = DrawingTarget(outputBitmap);

        foreach (y; 0 .. yl) foreach (x; 0 .. xl) {
            immutable int red   = get(x, y, Phybit.terrain);
            immutable int green = get(x, y, Phybit.steel);
            immutable int blue  = get(x, y, Phybit.goal | Phybit.fire
                | Phybit.water | Phybit.trap | Phybit.fling | Phybit.trampo);
            al_put_pixel(x, y, AlCol(red, blue, green, 1));
        }
        al_save_bitmap(fn.rootfulZ, outputBitmap);
    }



private:

    // "lt" == "lookup table", aligned as row, row, row, row, ...
    // I don't use the matrix class here, the code was already
    // written in C++ without it and works well
    Phybitset[] lt;

    Phybitset getAt(int x, int y) const    { return lt[y * xl + x]; }
    void  addAt(int x, int y, Phybitset n) { lt[y * xl + x] |= n;   }
    void  rmAt (int x, int y, Phybitset n) { lt[y * xl + x] &= ~n;  }

    void amend(ref int x, ref int y) const
    {
        x = torusX ? positiveMod(x, xl)
          : x >= xl ? xl - 1
          : x <  0  ? 0 : x;
        y = torusY ? positiveMod(y, yl)
          : y >= yl ? yl - 1
          : y <  0  ? 0 : y;
    }

    // Is the given point on the map?
    bool amendIfInside(ref int x, ref int y) const
    {
        if (! torusX && (x < 0 || x >= xl)) return false;
        if (! torusY && (y < 0 || y >= yl)) return false;
        amend(x, y);
        return true;
    }

}
// end class Phymap
