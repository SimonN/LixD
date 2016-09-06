module game.terchang;

import basics.rect;
import net.repdata;
import net.style;

private mixin template TerrainChangeBase() {
    Update update;
    Type   type;
    int x; // lix store the top-left corner of the terrain change here, ...
    int y; //    ...not the effective coordinate.

    @property Point loc()       const { return Point(x, y); }
    @property Point loc(in Point p)   { x = p.x; y = p.y; return loc(); }
}

public struct TerrainAddition {
    mixin TerrainChangeBase;
    enum Type {
        build,
        platformLong,
        platformShort,
        cube
    }
    Style style;
    int cubeYl;
}

public struct TerrainDeletion {
    mixin TerrainChangeBase;
    enum Type {
        implode,
        explode,
        bashLeft,
        bashRight,
        bashNoRelicsLeft,
        bashNoRelicsRight,
        mineLeft,
        mineRight,
        dig
    }
    int digYl;
}

// The following structs are of interest only in game.physdraw.PhysicsDrawer.
// They collect extra information for drawing to land, after having been drawn
// to the physics map already.
package struct FlaggedAddition {
    TerrainAddition terrainChange;
    alias terrainChange this;

    bool drawPerPixelDueToExistingTerrain;
    byte[16][16] needsColoring; // if mustDrawPerPixel, then look up where here
    /* 16 is the length of a cube.
     * I estimate that all addition-drawing is smaller than this.
     * How to look up: Coordinate at loc() + Point(x, y) is at arr[y][x].
     * I chose byte[][] instead of bool[][] to have it packed densely.
     */
}

package struct FlaggedDeletion {
    TerrainDeletion terrainChange;
    alias terrainChange this;
    bool drawPerPixelDueToSteel;
}
