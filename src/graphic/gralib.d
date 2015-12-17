module graphic.gralib;

import std.conv; // scale to
import std.string; // format

import basics.alleg5;
import basics.globals;  // name of internal bitmap dir
import basics.help;
import basics.matrix;
import graphic.color;   // replace pink with transparencys
import graphic.cutbit;
import file.filename;
import file.search;
import hardware.display; // display startup progress
import hardware.tharsis;
import lix.enums;
import lix.fields;

/* Graphics library, loads spritesheets and offers them for use via string
 * lookup. This does not handle Lix terrain, special objects, or L1/L2 graphics
 * sets. All of those are handled by the tile library.
 *
 *  void initialize();
 *  void deinitialize();
 *
 *  void setScaleFromGui(float); // exact value, what gui.geometry thinks
 *
 *  const(Cutbit) getInternal       (Filename);
 *  const(Cutbit) getLixSpritesheet (Style);
 *  const(Cutbit) getSkillButtonIcon(Style)
 *  const(Cutbit) getPanelInfoIcon  (Style)
 */

private:

    Cutbit[string] internal;
    Cutbit[Style]  spritesheets;
    Cutbit[Style]  panelInfoIcons;
    Cutbit[Style]  skillButtonIcons;

    Cutbit nullCutbit; // invalid bitmap to return instead of null pointer

    string scaleDir = dirDataBitmap.rootless; // load from which dir?

/*  void eidrecol       (in Filename);
 *  void eidrecol       (Albit, in int = 0);
 *  void recolor_into_vector(const(Albit), ref Cutbit[Style], int = 0);
 *
 *      The int variables should be != 0 for the character spreadsheet and
 *      similar things that require both a GUI and a player color recoloring.
 *      recolor_into_vector() assumes the cutbit's bitmap to be locked already.
 */
    // I believe these magic numbers are only to separate between recoloring
    // lixes and recoloring icons. eidrecol behaves differently based on
    // the magic number. recolor_into_vector skips some rows based on them.
    // These magic numbers are a relic from C++/A4 Lix.
    immutable int magicnrSpritesheets = 1;
    immutable int magicnrPanelInfoIcons = 2;
    immutable int magicnrSkillButtonIcons = 3;



public:

void setScaleFromGui(in float scale)
{
    scaleDir =
        scale < 1.5f ? dirDataBitmap.rootless
     :  scale < 2.0f ? dirDataBitmapScale.rootless ~ "150/"
     :  scale < 3.0f ? dirDataBitmapScale.rootless ~ "200/"
     :                 dirDataBitmapScale.rootless ~ "300/";
}



