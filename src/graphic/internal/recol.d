module graphic.internal.recol;

import std.string;

import basics.alleg5;
import basics.globals; // fileImageStyleRecol
import file.filename;
import graphic.color;
import graphic.cutbit;
import graphic.internal.getters;
import graphic.internal.vars;
import hardware.display; // print startup progress info; maybe make it lazy
import hardware.tharsis;
import lix.enums;

package:

void eidrecol(Cutbit cutbit, in int magicnr)
{
    // don't do anything for magicnr == magicnrSpritesheets. This function
    // is about GUI recoloring, not player color recoloring. All GUI portions
    // of the spritesheets have been moved to the skill buttons in 2015-10.
    if (magicnr == magicnrSpritesheets)
        return;
    makeColorDicts();

    version (tharsisprofiling)
        auto zone = Zone(profiler, "eidrecol magicnr = %d".format(magicnr));
    Albit bitmap = cutbit.albit;
    assert (bitmap);
    if (! bitmap) return;

    if (magicnr == 0) {
        auto region = al_lock_bitmap(bitmap,
         ALLEGRO_PIXEL_FORMAT.ALLEGRO_PIXEL_FORMAT_ANY,
         ALLEGRO_LOCK_READWRITE);
        assert (region, "can't lock bitmap despite magicnr == 0");
    }
    scope (exit)
        if (magicnr == 0)
            al_unlock_bitmap(bitmap);

    auto drata = DrawingTarget(bitmap);
    immutable bmp_yl = al_get_bitmap_height(bitmap);
    if (! magicnr)
        for (int y = 0; y < bmp_yl; ++y)
            applyToRow(y > cutbit.yl ? dictGuiLight
                                     : dictGuiNormal, bitmap, y);
    else if (magicnr == magicnrSkillButtonIcons) {
        recolorAllShadows(bitmap);
        for (int y = cutbit.yl + 1; y < bmp_yl; ++y) // only row 1 (of 0, 1)
            dictGuiNormalNoShadow.applyToRow(bitmap, y);
    }
    else if (magicnr == magicnrPanelInfoIcons) {
        recolorAllShadows(bitmap);
        for (int y = cutbit.yl + 1; y < 2 * (cutbit.yl + 1); ++y)
            dictGuiNormalNoShadow.applyToRow(bitmap, y);
    }
}

Cutbit lockThenRecolor(
    Cutbit sourceCutbit,
    in int magicnr,
    in Style st
) {
    // We assume sourceCutbit to be unlocked, and are going to lock it
    // in this function.
    if (! sourceCutbit || ! sourceCutbit.valid)
        return nullCutbit;
    Albit lix = sourceCutbit.albit;
    assert (lix);

    immutable int   lixXl    = al_get_bitmap_width (lix);
    immutable int   lixYl    = al_get_bitmap_height(lix);
    immutable AlCol colBreak = al_get_pixel(lix, lixXl - 1, 0);

    void recolorTargetForStyle()
    {
        version (tharsisprofiling)
            auto zone = Zone(profiler, format("recolor-one-bmp-%d", magicnr));
        AlCol[AlCol] recolArray = generateRecolArray(st);
        Y_LOOP: for (int y = 0; y < lixYl; y++) {
            X_LOOP: for (int x = 0; x < lixXl; x++) {
                // The skill button icons have two rows: the first has the
                // skills in player colors, the second has them greyed out.
                // Ignore the second row here.
                if (y >= sourceCutbit.yl + 1
                    && magicnr == magicnrSkillButtonIcons
                ) {
                    break Y_LOOP;
                }
                else if (magicnr == magicnrPanelInfoIcons
                     && y >= sourceCutbit.yl + 1
                     && y <  2 * (sourceCutbit.yl + 1)
                ) {
                    // skip all x pixels in the second row in this
                    continue;
                }
                immutable AlCol col = al_get_pixel(lix, x, y);
                if (magicnr == magicnrSpritesheets && col == colBreak)
                    // on two consecutive pixels with colBreak, skip for speed
                    if (x < lixXl - 1 && al_get_pixel(lix, x+1, y) == colBreak)
                        // bad:  immediately begin next row, because
                        //       we may have separating colBreak-colored
                        //       frames in the file.
                        // good: immediately begin next frame. We have already
                        //       advanced into the frame by 1 pixel, as we have
                        //       seen two
                        x += sourceCutbit.xl;

                // No exceptions for speed encountered so far.
                if (AlCol* colPtr = (col in recolArray))
                    al_put_pixel(x, y, *colPtr);
            }
        }
    }
    // end function recolorForStyle

    // now invoke the above code on the single wanted Lix style
    Cutbit targetCb = new Cutbit(sourceCutbit);
    version (tharsisprofiling)
        auto zone = Zone(profiler, format("recolor-one-foreach-%d", magicnr));
    auto lock  = LockReadOnly(lix);
    auto lock2 = LockReadWrite(targetCb.albit); // see [1] at end of function
    auto drata = DrawingTarget(targetCb.albit);
    recolorTargetForStyle();

    // eidrecol invoked with magicnr != 0 expects already-locked bitmap
    if (magicnr != magicnrSpritesheets)
        eidrecol(targetCb, magicnr);
    return targetCb;

    /* [1]: Why do we lock targetCb.albit at all?
     * I have no idea why we are doing this (2016-03). recolorTargetForStyle
     * runs extremely slowly if we don't lock targetCb.albit, even though we
     * only write to it. Speculation: al_put_pixel is slow when not writing
     * to VRAM bitmaps.
     *
     * We would have to lock targetCb.albit as read-write when going into
     * the eidrecol function. So we don't lose anything by locking it earlier.
     */
}

