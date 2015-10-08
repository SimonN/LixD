module graphic.gralib;

import std.conv; // scale to
import std.string; // format

import basics.alleg5;
import basics.globconf; // skip Lix recoloring loading in verify mode
import basics.globals;  // name of internal bitmap dir
import basics.help;
import basics.matrix;
import graphic.color;   // replace pink with transparencys
import graphic.cutbit;
import file.filename;
import file.search;
import hardware.display; // display startup progress
import lix.enums;

/* Graphics library, loads spritesheets and offers them for use via string
 * lookup. This does not handle Lix terrain, special objects, or L1/L2 graphics
 * sets. All of those are handled by the tile library.
 *
 *  void initialize();
 *  void deinitialize();
 *
 *  void set_scale_from_gui(float); // exact value, what gui.geometry thinks
 *
 *  const(Cutbit) get_internal(in Filename);
 *  const(Cutbit) get_lix     (in Style);
 *  const(Cutbit) get_icon    (in Style); -- for the panel
 */

private:

    Cutbit[string] internal;
    Cutbit[Style]  spritesheets;
    Cutbit[Style]  panel_info_icons;
    Cutbit[Style]  skill_button_icons;

    Cutbit null_cutbit; // invalid bitmap to return instead of null pointer

    string scale_dir = dir_data_bitmap.rootless; // load from which dir?

