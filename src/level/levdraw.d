module level.levdraw;

import std.algorithm;
import std.conv;
import std.range;
import std.string;

import basics.alleg5;
import basics.globals : dirExportImages;
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

private void drawGadgetOcc(in GadOcc occ, Torbit ground)
{
    occ.tile.cb.draw(ground, occ.loc,
        0, 0, // draw top-left frame. DTODO: Still OK for triggered traps?
        0, // mirroring
        // hatch rotation: not for drawing, only for spawn direction
        occ.tile.type == GadType.HATCH ? 0 : occ.hatchRot);
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
    // Render the gadgets, then the terrain, using a temporary bitmap.
    // If the level has torus, the following temporary torbit need torus, too
    {
        Torbit temp = new Torbit(level.topology);
        scope (exit)
            destroy(temp);
        auto target = DrawingTarget(temp.albit);

        temp.clearToColor(level.bgColor);
        for (int type = cast (GadType) 0; type != GadType.MAX; ++type)
            level.gadgets[type].each!(occ => drawGadgetOcc(occ, temp));
        ret.drawFromPreservingAspectRatio(temp);

        temp.clearToColor(color.transp);
        level.terrain.each!(occ => drawOccurrence(occ, temp));
        ret.drawFromPreservingAspectRatio(temp);
    }
    return ret;
}

package Filename exportImageFilename(in Filename levelFilename)
{
    return new VfsFilename("%s%s.png".format(dirExportImages.rootless,
                                             levelFilename.fileNoExtNoPre));
}

package void implExportImage(in Level level, in Filename fnToSaveImage)
in {
    assert (level);
    assert (fnToSaveImage);
}
body {
    version (tharsisprofiling)
        auto zone = Zone(profiler, "Level.export");
    enum int extraYl = 0; // DTODOIMAGEEXPORT: 60;
    const tp = level.topology;

    Torbit img = new Torbit(tp.xl, tp.yl + extraYl, tp.torusX, tp.torusY);
    scope (exit)
        destroy(img);

    // Render level
    {
        Torbit tempLand = new Torbit(tp);
        scope (exit)
            destroy(tempLand);
        auto target = DrawingTarget(tempLand.albit);
        tempLand.clearToColor(level.bgColor);
        for (int type = cast (GadType) 0; type != GadType.MAX; ++type)
            level.gadgets[type].each!(occ => drawGadgetOcc(occ, tempLand));
        img.drawFrom(tempLand.albit, Point(0, 0));

        // Even without no-overwrite terrain, we should do all gadgets first,
        // then all terrain. Reason: When terrain erases, it shouldn't erase
        // the gadgets.
        tempLand.clearToColor(color.transp);
        level.terrain.each!(occ => drawOccurrence(occ, tempLand));
        img.drawFrom(tempLand.albit, Point(0, 0));
    }

    // Draw UI near the bottom
    /+ // DTODOIMAGEEXPORT: uncomment and implement
    {
        auto target = DrawingTarget(img.albit);
        img.drawFilledRectangle(Rect(0, tp.yl, tp.xl, extraYl), color.guiM);
    }
    +/

    // Done rendering the image.
    img.saveToFile(fnToSaveImage);
}