private:

AlCol[AlCol] dictGuiLight, dictGuiNormal, dictGuiNormalNoShadow;

void makeColorDicts()
{
    // I don't dare to make these at compile time, unsure whether AlCol's
    // bitwise interpretation depends on color mode chosen by Allegro 5
    if (dictGuiLight != null)
        return;
    dictGuiLight[color.black]      = color.transp;
    dictGuiLight[color.guiFileSha] = color.guiSha;
    dictGuiLight[color.guiFileD]   = color.guiPicOnD;
    dictGuiLight[color.guiFileM]   = color.guiPicOnM;
    dictGuiLight[color.guiFileL]   = color.guiPicOnL;
    dictGuiNormal[color.black]      = color.transp;
    dictGuiNormal[color.guiFileSha] = color.guiSha;
    dictGuiNormal[color.guiFileD]   = color.guiPicD;
    dictGuiNormal[color.guiFileM]   = color.guiPicM;
    dictGuiNormal[color.guiFileL]   = color.guiPicL;
    dictGuiNormalNoShadow = dictGuiNormal.dup;
    dictGuiNormalNoShadow.remove(color.guiFileSha);
}

void applyToAllRows(AlCol[AlCol] dict, Albit bitmap)
{
    foreach (int row; 0 .. al_get_bitmap_height(bitmap))
        dict.applyToRow(bitmap, row);
}

void applyToRow(AlCol[AlCol] dict, Albit bitmap, int row)
{
    // We assume the bitmap to be locked for speed!
    foreach (int x; 0 .. al_get_bitmap_width(bitmap)) {
        immutable AlCol c = al_get_pixel(bitmap, x, row);
        if (auto newCol = c in dict)
            al_put_pixel(x, row, *newCol);
    }
}

void recolorAllShadows(Albit bitmap)
{
    foreach (int y; 0 .. al_get_bitmap_height(bitmap))
        foreach (int x; 0 .. al_get_bitmap_width(bitmap)) {
            immutable AlCol c = al_get_pixel(bitmap, x, y);
            if (c == color.guiFileSha)
                al_put_pixel(x, y, color.guiSha);
        }
}

AlCol[AlCol] generateRecolArray(in Style st)
{
    Cutbit rclCb = getInternalMutable(fileImageStyleRecol);
    assert (rclCb !is nullCutbit, "can't recolor, missing map image");
    Albit recol = rclCb.albit;
    auto lock = LockReadOnly(recol);
    AlCol[AlCol] recolArray;
    assert(st < al_get_bitmap_height(recol) - 1, "recolor map yl too low");
    foreach (x; 0 .. al_get_bitmap_width(recol))
        // The first row (y == 0) contains the source pixels. The first style
        // (garden) is at y == 1. Thus, target colors are at y == st + 1.
        recolArray[al_get_pixel(recol, x, 0)] =
                   al_get_pixel(recol, x, st + 1);
    return recolArray;
}
