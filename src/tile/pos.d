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
    int x;
    int y;

    abstract const(Platonic) ob() const;
    abstract IoLine    toIoLine() const;

    override bool opEquals(Object rhsObj)
    {
        auto rhs = cast (const AbstractPos) rhsObj;
        return rhs && ob is rhs.ob && x == rhs.x && y == rhs.y;
    }

    // The selection box, already shifted to the correct spot by x/y.
    // selboxX and selboxY return the land-unshifted start on the sprite.
    final @property Rect selbox() const
    {
        return Rect(x + selboxX, y + selboxY, selboxXl, selboxYl);
    }

    final @property Point point() const { return Point(x, y); }
    final @property Point point(in Point p)
    {
        x = p.x;
        y = p.y;
        return this.point();
    }

protected:
    @property int selboxX()  const { assert (ob); return ob.selboxX;  }
    @property int selboxY()  const { assert (ob); return ob.selboxY;  }
    @property int selboxXl() const { assert (ob); return ob.selboxXl; }
    @property int selboxYl() const { assert (ob); return ob.selboxYl; }
}

class GadPos : AbstractPos {
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
                x, y, hatchRot ? "r" : null);
    }

    // only for hatches
    @property int centerOnX() const
    {
        assert (ob);
        return x + ob.triggerX + (hatchRot ? -64 : 64);
    }

    @property int centerOnY() const
    {
        assert (ob);
        return y + ob.triggerY + 32;
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
        return IoLine.Colon(filename, x, y, modifiers);
    }

    auto phybitsOnMap(in Point p) const
    {
        assert (_ob);
        return _ob.getPhybitsXYRotMirr(p.x - x, p.y - y, rot, mirr);
    }

protected:
    // Return selbox of terrain tile, but affected by rotation and mirroring.
    // Mirroring occurs first, then rotation. The selbox (selection box)
    // says where the editor should draw a frame around the selected tile.
    override @property int selboxX()  const { return selboxStart!0; }
    override @property int selboxY()  const { return selboxStart!1; }
    override @property int selboxXl() const { return selboxLen!0; }
    override @property int selboxYl() const { return selboxLen!1; }

private:
    @property int selboxStart(int plusRot)() const
        if (plusRot == 0 || plusRot == 1)
    {
        assert (ob);
        assert (ob.cb);
        int invX() { return ob.cb.xl - ob.selboxX - ob.selboxXl; }
        int invY() { return ob.cb.yl - ob.selboxY - ob.selboxYl; }
        switch (rot + plusRot) {
            case 0: case 4: return ob.selboxX;
            case 1:         return mirr ? invY : ob.selboxY;
            case 2:         return invX;
            case 3:         return mirr ? ob.selboxY : invY;
            default: assert (false, "rotation should be 0, 1, 2, 3");
        }
    }

    @property int selboxLen(int plusRot)() const
        if (plusRot == 0 || plusRot == 1)
    {
        assert (ob);
        return (rot + plusRot) & 1 ? ob.selboxYl : ob.selboxXl;
    }
}
