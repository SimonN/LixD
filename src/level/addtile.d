module level.addtile;

import std.typecons;

import file.filename;
import file.log;
import level.level;
import tile.occur;
import tile.gadtile;
import tile.abstile;
import tile.terrain;
import tile.tilelib;

package:

// add tile to level such that its center point ends up at the argument point
Occurrence implCenter(Level level, Filename fn, Point center)
{
    if (! fn)
        return null;
    auto pos = add_object_from_ascii_line(level, fn.rootlessNoExt, center, "");
    if (! pos)
        return null;
    assert (pos.tile, "added tile, image doesn't exist?");
    pos.point = level.topology.clamp(center) - pos.tile.cb.len / 2;
    return pos;
}

// This gets called with the raw data, it's a factory.
// This adds to the correct array and, in addition, returns a reference.
Occurrence add_object_from_ascii_line(
    Level     level,
    in string text1,
    in Point  cornerAt,
    in string text2
) {
    const(TerrainTile) ter = get_terrain(text1);
    const(GadgetTile)  gad = ter is null ? get_gadget (text1) : null;
    if (ter && ter.cb) {
        TerOcc newpos = new TerOcc(ter);
        newpos.point  = level.topology.wrap(cornerAt);
        foreach (char c; text2) switch (c) {
            case 'f': newpos.mirrY = ! newpos.mirrY;          break;
            case 'r': newpos.rotCw =  (newpos.rotCw + 1) % 4; break;
            case 'd': newpos.dark  = ! newpos.dark;           break;
            case 'n': newpos.noow  = ! newpos.noow;           break;
            default: break;
        }
        level.terrain ~= newpos;
        return newpos;
    }
    else if (gad && gad.cb) {
        GadOcc newpos = new GadOcc(gad);
        newpos.point  = level.topology.wrap(cornerAt);
        if (gad.type == GadType.HATCH)
            foreach (char c; text2) switch (c) {
                case 'r': newpos.hatchRot = ! newpos.hatchRot; break;
                default: break;
            }
        level.pos[gad.type] ~= newpos;
        return newpos;
    }
    else {
        level._status = LevelStatus.BAD_IMAGE;
        logf("Missing image `%s'", text1);
        return null;
    }
}
