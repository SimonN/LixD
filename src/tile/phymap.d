module tile.phymap;

/* A lookup table for quick land/steel detection and backwards correspondence
 * of playfield positions to interactive objects.
 *
 * Two uses of this class:
 *  a) game uses it to look up physics.
 *  b) terrain/steel uses a small one, from which a) is generated.
 *
 * Water/fire/flingers/exits/hatches etc. don't use PhyMap to specify
 * trigger areas! The map in a) is drawn from the tile definitions,
 * not from any physics map in the tile.
 *
 * Right now, b) doesn't store pointers to objects. Thus, game can check
 * whether there is a trap at a given position, but it cannot
 * tell what exact gadget instance sits there. If necessary, the
 * gadget must be looked up manually in the list of gadgets of its type.
 */

import std.algorithm;
import std.range;
import std.string; // format assert errors

import basics.alleg5;
import basics.help;
import basics.topology;
import file.filename;
import physics.mask;

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

final class Phymap : Topology {

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
        assert (this.matches(rhs),
            "copy is implemented only between same size for speedup");
        assert (rhs.lt.length == lt.length);
        lt[] = rhs.lt[];
    }

    override void onResize()
    {
        lt.length = xl * yl;
    }

    Rect smallestNonzeroArea() const
    in {
        assert (! torusX && ! torusY, "this makes no sense on a torus");
    }
    out (ret) {
        assert (ret.xl <= this.xl);
        assert (ret.yl <= this.yl);
    }
    do {
        Rect ret = Rect(0, 0, xl, yl);
        // This relies on the representation of lt: column, column, column...
        // While the column at ret.y is all zeroes, smallen ret
        while (ret.yl > 0 && lt.drop(ret.y).stride(yl).allZero) {
            ++ret.y;
            --ret.yl;
        }
        while (ret.yl > 0 && lt.drop(ret.y + ret.yl - 1).stride(yl).allZero)
            --ret.yl;
        // Analyze a single column in the representation of lt
        while (ret.xl > 0 && lt.drop(ret.x * yl).take(yl).allZero) {
            ++ret.x;
            --ret.xl;
        }
        while (ret.xl > 0 && lt.drop((ret.x + ret.xl-1) * yl).take(yl).allZero)
            --ret.xl;
        return ret;
    }

    // Crop physics map to a given subarea of itself
    void cropTo(Rect rect)
    in {
        assert (rect.xl > 0);
        assert (rect.yl > 0);
        assert (rect.xl <= xl);
        assert (rect.yl <= yl);
    }
    do {
        if (rect.xl == xl && rect.yl == yl)
            return;
        Phybitset[] cropped = new Phybitset[rect.xl * rect.yl];
        // This implementation works for torus maps, too, but I never use that.
        foreach (x; 0 .. rect.xl)
            foreach (y; 0 .. rect.yl)
                cropped[x * rect.yl + y] = get(Point(rect.x + x, rect.y + y));
        resize(rect.xl, rect.yl);
        lt = cropped;
    }

    /*
     * get(p): return physics at the pixel p.
     * Desired change in Lix 0.10.0: Clamp only horizontally to force
     * out-of-bounds pixels onto the map. If p is out of bounds vertically,
     * always return featureless air. Diggers should not see floor beneath
     * the lowermost row, and walkers should walk out of the deadly ceiling.
     */
    Phybitset get(in Point p) const
    {
        if ((p.y < 0 || p.y >= yl) && ! torusY) {
            // Always hollow out of top and bottom.
            return 0;
        }
        return getAt(clamp(p));
    }

    bool getSolid(in Point p) const { return (get(p) & Phybit.terrain) != 0; }

    /*
     * getSolidEven: Stuff is solid at a 2x1 physics unit iff at least one
     * of its 1x1 pixels is solid.
     */
    bool getSolidEven(in Point p) const
    in {
        assert (xl % 2 == 0, "can't call getSolidEven on an odd-xl Phymap");
        assert (p.x % 2 == 0, "can only query double-pixels at even x");
    }
    do {
        return 0 != (Phybit.terrain & (get(p) | get(p + Point(1, 0))));
    }

    bool getSteel(in Point p) const
    out (ret) { if (ret) assert (getSolid(p)); }
    do { return (get(p) & Phybit.steel) != 0; }

    bool getSteelUnlessMaskIgnores(in Point eff, in Mask mask) const
    {
        with (mask) {
            immutable offset = Point(offsetX, offsetY);
            foreach (int x; 0 .. solid.xl)
                foreach (int y; 0 .. solid.yl) {
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
        for (int iy = 0; iy < re.yl; ++iy)
            for (int ix = 0; ix < re.xl; ++ix)
                func(Point(re.x + ix, re.y + iy), args);
    }

    int rectSum(alias func, Args...)(Rect re, Args args)
    {
        int ret = 0;
        for (int iy = 0; iy < re.yl; ++iy)
            for (int ix = 0; ix < re.xl; ++ix)
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
        foreach (int ix; 0 .. mask.solid.xl) {
            Point p = Point(topLeft.x + ix, 0);
            foreach (int iy; 0 .. mask.solid.yl) {
                p.y = topLeft.y + iy;
                if (mask.solid.get(ix, iy))
                    steelHit += setAirCountSteel(p);
            }
        }
        return steelHit;
    }

    // for testing
    void saveToFile() const
    {
        static int runningCount = 0;
        saveToFile(new VfsFilename("./phymap%03d.png".format(runningCount++)));
    }

    // for testing
    void saveToFile(in Filename fn) const
    {
        Albit outputBitmap = albitMemoryCreate(xl, yl);
        scope (exit)
            albitDestroy(outputBitmap);
        auto targetBitmap = TargetBitmap(outputBitmap);

        foreach (x; 0 .. xl) foreach (y; 0 .. yl) {
            immutable Point p = Point(x, y);
            immutable int red   = !!(get(p) & Phybit.terrain);
            immutable int green = !!(get(p) & Phybit.steel);
            immutable int blue  = !!(get(p) & (Phybit.goal | Phybit.fire
                        | Phybit.water | Phybit.trap | Phybit.fling));
            al_put_pixel(x, y, al_map_rgb_f(red, blue, green));
        }
        al_save_bitmap(fn.stringForWriting.toStringz, outputBitmap);
    }

private:
    // "lt" == "lookup table", aligned as column, column, column, ...
    // I don't use the matrix class here, the code was already
    // written in C++ without it and works well
    Phybitset[] lt;

    Phybitset getAt(in Point p) const { return lt[p.x * yl + p.y]; }
    void  addAt(in Point p, Phybitset n) { lt[p.x * yl + p.y] |= n;   }
    void  rmAt (in Point p, Phybitset n)
    {
        static assert (Phybitset.sizeof == 2);
        lt[p.x * yl + p.y] &= ~ cast(int) n;
    }

    bool inside(in Point p) const
    {
        if (! torusX && (p.x < 0 || p.x >= xl)) return false;
        if (! torusY && (p.y < 0 || p.y >= yl)) return false;
        return true;
    }
}

private alias allZero = all!(nr => nr == 0);

unittest {
    import std.conv : to;
    immutable Phybitset a = to!Phybitset(0x7F00);
    immutable Phybitset b = to!Phybitset(0x0400);
    immutable Phybitset difference = to!Phybitset(0x7B00);
    Phymap phymap = new Phymap(2, 2);
    phymap.add(Point(1, 1), a);
    phymap.rm (Point(1, 1), b);
    assert (phymap.get(Point(1, 1)) == difference);
}
