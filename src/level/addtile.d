module level.addtile;

import std.typecons;

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

package:

// add tile to level such that its center point ends up at the argument point
Occurrence implCenter(Level level, Filename fn, Point center)
{
    auto ret = addFromLine(level, &level.terrain,
                           tile.tilelib.resolveTileName(fn), center);
    if (! ret)
        return null;
    assert (ret.tile, "added tile, image doesn't exist?");
    ret.loc = level.topology.clamp(center) - ret.tile.cb.len / 2;
    return ret;
}

// This gets called with the raw data, it's a factory.
// This adds to the correct array and, in addition, returns a reference.
Occurrence addFromLine(
    Level level,
    TerOcc[]* terrainGoesHere,
    in ResolvedTile resolvedTile,
    in Point cornerAt,
    in string text2 = ""
) {
    if (resolvedTile.terrain || resolvedTile.group) {
        assert (terrainGoesHere);
        TerOcc newpos = new TerOcc(resolvedTile.terrain ?
                                   resolvedTile.terrain : resolvedTile.group);
        newpos.loc = level.topology.wrap(cornerAt);
        foreach (char c; text2) switch (c) {
            case 'f': newpos.mirrY = ! newpos.mirrY;          break;
            case 'r': newpos.rotCw =  (newpos.rotCw + 1) % 4; break;
            case 'd': newpos.dark  = ! newpos.dark;           break;
            case 'n': newpos.noow  = ! newpos.noow;           break;
            default: break;
        }
        *terrainGoesHere ~= newpos;
        return newpos;
    }
    else if (resolvedTile.gadget) {
        GadOcc newpos = new GadOcc(resolvedTile.gadget);
        newpos.loc = level.topology.wrap(cornerAt);
        if (resolvedTile.gadget.type == GadType.HATCH)
            foreach (char c; text2) switch (c) {
                case 'r': newpos.hatchRot = ! newpos.hatchRot; break;
                default: break;
            }
        level.gadgets[resolvedTile.gadget.type] ~= newpos;
        return newpos;
    }
    else {
        if (! resolvedTile.weRemovedThisTileThereforeDontRaiseErrors)
            level._status = LevelStatus.BAD_IMAGE;
        return null;
    }
}

ResolvedTile resolveTileName(
    const(TileGroupKey[string]) groupsRead,
    in string name,
) {
    auto resolvedByLib = tile.tilelib.resolveTileName(name);
    if (resolvedByLib.tile !is null)
        return resolvedByLib;
    // The level has more knowledge than the tile lib:
    // If the lib doesn't know the tile, resolve the name as a group.
    if (name.length >= glo.levelUseGroup.length)
        if (auto group = name[glo.levelUseGroup.length .. $] in groupsRead)
            return ResolvedTile(null, null, get_group(*group));
    // Neither the lib nor the level has resolved this tile name.
    if (! resolvedByLib.weRemovedThisTileThereforeDontRaiseErrors)
        logMissingImage(name);
    return resolvedByLib;
}
