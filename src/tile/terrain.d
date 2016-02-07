module tile.terrain;

/* Tiles can be gadgets or terrain pieces.
 *
 * Terrain pieces come with a matrix in RAM to specify where they're solid.
 * It would be a waste to load the graphic from RAM into VRAM every time
 * we draw the tile on the land.
 */

import basics.alleg5;
import graphic.cutbit;
import graphic.color;
import tile.phymap;
import tile.platonic;

class TerrainTile : Platonic {
private:
    Phymap _phymap;
    bool   _steel;

public:
    @property bool steel() const { return _steel; }

    static typeof(this) takeOverCutbit(Cutbit aCb, bool aSteel = false)
    {
        return new typeof(this)(aCb, aSteel);
    }

    // Input: Where you want to draw on the map, in relation to tile's 0, 0.
    // Output: The solid/nonsolid bits there of the rotated/mirrored tile
    Phybitset getPhybitsXYRotMirr(
        in int gx, in int gy, in int rot, in bool mirr) const
    {
        assert (_phymap);
        // The algorithm for rotation and mirroring is:
        // First mirror vertically, if the mirr flag is true.
        // The resulting thing, turn it by rot * 90 degrees ccw.
        // Here's some code copy-pasted from graphic.graphic.get_pixel.
        int useX = void, useY = void;
        with (_phymap) switch (rot & 3) {
            case 0: useX = gx;      useY = ! mirr ? gy      : yl-gy-1; break;
            case 1: useX = gy;      useY = ! mirr ? yl-gx-1 : gx;      break;
            case 2: useX = xl-gx-1; useY = ! mirr ? yl-gy-1 : gy;      break;
            case 3: useX = xl-gy-1; useY = ! mirr ? gx      : yl-gx-1; break;
            default: assert(false);
        }
        assert (0 <= useX && useX < _phymap.xl);
        assert (0 <= useY && useY < _phymap.yl);
        return _phymap.get(useX, useY);
    }

protected:
    this(Cutbit aCb, bool aSteel = false)
    {
        super(aCb);
        _steel = aSteel;
        makePhymapFindSelbox();
    }

private:
    void makePhymapFindSelbox()
    {
        assert (! _phymap);
        assert (cb);
        _phymap = new Phymap(cb.xl, cb.yl);
        immutable Phybitset bits = Phybit.terrain | (steel ? Phybit.steel : 0);
        with (LockReadOnly(cb.albit)) {
            super.findSelboxAssumeLocked();
            foreach (y; 0 .. _phymap.yl)
                foreach (x; 0 .. _phymap.xl)
                    if (cb.get_pixel(x, y) != color.transp)
                        _phymap.add(x, y, bits);
        }
    }
}
