module level.levdraw;

import std.algorithm;
import std.conv;
import std.range;
import std.string;

import file.filename;
import graphic.color;
import graphic.cutbit;
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
        occ.tile.type == GadType.hatch ? 0 : occ.hatchRot);
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
    if (level.errorFileNotFound || level.errorEmpty)
        return ret;
    // Render the gadgets, then the terrain, using a temporary bitmap.
    // If the level has torus, the following temporary torbit need torus, too
    {
        Torbit temp = () {
            Torbit.Cfg cfg = Torbit.Cfg(level.topology);
            cfg.smoothlyScalable = true;
            return new Torbit(cfg);
        }();
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

package void implExportImage(in Level level, in Filename fnToSaveImage)
in {
    assert (level);
    assert (fnToSaveImage);
}
do {
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

        drawToImg();
    }

    // Draw UI
    {
        import gui;
        gui.forceUnscaledGUIDrawing = true;
        scope (exit)
            gui.forceUnscaledGUIDrawing = false;

        // Torus icon in the top-left corner of the level
        {
            import graphic.internal;
            import std.exception;
            const icon = InternalImage.previewIcon.toCutbit;
            enforce(icon, "we need internal graphics to render levels");
            with (level.topology)
                icon.draw(Point(0, 0), torusX + 2 * torusY, 1);
        }

        // Draw UI near bottom of the level
        img.drawFilledRectangle(Rect(0, tp.yl, img.xl, extraYl), color.gui.m);
        import file.option : skillSort;
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
            enum niceLeftSpace = 5;
            enum labelX = skillSort.length * sbXl + niceLeftSpace;
            auto label = new LabelTwo(new Geom(labelX, tp.yl + plusY,
                                2 * sbXl - niceLeftSpace, 20), lang.transl);
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

// Testing the level drawing is expensive and relies on a lot of modules
// getting initialized. Doesn't matter. Noninteractive level dump is important
// and should work.
version (none): // Deactivated for unittest speed.
unittest {
    import basics.alleg5;
    import basics.init;
    import basics.cmdargs;
    import basics.globals;

    al_run_allegro({
        initializeNoninteractive(Runmode.EXPORT_IMAGES);
        scope (exit)
            deinitializeAfterUnittest();

        Filename lvFn = new VfsFilename(dirLevelsSingle.rootless
            ~ "lemforum/Lovely/anyway.txt");
        Level l = new Level(lvFn);
        assert (! l.errorMissingTiles, "Level `" ~ l.name
            ~ "' couldn't be loaded properly "
            ~ " to test image export. Is the tile library initialized?");
        assert (l.playable, "Test level `" ~ lvFn.rootless
            ~ "' isn't playable, that is strange even during unittest.");

        Filename imgFn = Level.exportImageFilename(lvFn);
        imgFn.deleteFile();
        l.exportImageTo(imgFn);
        assert (imgFn.fileExists, "`" ~ l.name ~ "' wasn't exported to `"
            ~ imgFn.rootless ~ "'.");

        import std.file;
        import std.conv;
        assert (std.file.getSize(imgFn.stringForReading) > 100_000,
            "`" ~ l.name ~ "' is a large level, it should produce a large"
            ~ " image file `" ~ imgFn.rootless ~ "`', but hasn't.");
        // This unittest doesn't delete its generated file. It should! Add it.
        return 0;
    });
}
