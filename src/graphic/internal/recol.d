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

void recolor_into_vector(
    Cutbit            cutbit,
    ref Cutbit[Style] vector,
    int               magicnr
) {
    // We assume the bitmap to be locked already. If you write code calling
    // this function, make sure it's locked. Otherwise, everything will work
    // extremely slowly.

    assert (cutbit.valid);
    Cutbit rclCb = getInternalMutable(fileImageStyleRecol);
    assert (rclCb !is nullCutbit, "can't recolor, missing map image");

    Albit recol = rclCb.albit;
    Albit lix   = cutbit.albit;
    if (!recol || !lix) return;

    immutable int   recolXl  = al_get_bitmap_width (recol);
    immutable int   recolYl  = al_get_bitmap_height(recol);
    immutable int   lixXl    = al_get_bitmap_width (lix);
    immutable int   lixYl    = al_get_bitmap_height(lix);
    immutable AlCol colBreak = al_get_pixel(lix, lixXl - 1, 0);

    auto lock = LockReadWrite(recol);



    void recolorOneBitmap(Albit target, in int style_id)
    {
        assert(target);
        assert(style_id < recolYl - 1);
        auto zone = Zone(profiler, format("recolor-one-bitmap-%d", magicnr));

        // Build the recolor array for this particular style
        AlCol[AlCol] recolArray;
        for (int conv = 0; conv < recolXl; ++conv) {
            recolArray[al_get_pixel(recol, conv, 0)] =
                       al_get_pixel(recol, conv, style_id + 1);
        }

        auto drata = DrawingTarget(target);

        // The first row (y == 0) contains the source pixels. The first style
        // (garden) is at y == 1. Thus the recol->h - 1 is correct as we count
        // styles starting at 0.
        Y_LOOP: for (int y = 0; y < lixYl; y++) {
            X_LOOP: for (int x = 0; x < lixXl; x++) {
                // The skill button icons have two rows: the first has the
                // skills in player colors, the second has them greyed out.
                // Ignore the second row here.
                if (y >= cutbit.yl + 1 && magicnr == magicnrSkillButtonIcons) {
                    break Y_LOOP;
                }
                else if (magicnr == magicnrPanelInfoIcons
                     && y >= cutbit.yl + 1
                     && y <  2 * (cutbit.yl + 1)
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
                        x += cutbit.xl;

                // No exceptions for speed encountered so far.
                if (AlCol* colPtr = (col in recolArray)) {
                    al_put_pixel(x, y, *colPtr);
                }
                // end of single-pixel color replacement
            }
        }
        // end of for-all-pixels in source bitmap
    }
    // end of function recolorOneBitmap


    // now invoke the above code on each Lix style
    foreach (int i; 0 .. Style.max) {
        Style st = cast (Style) i;
        vector[st] = new Cutbit(cutbit);

        static if (true)
            // Speed up loading to debug the game easier. This is not honte.
            // Recoloring different styles should not be done at program start.
            if (st >= Style.yellow)
                continue;

        auto zone = Zone(profiler, format("recolor-one-foreach-%d", magicnr));

        Albit target = vector[st].albit;
        assert (target);

        // DTODOLANG
        if (magicnr == magicnrSpritesheets)
            displayStartupMessage(styleToString(st));

        auto lockTarget = LockReadWrite(target);
        recolorOneBitmap(target, i);

        // Invoke eidrecol on the bitmap. Whenever eidrecol is invoked
        // with a magicnr != 0, it does not lock/unlock the bitmaps itself,
        // but assumes they are locked.
        if (magicnr != magicnrSpritesheets)
            eidrecol(vector[st], magicnr);
    }
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
