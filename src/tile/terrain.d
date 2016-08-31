module tile.terrain;

/* Tiles can be gadgets or terrain pieces.
 *
 * Terrain pieces come with a matrix in RAM to specify where they're solid.
 * It would be a waste to load the graphic from RAM into VRAM every time
 * we draw the tile on the land.
 *
 * Terrain tiles do not have names or filenames. Instead, tile.tilelib
 * maintains the global associative array of terrain.
 */

import basics.alleg5;
import basics.rect;
import graphic.cutbit;
import graphic.color;
import hardware.tharsis;
import tile.phymap;
import tile.abstile;

class TerrainTile : AbstractTile {
private:
    Phymap _phymap; // not the game's physics map, but the tile's map!
    Cutbit _dark; // same transparent pixels, but all nontransp are full white
    immutable string _name;

public:
    static typeof(this) takeOverCutbit(string aName, Cutbit aCb, bool aSteel)
    {
        if (! aCb || ! aCb.valid)
            return null;
        return new typeof(this)(aName, aCb, aSteel);
    }

    @property const(Cutbit) dark()  const { return _dark; }
    override @property string name() const { return _name; }

    // Input: Where you want to draw on the map, in relation to tile's 0, 0.
    // Output: The solid/nonsolid bits there of the rotated/mirrored tile
    // It is illegal to call this such that result is outside of tile.
    Phybitset getPhybitsXYRotMirr(in Point g, in int rot, in bool mirr) const
    in {
        assert (_phymap);
        import std.algorithm;
        immutable bound = max(_phymap.xl, _phymap.yl);
        import std.string;
        assert (0 <= g.x && g.x < bound,
            "input point's x = %d is not inside [0, %d[".format(g.x, bound));
        assert (0 <= g.y && g.y < bound,
            "input point's y = %d is not inside [0, %d[".format(g.y, bound));
    }
    body {
        // The algorithm for rotation and mirroring is:
        // First mirror vertically, if the mirr flag is true.
        // The resulting thing, turn it by rot * 90 degrees ccw.
        // Here's some code copy-pasted from graphic.graphic.get_pixel.
        Point u; // use this point for lookup
        with (_phymap) switch (rot & 3) {
            case 0: u.x = g.x;      u.y = !mirr ? g.y      : yl-g.y-1; break;
            case 1: u.x = g.y;      u.y = !mirr ? yl-g.x-1 : g.x;      break;
            case 2: u.x = xl-g.x-1; u.y = !mirr ? yl-g.y-1 : g.y;      break;
            case 3: u.x = xl-g.y-1; u.y = !mirr ? g.x      : yl-g.x-1; break;
            default: assert(false);
        }
        import std.string;
        assert (0 <= u.x && u.x < _phymap.xl
            &&  0 <= u.y && u.y < _phymap.yl, format(
            "Bad terrain tile rotation coordinate resolution. "
            "point=%s, rot=%d, mirr=%d, result=%s. "
            "Expected 0 <= %d < %d and 0 <= %d < %d.", g.toString, rot, mirr,
            u.toString, u.x, _phymap.xl, u.y, _phymap.yl));
        return _phymap.get(u);
    }

protected:
    this(string aName, Cutbit aCb, bool aSteel = false)
    {
        super(aCb);
        _name = aName;
        makePhymapFindSelbox(aSteel);
        makeDarkVersion();
    }

    // Take over the cutbit and the Phymap
    this(string aName, Cutbit aCb, Phymap aPhm)
    {
        super(aCb);
        _name = aName;
        _phymap = aPhm;
        makeDarkVersion();
    }

private:
    void makePhymapFindSelbox(bool steel)
    {
        assert (! _phymap);
        assert (cb);
        version (tharsisprofiling)
            auto zone = Zone(profiler, "Terrain.makePhymapFindSelbox");
        _phymap = new Phymap(cb.xl, cb.yl);
        immutable Phybitset bits = Phybit.terrain | (steel ? Phybit.steel : 0);
        with (LockReadOnly(cb.albit)) {
            super.findSelboxAssumeLocked();
            Point p = Point();
            for (    p.y = 0; p.y < _phymap.yl; ++p.y)
                for (p.x = 0; p.x < _phymap.xl; ++p.x)
                    if (cb.get_pixel(p) != color.transp)
                        _phymap.add(p, bits);
        }
    }

    void makeDarkVersion()
    {
        assert (! _dark);
        assert (cb);
        assert (_phymap);
        version (tharsisprofiling)
            auto zone = Zone(profiler, "Terrain.makeDarkVersion");
        _dark = new Cutbit(albitCreate(_phymap.xl, _phymap.yl), false);
        Point p = Point();
        with (LockWriteOnly(_dark.albit))
            with (TargetBitmap(_dark.albit))
                for (    p.y = 0; p.y < _phymap.yl; ++p.y)
                    for (p.x = 0; p.x < _phymap.xl; ++p.x)
                        al_put_pixel(p.x, p.y, _phymap.get(p)
                            ? color.white : color.transp);
    }
}
