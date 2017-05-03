module level.levdraw;

import std.algorithm;
import std.conv;
import std.range;
import std.string;

import basics.alleg5;
import basics.globals;
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
    assert (tb.matches(level.topology));
    assert (! lookup || lookup.matches(level.topology));
    version (tharsisprofiling)
        auto zone = Zone(profiler, "Level.%s %s".format(
                    lookup ? "drawLT" : "drawT", level.name.take(15)));
    with (TargetTorbit(tb)) {
        tb.clearToColor(color.transp);
        foreach (occ; level.terrain) {
            occ.drawOccurrence(); // to target torbit
            occ.drawOccurrence(lookup);
        }
    }
}

private void drawGadgetOcc(in GadOcc occ)
{
    occ.tile.cb.draw(occ.loc,
        0, 0, // draw top-left frame. DTODO: Still OK for triggered traps?
        0, // mirroring
        // hatch rotation: not for drawing, only for spawn direction
        occ.tile.type == GadType.HATCH ? 0 : occ.hatchRot);
}

package Torbit implCreatePreview(
    in Level level, in int prevXl, in int prevYl, in Alcol c
) {
    assert (prevXl > 0);
    assert (prevYl > 0);
    Torbit ret;
    {
        Torbit.Cfg cfg;
        cfg.xl = prevXl;
        cfg.yl = prevYl;
        ret = new Torbit(cfg);
        // If we want smooth scrolling, it wouldn't help to add merely
        // cfg.smoothlyScalable = true. Instead, we'd have to add that flag
        // to a temp bitmap, then blit from the temp bitmap to ret.
    }
    ret.clearToColor(c);
    if (   level.status == LevelStatus.BAD_FILE_NOT_FOUND
        || level.status == LevelStatus.BAD_EMPTY
    ) {
        return ret;
    }
    // Render the gadgets, then the terrain, using a temporary bitmap.
    // If the level has torus, the following temporary torbit need torus, too
    {
        Torbit temp = new Torbit(Torbit.Cfg(level.topology));
        scope (exit)
            destroy(temp);
        auto target = TargetTorbit(temp);
        temp.clearToColor(level.bgColor);
        for (int type = cast (GadType) 0; type != GadType.MAX; ++type)
            level.gadgets[type].each!(g => drawGadgetOcc(g));
        ret.drawFromPreservingAspectRatio(temp);

        temp.clearToColor(color.transp);
        level.terrain.each!drawOccurrence;
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
    enum int extraYl = 60;
    const tp = level.topology;

    Torbit img;
    {
        auto cfg = Torbit.Cfg(level.topology);
        cfg.xl = max(tp.xl, 640);
        cfg.yl = tp.yl + extraYl;
        img = new Torbit(cfg);
    }
    scope (exit)
        destroy(img);
    auto targetTorbit = TargetTorbit(img);
    img.clearToColor(color.screenBorder);

    // Render level
    {
        Torbit tempLand = new Torbit(Torbit.Cfg(tp));
        scope (exit)
            destroy(tempLand);
        void drawToImg()
        {
            auto target2 = TargetTorbit(img);
            tempLand.albit.drawToTargetTorbit(Point((img.xl - tp.xl) / 2, 0));
        }
        auto target = TargetTorbit(tempLand);
        tempLand.clearToColor(level.bgColor);
        for (int type = cast (GadType) 0; type != GadType.MAX; ++type)
            level.gadgets[type].each!(g => drawGadgetOcc(g));
        drawToImg();
        // Even without no-overwrite terrain, we should do all gadgets first,
        // then all terrain. Reason: When terrain erases, it shouldn't erase
        // the gadgets.
        tempLand.clearToColor(color.transp);
        level.terrain.each!drawOccurrence;
        // Torus icon in the top-left corner of the level
        import graphic.internal;
        getInternal(fileImagePreviewIcon).draw(Point(0, 0),
            level.topology.torusX + 2 * level.topology.torusY, 1);
        drawToImg();
    }

    // Draw UI near the bottom
    {
        import gui;
        gui.forceUnscaledGUIDrawing = true;
        scope (exit)
            gui.forceUnscaledGUIDrawing = false;

        img.drawFilledRectangle(Rect(0, tp.yl, img.xl, extraYl), color.guiM);
        import basics.user : skillSort;
        import file.language;
        enum sbXl = 40;
        auto sb = new SkillButton(new Geom(0, tp.yl, sbXl, extraYl));
        foreach (int i, Ac ac; skillSort) {
            sb.move(i * sbXl, tp.yl);
            sb.skill = ac.isPloder ? level.ploder : ac;
            sb.number = level.skills[sb.skill];
            sb.draw();
        }
        void printInfo(Lang lang, int value, int plusY)
        {
            enum labelX = skillSort.length * sbXl + 5;
            auto label = new LabelTwo(new Geom(labelX, tp.yl + plusY,
                                      tp.xl - labelX, 20), lang.transl);
            label.value = value;
            label.draw();
        }
        printInfo(Lang.exportSingleInitial,  level.initial,   0 + 2);
        printInfo(Lang.exportSingleRequired, level.required, 20 + 0);
        printInfo(Lang.exportSingleSpawnint, level.spawnint, 40 - 2);
    }

    // Done rendering the image.
    img.saveToFile(fnToSaveImage);
}
