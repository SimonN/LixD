module level.levdraw;

import basics.alleg5;
import file.filename;
import game.phymap;
import graphic.color;
import graphic.cutbit;
import graphic.graphic;
import graphic.torbit;
import level.level;
import level.tile;

package void implDrawTerrainTo(in Level level, Torbit tb, Phymap lookup)
{
    if (! tb) return;
    assert (tb.xl == level.xl);
    assert (tb.yl == level.yl);

    tb.clearToColor(color.transp);
    tb.setTorusXY(level.torusX, level.torusY);
    if (lookup) {
        lookup.resize(level.xl, level.yl);
        lookup.setTorusXY(level.torusX, level.torusY);
    }
    // Durch die Terrain-Liste iterieren, Wichtiges zuletzt blitten (obenauf)
    foreach (ref const(Pos) po; level.pos[TileType.TERRAIN]) {
        draw_pos(po, tb, lookup);
    }
}



private void draw_pos(in ref Pos po, Torbit ground, Phymap lookup)
{
    assert (po.ob);
    assert (po.ob.cb);
    const(Cutbit) bit = po.ob.cb;

    bit.draw(ground, po.x, po.y, po.mirr,
     po.ob.type == TileType.HATCH ? 0 : po.rot, // hatch rot: not for drawing
       po.noow ? Cutbit.Mode.NOOW
     : po.dark ? Cutbit.Mode.DARK
     :           Cutbit.Mode.NORMAL);

    // draw_pos is not only used for drawing terrain by
    // implDrawTerrainTo, but also by the implDraw_preview.
    // However, that one doesn't prepare a lookup map. So, for the lookupmap,
    // draw_pos is only concerned about drawing terrain and steel lookup.
    if (! lookup || po.ob.type != TileType.TERRAIN) return;

    // The remaining part of the function draws the terrain object, which
    // can be steel or normal terrain, to the lookup map.

    // The lookup map can contain additional info about trigger areas,
    // but draw_pos doesn't draw those onto the lookup map. That's done
    // by the game class.

    // We won't draw to ground, it's just to access rotated pixels.
    Graphic tempgra = new Graphic(bit, ground);
    scope (exit) destroy(tempgra);
    const(Albit) underlying_al_bitmap = bit.albit;
    auto lock = LockReadOnly(underlying_al_bitmap);
    tempgra.rotation = po.rot;
    tempgra.mirror   = po.mirr;
    for  (int x = po.x; x < po.x + tempgra.xl; ++x)
     for (int y = po.y; y < po.y + tempgra.yl; ++y)
     if (tempgra.get_pixel(x - po.x, y - po.y) != color.transp) {
        if (po.noow) {
            if (! lookup.get(x, y, Phybit.terrain))
                lookup.add(x, y, po.ob.subtype == 1 ?
                Phybit.steel | Phybit.terrain :
                Phybit.terrain);
        }
        else if (po.dark)
            lookup.rm(x, y, Phybit.terrain | Phybit.steel);
        else if (po.ob.subtype == 1)
            lookup.add(x, y, Phybit.terrain | Phybit.steel);
        else {
            lookup.add(x, y, Phybit.terrain);
            lookup.rm (x, y, Phybit.steel);
        }
    }
    // end of single pixel
}



package Torbit implCreatePreview(
    in Level level, in int w, in int h, in AlCol c)
{
    assert (w > 0);
    assert (h > 0);
    Torbit ret = new Torbit(w, h);
    ret.clearToColor(color.random); // DTODODRAW: draw the level on it
    return ret;
}



void implExportImage(in Level level, in Filename fn)
{
    assert (false, "DTODO: not implemented yet");
}
