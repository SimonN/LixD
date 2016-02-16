module tile.pos;

/* Pos is a single instance of a Tile in the level. A Tile can thus appear
 * many times in a level, differently rotated.
 *
 * This doesn't yet come with any information on how to draw the tile.
 * Moving and drawing on torus maps might be done differently than normal.
 */

import file.io;
import tile.tilelib;
import tile.terrain;
import tile.platonic;
import tile.gadtile;

struct GadPos {
    const(GadgetTile) ob;
    int  x;
    int  y;
    bool hatchRot;

    IoLine toIoLine() const
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

struct TerPos {
    const(TerrainTile) ob;
    int  x;
    int  y;
    bool mirr; // mirror vertically
    int  rot;  // rotate tile? 0 = normal, 1, 2, 3 = turned counter-clockwise
    bool dark; // Terrain loeschen anstatt neues malen
    bool noow; // Nicht ueberzeichnen?

    IoLine toIoLine() const
    {
        string filename = ob ? get_filename(ob) : null;
        string modifiers;
        if (mirr) modifiers ~= 'f';
        foreach (r; 0 .. rot) modifiers ~= 'r';
        if (dark) modifiers ~= 'd';
        if (noow) modifiers ~= 'n';
        return IoLine.Colon(filename, x, y, modifiers);
    }
}
