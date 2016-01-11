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
        drawPos(po, tb, lookup);
    }
}



private void drawPos(in Pos po, Torbit ground, Phymap lookup)
{
    assert (po.ob);
    assert (po.ob.cb);
    if (po.ob.type == TileType.TERRAIN)
        drawPosTerrain(po, ground, lookup);
    else
        drawPosGadget(po, ground);
}

private void drawPosGadget(in Pos po, Torbit ground)
{
    po.ob.cb.draw(ground, po.x, po.y,
        0, 0, // draw top-left frame. DTODO: Still OK for triggered traps?
        po.mirr,
        // hatch rotation: not for drawing, only for spawn direction
        po.ob.type == TileType.HATCH ? 0 : po.rot);
}

private void drawPosTerrain(in Pos po, Torbit ground, Phymap lookup)
{
    const(Cutbit) cb = po.ob.cb;
    cb.draw(ground, po.x, po.y, po.mirr, po.rot,
          po.noow ? Cutbit.Mode.NOOW
        : po.dark ? Cutbit.Mode.DARK
        :           Cutbit.Mode.NORMAL);
    if (! lookup)
        return;
    // The lookup map could contain additional info about trigger areas,
    // but drawPos[Terrain] doesn't draw those onto the lookup map. That's done
    // by the game class.
    Graphic tempgra = new Graphic(cb, ground); // won't draw this
    scope (exit)
        destroy(tempgra);
    tempgra.rotation = po.rot;
    tempgra.mirror   = po.mirr;
    auto lock = LockReadOnly(cb.albit);
    foreach (int y; po.y .. (po.y + tempgra.yl))
        foreach (int x; po.x .. (po.x + tempgra.xl)) {
            if (tempgra.get_pixel(x - po.x, y - po.y) == color.transp)
                continue;
            immutable isSteel  = po.ob.subtype == 1;
            immutable material = Phybit.terrain | (isSteel * Phybit.steel);
            if (po.noow) {
                if (! lookup.get(x, y, Phybit.terrain))
                    lookup.add(x, y, material);
            }
            else if (po.dark)
                lookup.rm(x, y, Phybit.terrain | Phybit.steel);
            else {
                lookup.add(x, y, material);
                if (! isSteel)
                    lookup.rm (x, y, Phybit.steel);
            }
        }
}



package Torbit implCreatePreview(
    in Level level, in int prevXl, in int prevYl, in AlCol c
) {
    assert (prevXl > 0);
    assert (prevYl > 0);
    Torbit ret = new Torbit(prevXl, prevYl);
    ret.clearToColor(c);
    if (   level.status == LevelStatus.BAD_FILE_NOT_FOUND
        || level.status == LevelStatus.BAD_EMPTY)
        return ret;

    Torbit newTb(AlCol tempTorbitCol)
    {
        Torbit t = new Torbit(level.xl, level.yl);
        t.clearToColor(tempTorbitCol);
        t.setTorusXY(level.torusX, level.torusY);
        return t;
    }
    Torbit tempTer = newTb(color.transp);
    Torbit tempObj = newTb(color.makecol(level.bgRed,
                                         level.bgGreen, level.bgBlue));
    scope (exit) {
        destroy(tempTer);
        destroy(tempObj);
    }
    for (int type = TileType.TERRAIN; type != TileType.MAX; ++type) {
        auto perm = Tile.perm(type);
        foreach (pos; level.pos[perm])
            drawPos(pos, perm == TileType.TERRAIN ? tempTer : tempObj, null);
    }
    ret.drawFromPreservingAspectRatio(tempObj);
    ret.drawFromPreservingAspectRatio(tempTer);
    return ret;
}



void implExportImage(in Level level, in Filename fn)
{
    assert (false, "DTODO: not implemented yet");
}