void initialize()
{
    nullCutbit = new Cutbit(cast (Cutbit) null);

    // DTODOLANG
    displayStartupMessage("Loading internal bitmaps...");

    // find all internal bitmaps
    auto files = file.search.findTree(dirDataBitmap);

    // Since this is unrelated to the terrain name replacements, the internal
    // graphics are saved WITH dir.

    // Save all image filenames without (extension inclusive dot). That will
    // be helpful should we ever switch image file formats, and thus the
    // filename extensions.
    foreach (fn; files) {
        if (fn.hasImageExtension()) {
            Cutbit cb = new Cutbit(fn);
            assert (cb, "error loading internal cutbit: " ~ fn.rootful);
            al_convert_mask_to_alpha(cb.albit, color.pink);
            internal[fn.rootlessNoExt] = cb;
            assert (getInternal(fn).valid,
                "can't retrieve from array: " ~ fn.rootful);
        }
    }

    // Create the matrix of eye coordinates.
    // Each frame of the Lix spritesheet has the eyes in some position.
    // The exploder fuse shall start at that position, let's calculate it.
    Cutbit* cb_ptr = (fileImageSpritesheet.rootlessNoExt in internal);
    assert (cb_ptr, "missing image: the main Lix spritesheet");
    if (! cb_ptr) return;
    Cutbit cb = *cb_ptr;

    Albit b = cb.albit;
    assert (b, "apparently your gfx card can't store the Lix spritesheet");

    // DTODOLANG
    displayStartupMessage("Examining Lix spritesheet for eye positions...");

    auto lock = LockReadWrite(b);

    lix.fields.countdown = new Matrix!XY(cb.xfs, cb.yfs);

    // fx, fy = which x- respective y-frame
    // x,  y  = which pixel inside this frame, offset from frame's top left
    for  (int fy = 0; fy < cb.yfs; ++fy)
     for (int fx = 0; fx < cb.xfs; ++fx) {
        for  (int y = 0; y < cb.yl; ++y )
         for (int x = 0; x < cb.xl; ++x ) {
            // Is it the pixel of the eye?
            const int real_x = 1 + fx * (cb.xl + 1) + x;
            const int real_y = 1 + fy * (cb.yl + 1) + y;
            if (al_get_pixel(b, real_x, real_y) == color.lixFileEye) {
                countdown.set(fx, fy, XY(x, y-1));
                goto GOTO_NEXTFRAME;
            }
            // If not yet gone to GOTO_NEXTFRAME:
            // Use the XY of the frame left to the current one if there was
            // nothing found, and a default value for the leftmost frames.
            // Frames (0, y) and (1, y) are the skill button images.
            if (y == cb.yl - 1 && x == cb.xl - 1) {
                if (fx < 3) countdown.set(fx, fy, XY(cb.xl / 2 - 1, 12));
                else        countdown.set(fx, fy, countdown.get(fx - 1, fy));
            }
        }
        GOTO_NEXTFRAME:
        if (fy == Ac.blocker) {
            XY blockerEyes = countdown.get(fx, fy);
            blockerEyes.x = lix.enums.exOffset;
            countdown.set(fx, fy, blockerEyes);
        }
    }
    // All pixels of the entire spritesheet have been examined.

    // ########################################################################
    // Done making the matrix, now eidrecoloring. That will be very slow. #####
    // ########################################################################

    // DTODOLANG
    displayStartupMessage("Recoloring Lix sprites for multiplayer...");

    // Prepare Lix sprites in multiple colors
    recolor_into_vector(cb, spritesheets, magicnrSpritesheets);

    // DTODOLANG
    displayStartupMessage("Recoloring panel info icons for multiplayer...");

    // local function that is called twice immediately
    void q(in Filename fn, ref Cutbit[Style] vec, in int magicnr)
    {
        Cutbit cb_icons = getInternalMutable(fn);
        assert (cb_icons && cb_icons.valid,
            format("can't get bitmap for magicnr %d", magicnr));
        if (! cb_icons || ! cb_icons.valid)
            return;
        Albit  cb_bmp   = cb_icons.albit;
        auto lock_icons = LockReadWrite(cb_bmp);
        recolor_into_vector(cb_icons, vec, magicnr);
    }
    q(fileImageGame_icon,   panelInfoIcons,   magicnrPanelInfoIcons);

    // DTODOLANG
    displayStartupMessage("Recoloring skill buttons for multiplayer...");
    q(fileImageSkillIcons, skillButtonIcons, magicnrSkillButtonIcons);

    // DTODOLANG
    displayStartupMessage("Recoloring GUI elements...");

    // Make GUI elements have the correct colors. We assume the user file
    // to have been loaded already, and therefore the correct GUI colors
    // have been computed.
    eidrecol(fileImageApi_number);
    eidrecol(fileImageEdit_flip);
    eidrecol(fileImageEditHatch);
    eidrecol(fileImageEdit_panel);
    eidrecol(fileImageGame_arrow);
    eidrecol(fileImageGame_icon);
    eidrecol(fileImageGameNuke);
    eidrecol(fileImageGame_panel);
    eidrecol(fileImageGamePanel2);
    eidrecol(fileImageGamePanelhints);
    eidrecol(fileImageGame_spi_fix);
    eidrecol(fileImageGamePause);
    eidrecol(fileImageLobbySpec);
    eidrecol(fileImageMenuCheckmark);
    eidrecol(fileImagePreviewIcon);

    // DTODO: move load_all_file_replacements(); into obj_lib

    auto toAssert = getSkillButtonIcon(Style.garden);
    assert (toAssert);
    assert (toAssert.valid);
}



void deinitialize()
{
    destroyArray(skillButtonIcons);
    destroyArray(panelInfoIcons);
    destroyArray(spritesheets);
    destroyArray(internal);

    destroy(nullCutbit);
    nullCutbit = null;
}



private Cutbit getInternalMutable(in Filename fn)
{
    Filename correctScale(in Filename f)
    {
        return new Filename(scaleDir ~ f.file);
    }
    string str = correctScale(fn).rootlessNoExt;
    if (auto ret = str in internal)
        return *ret;

    // if not yet returned, fall back onto non-scaled bitmap
    str = fn.rootlessNoExt;
    if (auto ret = str in internal)
        return *ret;
    else
        return nullCutbit;
}



const(Cutbit) getInternal(in Filename fn)
{
    return getInternalMutable(fn);
}



const(Cutbit) getLixSpritesheet(in Style st)
{
    if (auto ret = st in spritesheets)
        return *ret;
    else
        return nullCutbit;
}



