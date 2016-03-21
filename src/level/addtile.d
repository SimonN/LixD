module level.addtile;

import std.typecons;

import basics.help;
import file.filename;
import file.log;
import level.level;
import tile.pos;
import tile.gadtile;
import tile.platonic;
import tile.terrain;
import tile.tilelib;

package:

// add tile to level such that its center point ends up at p
void implCenter(Level level, Filename fn, Point p)
{
    if (! fn)
        return;
    const str = fn.rootlessNoExt;
    // There is a compiler bug in dmd 2.070: Assume classes B : A and C : A.
    // The common type of B and C is A, correct. But the common type of
    // const(B) and const(C) is not const(A), but void, which is a bug.
    // We can't use operator ?:, but have to roll our own disambiguation.
    Rebindable!(const(Platonic)) tile = get_terrain(str);
    if (! tile)
        tile = get_gadget(str);
    if (! tile)
        return;
    int x = p.x - tile.cb.xl / 2;
    int y = p.y - tile.cb.yl / 2;
    if (level.torusX)
        x = positiveMod(x, level.xl);
    if (level.torusY)
        y = positiveMod(y, level.yl);
    add_object_from_ascii_line(level, str, x, y, "");
}

// this gets called with the raw data, it's a factory
void add_object_from_ascii_line(
    Level     level,
    in string text1,
    in int    nr1,
    in int    nr2,
    in string text2
) {
    const(TerrainTile) ter = get_terrain(text1);
    const(GadgetTile)  gad = ter is null ? get_gadget (text1) : null;
    if (ter && ter.cb) {
        TerPos newpos = new TerPos(ter);
        newpos.x  = nr1;
        newpos.y  = nr2;
        foreach (char c; text2) switch (c) {
            case 'f': newpos.mirr = ! newpos.mirr;         break;
            case 'r': newpos.rot  =  (newpos.rot + 1) % 4; break;
            case 'd': newpos.dark = ! newpos.dark;         break;
            case 'n': newpos.noow = ! newpos.noow;         break;
            default: break;
        }
        level.terrain ~= newpos;
    }
    else if (gad && gad.cb) {
        GadPos newpos = new GadPos(gad);
        newpos.x  = nr1;
        newpos.y  = nr2;
        if (gad.type == GadType.HATCH)
            foreach (char c; text2) switch (c) {
                case 'r': newpos.hatchRot = ! newpos.hatchRot; break;
                default: break;
            }
        level.pos[gad.type] ~= newpos;
    }
    else {
        level._status = LevelStatus.BAD_IMAGE;
        logf("Missing image `%s'", text1);
    }
}
