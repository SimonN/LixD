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
    struct Can {
        bool rotate;
        bool mirror;
        bool darken;
    }

    immutable Can can;

    /* loc: location of the occurrence. This is the top-left corner of the
     * entire image (cutbitOnMap). The selection box's map coordinates
     * (selboxOnMap) may too start here (this.selboxOnMap.topLeft == this.loc).
     * If the tile has transparent borders around visible pixels, the selbox is
     * smaller than the cutbit, therefore this.selboxOnMap.topLeft is
     * >= loc in each direction, in general.
     * The editor snaps loc to the grid, not selboxOnMap.topLeft.
     *
     *  A-------------------+   A: loc
     *  |                B  |   B: cutbitOnMap -- transp around visible pixels
     *  |  C---------+      |   C: selboxOnMap.topLeft
     *  |  |    D    |      |   D: selbox (smallest rect with visible pixels)
     *  |  |         |      |
     *  |  +---------+      |   B is equal or larger than D.
     *  +-------------------+
     */
    Point loc;

protected:
    this(in Can aCan) { can = aCan; }

public:
    abstract Occurrence clone() const;
    abstract const(AbstractTile) tile() const pure nothrow @safe @nogc;
    abstract IoLine toIoLine() const;

    override bool opEquals(Object rhsObj)
    {
        auto rhs = cast (const Occurrence) rhsObj;
        return rhs && tile is rhs.tile && loc == rhs.loc;
    }

    @property const {
        final Rect selboxOnMap() { return selboxOnTile + loc; }
        final Rect cutbitOnMap() { return cutbitOnTile + loc; }

        Rect selboxOnTile() { assert (tile); return tile.selbox; }
        Rect cutbitOnTile()
        {
            assert (tile);
            return Rect(0, 0, tile.cb.xl, tile.cb.yl);
        }
    }

    /*
     * It's only legal to call these when the corresponding can.* is true.
     * Override the following when the corresponding can.* may be true.
     */
    @property pure nothrow @safe @nogc {
        int rotCw() const
        in { assert (can.rotate); } body { return 0; }
        int rotCw(int)
        in { assert (can.rotate); } body { return 0; }

        bool mirrY() const
        in { assert (can.mirror); } body { return false; }
        bool mirrY(bool)
        in { assert (can.mirror); } body { return false; }

        bool dark() const
        in { assert (can.darken); } body { return false; }
        bool dark(bool)
        in { assert (can.darken); } body { return false; }
    }

    version (assert) {
        override string toString() const
        {
            import std.format;
            import std.range;
            import std.array;
            return format!"%s at %s %s%s%s"(tile.name, loc,
                'r'.repeat(can.rotate ? rotCw : 0).array,
                'f'.repeat(can.mirror ? mirrY : 0).array,
                'd'.repeat(can.darken ? dark : 0).array);
        }
    }
}

class GadOcc : Occurrence {
private:
    bool _hatchRot;
    const(GadgetTile) _tile;

public:
    this(const(GadgetTile) t)
    {
        _tile = t;
        super(Can(false, _tile.type == GadType.HATCH, false));
    }

    override GadOcc clone() const
    {
        auto ret = new GadOcc(tile);
        ret.loc = loc;
        ret._hatchRot = _hatchRot;
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

    final override @property pure nothrow @safe @nogc {
        bool mirrY() const { return _hatchRot; }
        bool mirrY(bool b) { return _hatchRot = b; }
    }

    @property bool hatchRot() const pure nothrow @safe @nogc
    {
        return _hatchRot;
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
private:
    const(TerrainTile) _tile;
    bool _mirrY; // mirror vertically, happens before rotation
    int  _rotCw; // rotate tile after mirrY? 0 = no, 1, 2, 3 = turned clockwise
    bool _dark;  // where solid pixels would be drawn, erase exisiting pixels

public:
    bool noow;  // only draw pixels into air; may be culled in the future

    this(const(TerrainTile) t, Point p = Point())
    {
        _tile = t;
        super(Can(true, true, true));
        loc = p;
    }

    override TerOcc clone() const
    {
        auto ret = new TerOcc(tile);
        ret.loc = loc;
        ret.noow  = noow;
        ret._mirrY = _mirrY;
        ret._rotCw = _rotCw;
        ret._dark  = _dark;
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

    final override @property pure nothrow @safe @nogc {
        int rotCw() const { return _rotCw; }
        int rotCw(int r) { return _rotCw = r % 4; }
        bool mirrY() const { return _mirrY; }
        bool mirrY(bool b) { return _mirrY = b; }
        bool dark() const { return _dark; }
        bool dark(bool b) { return _dark = b; }
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

    override @property Rect cutbitOnTile() const
    {
        assert (_tile);
        return Rect(0, 0, (rotCw % 2 == 0) ? tile.cb.xl : tile.cb.yl,
                          (rotCw % 2 == 0) ? tile.cb.yl : tile.cb.xl);
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