const(Cutbit) getPanelInfoIcon(in Style st)
{
    if (auto ret = st in panelInfoIcons)
        return *ret;
    else
        return nullCutbit;
}



const(Cutbit) getSkillButtonIcon(in Style st)
{
    if (auto ret = st in skillButtonIcons)
        return *ret;
    else
        return nullCutbit;
}



private:

void eidrecol(in Filename fn)
{
    getInternalMutable(fn).eidrecol(0);
}



void eidrecol(Cutbit cutbit, in int magicnr)
{
    // don't do anything for magicnr == magicnrSpritesheets. This function
    // is about GUI recoloring, not player color recoloring. All GUI portions
    // of the spritesheets have been moved to the skill buttons in 2015-10.
    if (magicnr == magicnrSpritesheets)
        return;

    Albit bitmap = cutbit.albit;
    assert (bitmap);
    if (! bitmap) return;

    if (magicnr == 0) {
        auto region = al_lock_bitmap(bitmap,
         ALLEGRO_PIXEL_FORMAT.ALLEGRO_PIXEL_FORMAT_ANY,
         ALLEGRO_LOCK_READWRITE);
        assert (region, "can't lock bitmap despite magicnr == 0");
    }
    auto drata = DrawingTarget(bitmap);

    alias al_put_pixel pp;

    immutable bmp_xl = al_get_bitmap_width (bitmap);
    immutable bmp_yl = al_get_bitmap_height(bitmap);

    if (! magicnr)
     for (int y = 0; y < bmp_yl; ++y) {
        immutable bool light = (y > cutbit.yl);
        if (light) for (int x = 0; x < bmp_xl; ++x) {
            immutable AlCol c = al_get_pixel(bitmap, x, y);
            if      (c == color.black)     pp(x, y, color.transp);
            else if (c == color.guiFileSha) pp(x, y, color.guiSha);
            else if (c == color.guiFileD)   pp(x, y, color.guiPicOnD);
            else if (c == color.guiFileM)   pp(x, y, color.guiPicOnM);
            else if (c == color.guiFileL)   pp(x, y, color.guiPicOnL);
        }
        else for (int x = 0; x < bmp_xl; ++x) {
            immutable AlCol c = al_get_pixel(bitmap, x, y);
            if      (c == color.black)     pp(x, y, color.transp);
            else if (c == color.guiFileSha) pp(x, y, color.guiSha);
            else if (c == color.guiFileD)   pp(x, y, color.guiPicD);
            else if (c == color.guiFileM)   pp(x, y, color.guiPicM);
            else if (c == color.guiFileL)   pp(x, y, color.guiPicL);
        }
    }
    else if (magicnr == magicnrSkillButtonIcons)
     for (int y = cutbit.yl + 1; y < bmp_yl; ++y) { // only row 1 of rows 0, 1
        for (int x = 0; x < bmp_xl; ++x) {
            immutable AlCol c = al_get_pixel(bitmap, x, y);
            if      (c == color.black)     pp(x, y, color.transp);
            else if (c == color.guiFileSha) pp(x, y, color.guiSha);
            else if (c == color.guiFileD)   pp(x, y, color.guiPicD);
            else if (c == color.guiFileM)   pp(x, y, color.guiPicM);
            else if (c == color.guiFileL)   pp(x, y, color.guiPicL);
        }
    }
    else if (magicnr == magicnrPanelInfoIcons) {
        // Recolor the API things (except shadow, which will be done in
        // an upcoming loop) in the second row.
        for (int y = cutbit.yl + 1; y < 2 * (cutbit.yl + 1); ++y)
         for (int x = 0; x < bmp_xl; ++x) {
            immutable AlCol c = al_get_pixel(bitmap, x, y);
            if      (c == color.black)   pp(x, y, color.transp);
            else if (c == color.guiFileD) pp(x, y, color.guiPicD);
            else if (c == color.guiFileM) pp(x, y, color.guiPicM);
            else if (c == color.guiFileL) pp(x, y, color.guiPicL);
        }
        // Recolor the shadow of all frames
        for (int y = 0; y < bmp_yl; ++y)
         for (int x = 0; x < bmp_xl; ++x) {
            immutable AlCol c = al_get_pixel(bitmap, x, y);
            if (c == color.guiFileSha) pp(x, y, color.guiSha);
        }
    }

    if (magicnr == 0) {
        al_unlock_bitmap(bitmap);
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
    Cutbit* rclPtr = (fileImageStyleRecol.rootlessNoExt in internal);
    assert (rclPtr && rclPtr.valid, "can't recolor, missing map image");

    Albit recol = rclPtr.albit;
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

