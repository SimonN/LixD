module tile.pos;

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
import tile.platonic;
import tile.gadtile;

abstract class AbstractPos {
public:
    Point point;

    abstract const(Platonic) ob() const;
    abstract IoLine    toIoLine() const;

    override bool opEquals(Object rhsObj)
    {
        auto rhs = cast (const AbstractPos) rhsObj;
        return rhs && ob is rhs.ob && point == rhs.point;
    }

    // The selection box, already shifted to the correct spot by x/y.
    // selboxX and selboxY return the land-unshifted start on the sprite.
    final @property Rect selboxOnMap() const
    {
        return Rect(point.x + selboxOnTile.x, point.y + selboxOnTile.y,
                              selboxOnTile.xl,          selboxOnTile.yl);
    }

protected:
    @property Rect selboxOnTile() const { assert (ob); return ob.selbox; }
}

class GadPos : AbstractPos {
public:
    const(GadgetTile) _ob;
    bool hatchRot;

    this(const(GadgetTile) tile) { _ob = tile; }
    override const(GadgetTile) ob() const { return _ob; }
    override bool opEquals(Object rhsObj)
    {
        auto rhs = cast (const GadPos) rhsObj;
        return rhs && hatchRot == rhs.hatchRot && super.opEquals(rhsObj);
    }

    override IoLine toIoLine() const
    {
        return IoLine.Colon(ob ? get_filename(ob) : null,
                point.x, point.y, hatchRot ? "r" : null);
    }

    // only for hatches
    @property Point screenCenter() const
    {
        assert (ob);
        return point + ob.trigger + Point(hatchRot ? -64 : 64, 0);
    }
}

class TerPos : AbstractPos {
    const(TerrainTile) _ob;
    bool mirr; // mirror vertically
    int  rot;  // rotate tile? 0 = normal, 1, 2, 3 = turned counter-clockwise
    bool dark; // Terrain loeschen anstatt neues malen
    bool noow; // Nicht ueberzeichnen?

    this(const(TerrainTile) tile) { _ob = tile; }
    override const(TerrainTile) ob() const { return _ob; }
    override bool opEquals(Object rhsObj)
    {
        auto rhs = cast (const TerPos) rhsObj;
        return rhs && mirr == rhs.mirr && rot  == rhs.rot
                   && dark == rhs.dark && noow == rhs.noow
                   && super.opEquals(rhsObj);
    }

    override IoLine toIoLine() const
    {
        string filename = ob ? get_filename(ob) : null;
        string modifiers;
        if (mirr) modifiers ~= 'f';
        foreach (r; 0 .. rot) modifiers ~= 'r';
        if (dark) modifiers ~= 'd';
        if (noow) modifiers ~= 'n';
        return IoLine.Colon(filename, point.x, point.y, modifiers);
    }

    auto phybitsOnMap(in Point p) const
    {
        assert (_ob);
        return _ob.getPhybitsXYRotMirr(p - point, rot, mirr);
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
        assert (ob);
        assert (ob.cb);
        int invX() { return ob.cb.xl - ob.selbox.x - ob.selbox.xl; }
        int invY() { return ob.cb.yl - ob.selbox.y - ob.selbox.yl; }
        switch (rot + plusRot) {
            case 0: case 4: return ob.selbox.x;
            case 1:         return mirr ? invY : ob.selbox.y;
            case 2:         return invX;
            case 3:         return mirr ? ob.selbox.y : invY;
            default: assert (false, "rotation should be 0, 1, 2, 3");
        }
    }

    @property int selboxLen(int plusRot)() const
        if (plusRot == 0 || plusRot == 1)
    {
        assert (ob);
        return (rot + plusRot) & 1 ? ob.selbox.yl : ob.selbox.xl;
    }
}
