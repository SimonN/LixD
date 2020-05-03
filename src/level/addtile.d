module level.addtile;

import std.typecons;

import optional;

import glo = basics.globals; // keyword to use a tile group
import file.filename;
import file.log;
import level.level;
import tile.occur;
import tile.gadtile;
import tile.abstile;
import tile.group;
import tile.terrain;
import tile.tilelib;
import tile.visitor;

package:

// This gets called with the raw data, it's a factory.
// This adds to the correct array and, in addition, returns a reference.
Occurrence addFromLine(
    Level level,
    TerOcc[]* terrainGoesHere,
    in AbstractTile resolvedTile,
    in Point cornerAt,
    in string text2 = ""
) {
    Occurrence ret = null;
    resolvedTile.accept(new class TileVisitor {
        void visit(const(TerrainTile) te)
        {
            assert (terrainGoesHere);
            TerOcc newpos = new TerOcc(te);
            newpos.loc = level.topology.wrap(cornerAt);
            foreach (char c; text2) switch (c) {
                case 'f': newpos.mirrY = ! newpos.mirrY;          break;
                case 'r': newpos.rotCw =  (newpos.rotCw + 1) % 4; break;
                case 'd': newpos.dark  = ! newpos.dark;           break;
                case 'n': newpos.noow  = ! newpos.noow;           break;
                default: break;
            }
            *terrainGoesHere ~= newpos;
            ret = newpos;
        }
        void visit(const(TileGroup) gr)
        {
            visit(cast (const(TerrainTile)) gr);
        }
        void visit(const(GadgetTile) ga)
        {
            GadOcc newpos = new GadOcc(ga);
            newpos.loc = level.topology.wrap(cornerAt);
            if (ga.type == GadType.HATCH)
                foreach (char c; text2) switch (c) {
                    case 'r': newpos.mirrY = ! newpos.mirrY; break;
                    default: break;
                }
            level.gadgets[ga.type] ~= newpos;
            ret = newpos;
        }
    });
    return ret;
}

// Might return none if tile doesn't exist.
// The tile library is responsible for any logging, we won't log.
Optional!(const(AbstractTile)) resolveTileName(
    const(TileGroupKey[string]) groupsRead,
    in string name,
) {
    // The level knows about groupsRead, the tile lib doesn't.
    if (name.length >= glo.levelUseGroup.length)
        if (auto group = name[glo.levelUseGroup.length .. $] in groupsRead) {
            try {
                const(AbstractTile) gotten = getGroup(*group);
                return some(gotten);
            }
            catch (TileGroup.InvisibleException) {
                logf(name ~ " has no visible pixels");
                return no!(const(AbstractTile));
            }
        }
    // This name doesn't refer to a group. Let the lib resolve this, as normal.
    // The lib is guaranteed to be called only with names it can understand
    // (not "Group-1") and the lib can thus log any encountered error.
    return tile.tilelib.resolveTileName(name);
}
