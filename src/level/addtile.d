module level.addtile;

import std.typecons;

import file.filename;
import file.log;
import level.level;
import tile.pos;
import tile.gadtile;
import tile.platonic;
import tile.terrain;
import tile.tilelib;

package:

// add tile to level such that its center point ends up at the argument point
AbstractPos implCenter(Level level, Filename fn, Point center)
{
    if (! fn)
        return null;
    auto pos = add_object_from_ascii_line(level, fn.rootlessNoExt, center, "");
    if (! pos)
        return null;
    assert (pos.ob, "added tile, image doesn't exist?");
    pos.point = level.topology.clamp(center) - pos.ob.cb.len / 2;
    return pos;
}

// This gets called with the raw data, it's a factory.
// This adds to the correct array and, in addition, returns a reference.
AbstractPos add_object_from_ascii_line(
    Level     level,
    in string text1,
    in Point  cornerAt,
    in string text2
) {
    const(TerrainTile) ter = get_terrain(text1);
    const(GadgetTile)  gad = ter is null ? get_gadget (text1) : null;
    if (ter && ter.cb) {
        TerPos newpos = new TerPos(ter);
        newpos.point  = level.topology.wrap(cornerAt);
        foreach (char c; text2) switch (c) {
            case 'f': newpos.mirr = ! newpos.mirr;         break;
            case 'r': newpos.rot  =  (newpos.rot + 1) % 4; break;
            case 'd': newpos.dark = ! newpos.dark;         break;
            case 'n': newpos.noow = ! newpos.noow;         break;
            default: break;
        }
        level.terrain ~= newpos;
        return newpos;
    }
    else if (gad && gad.cb) {
        GadPos newpos = new GadPos(gad);
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
