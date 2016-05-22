module level.levdraw;

import std.algorithm;
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
import tile.draw;
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
    foreach (occ; level.terrain) {
        occ.drawOccurrence(tb);
        occ.drawOccurrence(lookup);
    }
}

private void drawPosGadget(in GadOcc po, Torbit ground)
{
    po.tile.cb.draw(ground, po.point,
        0, 0, // draw top-left frame. DTODO: Still OK for triggered traps?
        0, // mirroring
        // hatch rotation: not for drawing, only for spawn direction
        po.tile.type == GadType.HATCH ? 0 : po.hatchRot);
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
        level.pos[type].each!(occ => drawPosGadget(occ, tempObj));
    level.terrain.each!(occ => drawOccurrence(occ, tempTer));
    ret.drawFromPreservingAspectRatio(tempObj);
    ret.drawFromPreservingAspectRatio(tempTer);
    return ret;
}

void implExportImage(in Level level, in Filename fn)
{
    assert (false, "DTODO: not implemented yet");
}
