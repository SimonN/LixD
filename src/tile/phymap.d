module tile.phymap;

/* A lookup table for quick land/steel detection and backwards correspondence
 * of playfield positions to interactive objects.
 *
 * Two uses of this class:
 *  a) game uses it to look up physics.
 *  b) terrain/steel uses a small one, from which a) is generated.
 *
 * But watchout: Water/fire/flingers/exits/hatches etc. don't use a physicsmap
 * to specify their trigger areas! The map in a) is composed from the tile
 * definitions, not from the physicsmap in the tile.
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
    goal    = 0x0010,
    fire    = 0x0040,
    water   = 0x0080,
    trap    = 0x0100,
    fling   = 0x0200,
    all     = 0x7FFF,
}

class Phymap : Topology {

    this(in int xl, in int yl, in bool _tx = false, in bool _ty = false) {
        super(xl, yl, _tx, _ty);
        lt = new Phybitset[xl * yl];
    }

    this(in Topology topology)
    {
        super(topology);
        lt = new Phybitset[topology.xl * topology.yl];
    }

    override Phymap clone() const { return new Phymap(this); }
    this(in typeof(this) rhs)
    {
        assert (rhs !is null);
        super(rhs);
        lt = rhs.lt.dup;
    }

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

    Phybitset get(in Point p)              const { return getAt(clamp(p));   }
    bool      get(in Point p, Phybitset n) const { return (get(p) & n) != 0; }

    bool getSolid(in Point p) const { return (get(p) & Phybit.terrain) != 0; }
    bool getSolidEven(in Point p) const
    {
        assert (xl % 2 == 0, "can't call getSolidEven on an odd-xl Phymap");
        // x & ~1 makes numbers even by zeroing the last bit
        // x |  1 makes numbers odd
        return ((getAt(clamp(Point(p.x & ~1, p.y)))
               | getAt(clamp(Point(p.x |  1, p.y)))) & Phybit.terrain) != 0;
    }

    bool getSteel(in Point p) const
    out (ret) { if (ret) assert (getSolid(p)); }
    body      { return get(p, Phybit.steel);   }

    bool getSteelUnlessMaskIgnores(in Point eff, in Mask mask) const
    {
        with (mask) {
            immutable offset = Point(offsetX, offsetY);
            foreach (int y; 0 .. solid.yl)
                foreach (int x; 0 .. solid.xl) {
                    immutable p = Point(x, y);
                    if (solid.get(x, y)
                        && (ignoreSteel is null || ! ignoreSteel.get(x, y))
                        && getSteel(eff + p - offset))
                        return true;
                }
        }
        return false;
    }

    void rm(in Point p, Phybitset n)
    {
        if (inside(p))
            rmAt(wrap(p), n);
    }

    void add(in Point p, Phybitset n)
    {
        if (inside(p))
            addAt(wrap(p), n);
    }

    void rect(alias func, Args...)(Rect re, Args args)
    {
        for     (int ix = 0; ix < re.xl; ++ix)
            for (int iy = 0; iy < re.yl; ++iy)
                func(Point(re.x + ix, re.y + iy), args);
    }

    int rectSum(alias func, Args...)(Rect re, Args args)
    {
        int ret = 0;
        for     (int ix = 0; ix < re.xl; ++ix)
            for (int iy = 0; iy < re.yl; ++iy)
                ret += ! ! func(Point(re.x + ix, re.y + iy), args);
        return ret;
    }

    void setSolidAlreadyColored(in Point p)
    {
        if (inside(p))
            addAt(wrap(p), Phybit.terrain);
    }

    bool setAirCountSteel(in Point p)
    {
        immutable wrapped = wrap(p);
        if (! inside(p))
            return getSteel(p);
        else if    (getAt(wrapped) & Phybit.steel) {
            assert (getAt(wrapped) & Phybit.terrain);
            return true;
        }
        else {
            rmAt(wrapped, Phybit.terrain);
            return false;
        }
    }

    // this is called not with lix's ex, ey, but with the top-left coordinate
    // of where the mask should be applied. Thus, during this function,
    // never refer to mask.offsetX/Y.
    int setAirCountSteelEvenWhereMaskIgnores(in Point topLeft, in Mask mask)
    {
        assert (mask.solid);
        int steelHit = 0;
        foreach (int iy; 0 .. mask.solid.yl) {
            Point p = Point(0, topLeft.y + iy);
            foreach (int ix; 0 .. mask.solid.xl) {
                p.x = topLeft.x + ix;
                if (mask.solid.get(ix, iy))
                    steelHit += setAirCountSteel(p);
            }
        }
        return steelHit;
    }

    // for testing
    void saveToFile(in Filename fn) const
    {
        Albit outputBitmap = albitMemoryCreate(xl, yl);
        scope (exit)
            al_destroy_bitmap(outputBitmap);
        auto drata = DrawingTarget(outputBitmap);

        foreach (y; 0 .. yl) foreach (x; 0 .. xl) {
            immutable Point p = Point(x, y);
            immutable int red   = get(p, Phybit.terrain);
            immutable int green = get(p, Phybit.steel);
            immutable int blue  = get(p, Phybit.goal | Phybit.fire
                        | Phybit.water | Phybit.trap | Phybit.fling);
            al_put_pixel(x, y, AlCol(red, blue, green, 1));
        }
        al_save_bitmap(fn.rootfulZ, outputBitmap);
    }

private:
    // "lt" == "lookup table", aligned as row, row, row, row, ...
    // I don't use the matrix class here, the code was already
    // written in C++ without it and works well
    Phybitset[] lt;

    Phybitset getAt(in Point p) const    { return lt[p.y * xl + p.x]; }
    void  addAt(in Point p, Phybitset n) { lt[p.y * xl + p.x] |= n;   }
    void  rmAt (in Point p, Phybitset n) { lt[p.y * xl + p.x] &= ~n;  }

    bool inside(in Point p) const
    {
        if (! torusX && (p.x < 0 || p.x >= xl)) return false;
        if (! torusY && (p.y < 0 || p.y >= yl)) return false;
        return true;
    }
}