/*  void eidrecol_api       (in Filename);
 *  void eidrecol_api       (Albit, in int = 0);
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
    immutable int magicnr_spritesheets = 1;
    immutable int magicnr_panel_info_icons = 2;
    immutable int magicnr_skill_button_icons = 3;



public:

void set_scale_from_gui(in float scale)
{
    scale_dir =
        scale < 1.5f ? dir_data_bitmap.rootless
     :  scale < 2.0f ? dir_data_bitmap_scale.rootless ~ "150/"
     :  scale < 3.0f ? dir_data_bitmap_scale.rootless ~ "200/"
     :                 dir_data_bitmap_scale.rootless ~ "300/";
}



void initialize()
{
    null_cutbit = new Cutbit(cast (Cutbit) null);

    // DTODOLANG
    display_startup_message("Loading internal bitmaps...");

    // find all internal bitmaps
    auto files = file.search.find_tree(dir_data_bitmap);

    // Since this is unrelated to the terrain name replacements, the internal
    // graphics are saved WITH dir.

    // Save all image filenames without (extension inclusive dot). That will
    // be helpful should we ever switch image file formats, and thus the
    // filename extensions.
    foreach (fn; files) {
        if (fn.has_image_extension()) {
            Cutbit cb = new Cutbit(fn);
            assert (cb, "error loading internal cutbit: " ~ fn.rootful);
            al_convert_mask_to_alpha(cb.albit, color.pink);
            internal[fn.rootless_no_ext] = cb;
            assert (get_internal(fn).valid,
                "can't retrieve from array: " ~ fn.rootful);
        }
    }

    // Create the matrix of eye coordinates.
    // Each frame of the Lix spritesheet has the eyes in some position.
    // The exploder fuse shall start at that position, let's calculate it.
    Cutbit* cb_ptr = (file_bitmap_lix.rootless_no_ext in internal);
    assert (cb_ptr, "missing image: the main Lix spritesheet");
    if (! cb_ptr) return;
    Cutbit cb = *cb_ptr;

    Albit b = cb.albit;
    assert (b, "apparently your gfx card can't store the Lix spritesheet");

    // DTODOLANG
    display_startup_message("Examining Lix spritesheet for eye positions...");

    auto lock = LockReadWrite(b);

    lix.enums.countdown = new Matrix!XY(cb.xfs, cb.yfs);

    // fx, fy = which x- respective y-frame
    // x,  y  = which pixel inside this frame, offset from frame's top left
    for  (int fy = 0; fy < cb.yfs; ++fy)
     for (int fx = 0; fx < cb.xfs; ++fx) {
        for  (int y = 0; y < cb.yl; ++y )
         for (int x = 0; x < cb.xl; ++x ) {
            // Is it the pixel of the eye?
            const int real_x = 1 + fx * (cb.xl + 1) + x;
            const int real_y = 1 + fy * (cb.yl + 1) + y;
            if (al_get_pixel(b, real_x, real_y) == color.lixfile_eye) {
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
        if (fy == Ac.BLOCKER) {
            XY blocker_eyes = countdown.get(fx, fy);
            blocker_eyes.x = lix.enums.ex_offset;
            countdown.set(fx, fy, blocker_eyes);
        }
    }
    // All pixels of the entire spritesheet have been examined.

    // ########################################################################
    // Done making the matrix, now eidrecoloring. That will be very slow. #####
    // ########################################################################

    // DTODOLANG
    display_startup_message("Recoloring Lix sprites for multiplayer...");

    // Prepare Lix sprites in multiple colors
    recolor_into_vector(cb, spritesheets, magicnr_spritesheets);

    // DTODOLANG
    display_startup_message("Recoloring panel info icons for multiplayer...");

    // local function that is called twice immediately
    void q(in Filename fn, ref Cutbit[Style] vec, in int magicnr)
    {
        Cutbit cb_icons = get_internal_mutable(fn);
        assert (cb_icons && cb_icons.valid,
            format("can't get bitmap for magicnr %d", magicnr));
        if (! cb_icons || ! cb_icons.valid)
            return;
        Albit  cb_bmp   = cb_icons.albit;
        auto lock_icons = LockReadWrite(cb_bmp);
        recolor_into_vector(cb_icons, vec, magicnr);
    }
    q(file_bitmap_game_icon,   panel_info_icons,   magicnr_panel_info_icons);

    // DTODOLANG
    display_startup_message("Recoloring skill buttons for multiplayer...");
    q(file_bitmap_skill_icons, skill_button_icons, magicnr_skill_button_icons);

    // DTODOLANG
    display_startup_message("Recoloring GUI elements...");

    // Make GUI elements have the correct colors. We assume the user file
    // to have been loaded already, and therefore the correct GUI colors
    // have been computed.
    eidrecol_api(file_bitmap_api_number);
    eidrecol_api(file_bitmap_edit_flip);
    eidrecol_api(file_bitmap_edit_hatch);
    eidrecol_api(file_bitmap_edit_panel);
    eidrecol_api(file_bitmap_game_arrow);
    eidrecol_api(file_bitmap_game_icon);
    eidrecol_api(file_bitmap_game_nuke);
    eidrecol_api(file_bitmap_game_panel);
    eidrecol_api(file_bitmap_game_panel_2);
    eidrecol_api(file_bitmap_game_panel_hints);
    eidrecol_api(file_bitmap_game_spi_fix);
    eidrecol_api(file_bitmap_game_pause);
    eidrecol_api(file_bitmap_lobby_spec);
    eidrecol_api(file_bitmap_menu_checkmark);
    eidrecol_api(file_bitmap_preview_icon);

    // DTODO: move load_all_file_replacements(); into obj_lib

    auto to_assert = get_skill_button_icon(Style.GARDEN);
    assert (to_assert);
    assert (to_assert.valid);

    // DTODO: move this line ahead and see how much time we save, and whether
    // we get crashes
    if (basics.globconf.verify_mode) return;
}



void deinitialize()
{
    destroy_array(skill_button_icons);
    destroy_array(panel_info_icons);
    destroy_array(spritesheets);
    destroy_array(internal);

    destroy(null_cutbit);
    null_cutbit = null;
}



private Cutbit get_internal_mutable(in Filename fn)
{
    Filename correct_scale(in Filename f)
    {
        return new Filename(scale_dir ~ f.file);
    }
    string str = correct_scale(fn).rootless_no_ext;
    if (auto ret = str in internal)
        return *ret;

    // if not yet returned, fall back onto non-scaled bitmap
    str = fn.rootless_no_ext;
    if (auto ret = str in internal)
        return *ret;
    else
        return null_cutbit;
}



const(Cutbit) get_internal(in Filename fn)
{
    return get_internal_mutable(fn);
}



const(Cutbit) get_spritesheet(in Style st)
{
    if (auto ret = st in spritesheets)
        return *ret;
    else
        return null_cutbit;
}



const(Cutbit) get_panel_info_icon(in Style st)
{
    if (auto ret = st in panel_info_icons)
        return *ret;
    else
        return null_cutbit;
}



const(Cutbit) get_skill_button_icon(in Style st)
{
    if (auto ret = st in skill_button_icons)
        return *ret;
    else
        return null_cutbit;
}



private:

void eidrecol_api(in Filename fn)
{
    get_internal_mutable(fn).eidrecol_api(0);
}



void eidrecol_api(Cutbit cutbit, in int magicnr)
{
    // don't do anything for magicnr == magicnr_spritesheets. This function
    // is about GUI recoloring, not player color recoloring. All GUI portions
    // of the spritesheets have been moved to the skill buttons in 2015-10.
    if (magicnr == magicnr_spritesheets)
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
            else if (c == color.gui_f_sha) pp(x, y, color.gui_sha);
            else if (c == color.gui_f_d)   pp(x, y, color.gui_pic_on_d);
            else if (c == color.gui_f_m)   pp(x, y, color.gui_pic_on_m);
            else if (c == color.gui_f_l)   pp(x, y, color.gui_pic_on_l);
        }
        else for (int x = 0; x < bmp_xl; ++x) {
            immutable AlCol c = al_get_pixel(bitmap, x, y);
            if      (c == color.black)     pp(x, y, color.transp);
            else if (c == color.gui_f_sha) pp(x, y, color.gui_sha);
            else if (c == color.gui_f_d)   pp(x, y, color.gui_pic_d);
            else if (c == color.gui_f_m)   pp(x, y, color.gui_pic_m);
            else if (c == color.gui_f_l)   pp(x, y, color.gui_pic_l);
        }
    }
    else if (magicnr == magicnr_skill_button_icons)
     for (int y = cutbit.yl + 1; y < bmp_yl; ++y) { // only row 1 of rows 0, 1
        for (int x = 0; x < bmp_xl; ++x) {
            immutable AlCol c = al_get_pixel(bitmap, x, y);
            if      (c == color.black)     pp(x, y, color.transp);
            else if (c == color.gui_f_sha) pp(x, y, color.gui_sha);
            else if (c == color.gui_f_d)   pp(x, y, color.gui_pic_d);
            else if (c == color.gui_f_m)   pp(x, y, color.gui_pic_m);
            else if (c == color.gui_f_l)   pp(x, y, color.gui_pic_l);
        }
    }
    else if (magicnr == magicnr_panel_info_icons) {
        // Recolor the API things (except shadow, which will be done in
        // an upcoming loop) in the second row.
        for (int y = cutbit.yl + 1; y < 2 * (cutbit.yl + 1); ++y)
         for (int x = 0; x < bmp_xl; ++x) {
            immutable AlCol c = al_get_pixel(bitmap, x, y);
            if      (c == color.black)   pp(x, y, color.transp);
            else if (c == color.gui_f_d) pp(x, y, color.gui_pic_d);
            else if (c == color.gui_f_m) pp(x, y, color.gui_pic_m);
            else if (c == color.gui_f_l) pp(x, y, color.gui_pic_l);
        }
        // Recolor the shadow of all frames
        for (int y = 0; y < bmp_yl; ++y)
         for (int x = 0; x < bmp_xl; ++x) {
            immutable AlCol c = al_get_pixel(bitmap, x, y);
            if (c == color.gui_f_sha) pp(x, y, color.gui_sha);
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
    Cutbit* rcl_p = (file_bitmap_lix_recol.rootless_no_ext in internal);
    assert (rcl_p && rcl_p.valid, "can't recolor, missing map image");

    Albit recol = rcl_p .albit;
    Albit lix   = cutbit.albit;
    if (!recol || !lix) return;

    immutable int   recol_xl  = al_get_bitmap_width (recol);
    immutable int   recol_yl  = al_get_bitmap_height(recol);
    immutable int   lix_xl    = al_get_bitmap_width (lix);
    immutable int   lix_yl    = al_get_bitmap_height(lix);
    immutable AlCol col_break = al_get_pixel(lix, lix_xl - 1, 0);

    auto lock = LockReadWrite(recol);



    void recolor_one_bitmap(Albit target, in int style_id)
    {
        assert(target);
        assert(style_id < recol_yl - 1);

        // Build the recolor array for this particular style
        AlCol[AlCol] recol_arr;
        for (int conv = 0; conv < recol_xl; ++conv) {
            recol_arr[al_get_pixel(recol, conv, 0)] =
                      al_get_pixel(recol, conv, style_id + 1);
        }

        auto drata = DrawingTarget(target);

        // The first row (y == 0) contains the source pixels. The first style
        // (garden) is at y == 1. Thus the recol->h - 1 is correct as we count
        // styles starting at 0.
        Y_LOOP: for (int y = 0; y < lix_yl; y++)
            X_LOOP: for (int x = 0; x < lix_xl; x++)
        {
            // The skill button icons have two rows: the first has the
            // skills in player colors, the second has them greyed out.
            // Ignore the second row here.
            if (y >= cutbit.yl + 1 && magicnr == magicnr_skill_button_icons) {
                break Y_LOOP;
            }
            // I don't recall what this else-if does, it's probably important.
            else if (magicnr == magicnr_panel_info_icons
                 && y >= cutbit.yl + 1
                 && y <  2 * (cutbit.yl + 1)
            ) {
                // skip all x pixels in the second row in this
                continue;
            }

            immutable AlCol col = al_get_pixel(lix, x, y);
            if (magicnr == magicnr_spritesheets && col == col_break) {
                // bad solution here: immediately begin next pixel, too slow
                // bad solution too:  immediately begin next row, because
                //                    we may have separating col_break-colored
                //                    frames in the file.
                // good solution:     immediately begin next frame
                x += cutbit.xl;
                continue;
            }
            // No exceptions for speed encountered so far. Now do the
            // per-player recoloring. We don't consider the color conversion
            // bitmap (recol) anymore, only recol_arr.
            if (AlCol* col_ptr = (col in recol_arr)) {
                al_put_pixel(x, y, *col_ptr);
            }
            // end of single-pixel color replacement
        }
        // end of for-all-pixels in source bitmap
    }
    // end of function recolor_one_bitmap


    // now invoke the above code on each Lix style
    foreach (int i; 0 .. Style.MAX) {
        Style st = cast (Style) i;
        vector[st] = new Cutbit(cutbit);
        Albit target = vector[st].albit;
        assert (target);

        // DTODOLANG
        if (magicnr == magicnr_spritesheets)
            display_startup_message(style_to_string(st));

        auto lock_target = LockReadWrite(target);
        recolor_one_bitmap(target, i);

        // Invoke eidrecol on the bitmap. Whenever eidrecol is invoked
        // with a magicnr != 0, it does not lock/unlock the bitmaps itself,
        // but assumes they are locked.
        eidrecol_api(vector[st], magicnr);
    }

    static if (false)
     foreach (int i; 0 .. Style.YELLOW) {
        Style st = cast (Style) i;
        al_save_bitmap(format("./nagetier-%d-%d.png", magicnr, i).toStringz,
         vector[st].albit);
    }

}

