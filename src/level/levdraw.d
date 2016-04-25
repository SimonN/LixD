module level.levdraw;

import std.conv;
import std.range; // for zone format
import std.string; // for zone format

import basics.alleg5;
import file.filename;
import graphic.color;
import graphic.cutbit;
import graphic.graphic;
import graphic.torbit;
import hardware.tharsis;
import level.level;
import tile.gadtile;
import tile.phymap;
import tile.occur;

package void implDrawTerrainTo(in Level level, Torbit tb, Phymap lookup)
{
    if (! tb) return;
    assert (tb == level.topology);
    assert (! lookup || lookup == level.topology);
    version (tharsisprofiling)
        auto zone = Zone(profiler, "Level.%s %s".format(
                    lookup ? "drawLT" : "drawT", level.name.take(15)));
    tb.clearToColor(color.transp);
    foreach (po; level.terrain)
        drawPosTerrain(po, tb, lookup);
}

private void drawPosGadget(in GadOcc po, Torbit ground)
{
    po.tile.cb.draw(ground, po.point,
        0, 0, // draw top-left frame. DTODO: Still OK for triggered traps?
        0, // mirroring
        // hatch rotation: not for drawing, only for spawn direction
        po.tile.type == GadType.HATCH ? 0 : po.hatchRot);
}

private void drawPosTerrain(in TerOcc po, Torbit ground, Phymap lookup)
{
    assert (po.tile);
    const(Cutbit) cb = po.dark ? po.tile.dark : po.tile.cb;
    assert (cb);
    Cutbit.Mode mode = po.noow ? Cutbit.Mode.NOOW
                     : po.dark ? Cutbit.Mode.DARK
                     :           Cutbit.Mode.NORMAL;
    {
        version (tharsisprofiling)
            auto zone = Zone(profiler, "Level.drawPos VRAM " ~ mode.to!string);
        cb.draw(ground, po.point, po.mirr, po.rot, mode);
    }
    if (! lookup)
        return;
    version (tharsisprofiling)
        auto zone = Zone(profiler, "Level.drawPos RAM " ~ mode.to!string);
    // The lookup map could contain additional info about trigger areas,
    // but drawPosGadget doesn't draw those onto the lookup map.
    // That's done by the game class.
    immutable xl = (po.rot & 1) ? po.tile.cb.yl : po.tile.cb.xl;
    immutable yl = (po.rot & 1) ? po.tile.cb.xl : po.tile.cb.yl;
    foreach (int y; po.point.y .. (po.point.y + yl))
        foreach (int x; po.point.x .. (po.point.x + xl)) {
            immutable p = Point(x, y);
            immutable bits = po.phybitsOnMap(p);
            if (! bits)
                continue;
            if (po.noow) {
                if (! lookup.get(p, Phybit.terrain))
                    lookup.add(p, bits);
            }
            else if (po.dark)
                lookup.rm(p, Phybit.terrain | Phybit.steel);
            else {
                lookup.add(p, bits);
                if (! po.tile.steel)
                    lookup.rm(p, Phybit.steel);
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
        Torbit t = new Torbit(level.topology);
        t.clearToColor(tempTorbitCol);
        return t;
    }
    Torbit tempTer = newTb(color.transp);
    Torbit tempObj = newTb(color.makecol(level.bgRed,
                                         level.bgGreen, level.bgBlue));
    scope (exit) {
        destroy(tempTer);
        destroy(tempObj);
    }
    for (int type = cast (GadType) 0; type != GadType.MAX; ++type)
        foreach (pos; level.pos[type])
            drawPosGadget(pos, tempObj);
    foreach (pos; level.terrain)
        drawPosTerrain(pos, tempTer, null);
    ret.drawFromPreservingAspectRatio(tempObj);
    ret.drawFromPreservingAspectRatio(tempTer);
    return ret;
}

void implExportImage(in Level level, in Filename fn)
{
    assert (false, "DTODO: not implemented yet");
}
