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
    Point point;

    abstract Occurrence clone() const
    out (ret) { assert (ret); }
    body { return null; }

    abstract const(AbstractTile) tile() const;
    abstract IoLine    toIoLine() const;

    override bool opEquals(Object rhsObj)
    {
        auto rhs = cast (const Occurrence) rhsObj;
        return rhs && tile is rhs.tile && point == rhs.point;
    }

    // The selection box, already shifted to the correct spot by x/y.
    // selboxX and selboxY return the land-unshifted start on the sprite.
    final @property Rect selboxOnMap() const
    {
        return Rect(point.x + selboxOnTile.x, point.y + selboxOnTile.y,
                              selboxOnTile.xl,          selboxOnTile.yl);
    }

protected:
    @property Rect selboxOnTile() const { assert (tile); return tile.selbox; }
}

class GadOcc : Occurrence {
public:
    const(GadgetTile) _tile;
    bool hatchRot;

    this(const(GadgetTile) t) { _tile = t; }

    override GadOcc clone() const
    {
        auto ret     = new GadOcc(tile);
        ret.point    = point;
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
        return IoLine.Colon(tile ? get_filename(tile) : null,
                point.x, point.y, hatchRot ? "r" : null);
    }

    // only for hatches
    @property Point screenCenter() const
    {
        assert (tile);
        return point + tile.trigger + Point(hatchRot ? -64 : 64, 64);
    }
}

class TerOcc : Occurrence {
    const(TerrainTile) _tile;
    bool mirr; // mirror vertically
    int  rot;  // rotate tile? 0 = normal, 1, 2, 3 = turned counter-clockwise
    bool dark; // wherever a solid pixel would be drawn, erase exisiting pixels
    bool noow; // only draw pixels into air; may be culled in the future

    this(const(TerrainTile) t) { _tile = t; }

    override TerOcc clone() const
    {
        auto ret  = new TerOcc(tile);
        ret.point = point;
        ret.mirr  = mirr;
        ret.rot   = rot;
        ret.dark  = dark;
        ret.noow  = noow;
        return ret;
    }

    override const(TerrainTile) tile() const { return _tile; }
    override bool opEquals(Object rhsObj)
    {
        auto rhs = cast (const TerOcc) rhsObj;
        return rhs && mirr == rhs.mirr && rot  == rhs.rot
                   && dark == rhs.dark && noow == rhs.noow
                   && super.opEquals(rhsObj);
    }

    override IoLine toIoLine() const
    {
        string filename = tile ? get_filename(tile) : null;
        string modifiers;
        if (mirr) modifiers ~= 'f';
        foreach (r; 0 .. rot) modifiers ~= 'r';
        if (dark) modifiers ~= 'd';
        if (noow) modifiers ~= 'n';
        return IoLine.Colon(filename, point.x, point.y, modifiers);
    }

    auto phybitsOnMap(in Point p) const
    {
        assert (_tile);
        return _tile.getPhybitsXYRotMirr(p - point, rot, mirr);
    }

protected:
    // Return selbox of terrain tile, but affected by rotation and mirroring.
    // Mirroring occurs first, then rotation. The selbox (selection box)
    // says where the editor should draw a frame around the selected tile.
    override @property Rect selboxOnTile() const
    {
        return Rect(selboxStart!0, selboxStart!1, selboxLen!0, selboxLen!1);
    }

private:
    @property int selboxStart(int plusRot)() const
        if (plusRot == 0 || plusRot == 1)
    {
        assert (_tile);
        assert (_tile.cb);
        int invX() { return _tile.cb.xl - _tile.selbox.x - _tile.selbox.xl; }
        int invY() { return _tile.cb.yl - _tile.selbox.y - _tile.selbox.yl; }
        switch (rot + plusRot) {
            case 0: case 4: return _tile.selbox.x;
            case 1:         return mirr ? invY : _tile.selbox.y;
            case 2:         return invX;
            case 3:         return mirr ? _tile.selbox.y : invY;
            default: assert (false, "rotation should be 0, 1, 2, 3");
        }
    }

    @property int selboxLen(int plusRot)() const
        if (plusRot == 0 || plusRot == 1)
    {
        assert (_tile);
        return (rot + plusRot) & 1 ? _tile.selbox.yl : _tile.selbox.xl;
    }
}
