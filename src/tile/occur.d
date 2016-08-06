module tile.occur;

/* Pos is a single instance of a Tile in the level. A Tile can thus appear
 * many times in a level, differently rotated.
 *
 * This doesn't yet come with any information on how to draw the tile.
 * Moving and drawing on torus maps might be done differently than normal.
 */

public import basics.rect;

import file.io;
import tile.tilelib;
import tile.terrain;
import tile.abstile;
import tile.gadtile;

abstract class Occurrence {
public:
    /* loc: location of the occurrence. This is the top-left corner of the
     * entire image. The selection box's map coordinates (selboxOnMap)
     * may too start here (this.selboxOnMap.topLeft == this.loc). If the tile
     * has transparent borders around visible pixels, the selection box is
     * smaller than the bitmap, therefore this.selboxOnMap.topLeft is
     * >= loc in each direction, in general.
     * The editor snaps loc to the grid, not selboxOnMap.topLeft.
     *
     *  A-------------------+   A: loc
     *  |                B  |   B: transparent border around visible pixels
     *  |  C---------+      |   C: selboxOnMap.topLeft
     *  |  |    D    |      |   D: selbox (smallest rect with visible pixels)
     *  |  |         |      |
     *  |  +---------+      |
     *  +-------------------+
     */
    Point loc;

    abstract Occurrence clone() const
    out (ret) { assert (ret); }
    body { return null; }

    abstract @safe const(AbstractTile) tile() const pure nothrow;
    abstract IoLine toIoLine() const;

    override bool opEquals(Object rhsObj)
    {
        auto rhs = cast (const Occurrence) rhsObj;
        return rhs && tile is rhs.tile && loc == rhs.loc;
    }

    final @property Rect selboxOnMap() const { return selboxOnTile + loc; }

    @property Rect selboxOnTile() const { assert (tile); return tile.selbox; }
}

class GadOcc : Occurrence {
public:
    const(GadgetTile) _tile;
    bool hatchRot;

    this(const(GadgetTile) t) { _tile = t; }

    override GadOcc clone() const
    {
        auto ret = new GadOcc(tile);
        ret.loc = loc;
        ret.hatchRot = hatchRot;
        return ret;
    }

    override const(GadgetTile) tile() const { return _tile; }
    override bool opEquals(Object rhsObj)
    {
        auto rhs = cast (const GadOcc) rhsObj;
        return rhs && hatchRot == rhs.hatchRot && super.opEquals(rhsObj);
    }

    override IoLine toIoLine() const
    {
        assert (_tile);
        return IoLine.Colon(_tile.name, loc.x, loc.y, hatchRot ? "r" : "");
    }

    @property Rect triggerAreaOnMap() const
    {
        assert (_tile);
        return tile.triggerArea + loc;
    }

    // only for hatches
    @property Point screenCenter() const
    {
        assert (tile);
        return loc + tile.trigger + Point(hatchRot ? -64 : 64, 32);
    }
}

class TerOcc : Occurrence {
public:
    const(TerrainTile) _tile;
    bool mirrY; // mirror vertically, happens before rotation
    int  rotCw; // rotate tile after mirrY? 0 = no, 1, 2, 3 = turned clockwise
    bool dark;  // wherever solid pixels would be drawn, erase exisiting pixels
    bool noow;  // only draw pixels into air; may be culled in the future

    this(const(TerrainTile) t, Point p = Point())
    {
        _tile = t;
        loc = p;
    }

    override TerOcc clone() const
    {
        auto ret = new TerOcc(tile);
        ret.loc = loc;
        ret.mirrY = mirrY;
        ret.rotCw = rotCw;
        ret.dark  = dark;
        ret.noow  = noow;
        return ret;
    }

    override const(TerrainTile) tile() const { return _tile; }
    override bool opEquals(Object rhsObj)
    {
        auto rhs = cast (const TerOcc) rhsObj;
        return rhs && mirrY == rhs.mirrY && rotCw == rhs.rotCw
                   && dark  == rhs.dark  && noow  == rhs.noow
                   && super.opEquals(rhsObj);
    }

    override IoLine toIoLine() const
    {
        string modifiers;
        if (mirrY) modifiers ~= 'f';
        foreach (r; 0 .. rotCw) modifiers ~= 'r';
        if (dark) modifiers ~= 'd';
        if (noow) modifiers ~= 'n';
        assert (_tile);
        return IoLine.Colon(_tile.name, loc.x, loc.y, modifiers);
    }

    auto phybitsOnMap(in Point pointOnMap) const
    {
        assert (_tile);
        return _tile.getPhybitsXYRotMirr(pointOnMap - loc, rotCw, mirrY);
    }

    // Return selbox of terrain tile, but affected by rotation and mirroring.
    // Mirroring is vertically, even though the editor button mirrors
    // horizontally. Reason: The editor button mirrors, then rotates twice.
    // Mirroring occurs first, then rotation. The selbox (selection box)
    // says where the editor should draw a frame around the selected tile.
    override @property Rect selboxOnTile() const
    {
        return Rect(selboxStart!0, selboxStart!3, selboxLen!0, selboxLen!1);
    }

private:
    @property int selboxStart(int plusRot)() const
        if (plusRot == 0 || plusRot == 3) {
        with (_tile)
    {
        assert (_tile);
        assert (cb);
        if (! mirrY)
            switch ((rotCw + plusRot) & 3) {
                case 1:  return cb.yl - selbox.y - selbox.yl;
                case 2:  return cb.xl - selbox.x - selbox.xl;
                case 3:  return _tile.selbox.y;
                default: return _tile.selbox.x;
            }
        else
            // Vertical mirroring happens first, then ccw rotation.
            switch ((rotCw + plusRot) & 3) {
                case 1:  return _tile.selbox.y;
                case 2:  return cb.xl - selbox.x - selbox.xl;
                case 3:  return cb.yl - selbox.y - selbox.yl;
                default: return _tile.selbox.x;
            }
    }}

    @property int selboxLen(int plusRot)() const
        if (plusRot == 0 || plusRot == 1)
    {
        assert (_tile);
        return (rotCw + plusRot) & 1 ? _tile.selbox.yl : _tile.selbox.xl;
    }
}
