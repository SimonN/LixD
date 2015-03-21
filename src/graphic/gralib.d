module graphic.gralib;

import basics.alleg5;
import basics.globconf; // skip Lix recoloring loading in verify mode
import basics.globals;  // name of internal bitmap dir
import basics.matrix;
import graphic.color;   // replace pink with transparencys
import graphic.cutbit;
import file.filename;
import file.search;
import lix.enums;

// Graphics library, loads spritesheets and offers them for use via string
// lookup. This does not handle Lix terrain, special objects, or L1/L2 graphics
// sets. All of those are handled by the tile library.

void initialize();
void deinitialize();

const(Cutbit) get     (in Filename);
const(Cutbit) get_lix (in Style);
const(Cutbit) get_icon(in Style); // for the panel

deprecated void replace_filestring(in string) { } // move to objlib



private:

    Cutbit[string] internal;
    Cutbit[Style]  style;
    Cutbit[Style]  icons;

    Cutbit null_cutbit; // invalid bitmap to return instead of null pointer

    // The int variables should be != 0 for the character spreadsheet and
    // similar things that require both a GUI and a player color recoloring.
    // recolor_into_vector() assumes the cutbit's bitmap to be locked already.
    void eidrecol_api       (in Filename);
    void eidrecol_api       (Cutbit, in int = 0);
    void recolor_into_vector(const(Cutbit), ref Cutbit[Style], int = 0);

    // I believe these magic numbers are only to separate between recoloring
    // lixes and recoloring icons. eidrecol behaves differently based on
    // the magic number. recolor_into_vector skips some rows based on them.
    // These magic numbers are a relic from C++/A4 Lix.
    immutable int magicnr_sheet = 1;
    immutable int magicnr_icons = 2;



public:

import file.log; // debugging
alias Log.log writefln;

void initialize()
{
    writefln("entering intitialize");
    null_cutbit = new Cutbit(cast (Cutbit) null);

    // find all internal bitmaps
    auto files = file.search.find_tree(dir_data_bitmap);

    // Since this is unrelated to the terrain name replacements, the internal
    // graphics are saved WITH dir.

    // Save all image filenames without (extension inclusive dot). That will
    // be helpful should we ever switch image file formats, and thus the
    // filename extensions.
    foreach (fn; files) if (fn.has_image_extension()) {
        Cutbit cb = new Cutbit(fn);
        assert (cb, "error loading internal cutbit: " ~ fn.get_rootful());
        al_convert_mask_to_alpha(cb.get_albit(), color.pink);
        internal[fn.get_rootless_no_extension()] = cb;
        assert (get(fn).is_valid(), "not valid: " ~ fn.get_rootful());
    }

    // Create the matrix of eye coordinates.
    // Each frame of the Lix spritesheet has the eyes in some position.
    // The exploder fuse shall start at that position, let's calculate it.
    Cutbit* cb_ptr = (file_bitmap_lix.get_rootless_no_extension() in internal);
    assert (cb_ptr, "missing image: the main Lix spritesheet");
    if (! cb_ptr) return;
    Cutbit cb = *cb_ptr;

    AlBit b = cb.get_albit();
    assert (b, "apparently your gfx card can't store the Lix spritesheet");

    mixin(temp_lock!"b");

    lix.enums.countdown = new Matrix!XY(cb.get_x_frames(), cb.get_y_frames());

    writefln("start xy-ing");

    // fx, fy = which x- respective y-frame
    // x,  y  = which pixel inside this frame, offset from frame's top left
    for  (int fy = 0; fy < cb.get_y_frames(); ++fy)
     for (int fx = 0; fx < cb.get_x_frames(); ++fx) {
        for  (int y = 0; y < cb.get_yl(); ++y )
         for (int x = 0; x < cb.get_xl(); ++x ) {
            // Is it the pixel of the eye?
            const int real_x = 1 + fx * (cb.get_xl() + 1) + x;
            const int real_y = 1 + fy * (cb.get_yl() + 1) + y;
            if (al_get_pixel(b, real_x, real_y) == color.lixfile_eye) {
                countdown.set(fx, fy, XY(x, y-1));
                goto GOTO_NEXTFRAME;
            }
            // If not yet gone to GOTO_NEXTFRAME:
            // Use the XY of the frame left to the current one if there was
            // nothing found, and a default value for the leftmost frames.
            // Frames (0, y) and (1, y) are the skill button images.
            if (y == cb.get_yl() - 1 && x == cb.get_xl() - 1) {
                if (fx < 3) countdown.set(fx, fy, XY(cb.get_xl() / 2 - 1, 12));
                else        countdown.set(fx, fy, countdown.get(fx - 1, fy));
            }
        }
        GOTO_NEXTFRAME:
        if (fy == Ac.BLOCKER - 1) {
            XY blocker_eyes = countdown.get(fx, fy);
            blocker_eyes.x = lix.enums.ex_offset;
            countdown.set(fx, fy, blocker_eyes);
        }
    }
    // All pixels of the entire spritesheet have been examined.

    writefln("done xy-ing");

    // ########################################################################
    // Done making the matrix, now eidrecoloring. That will be very slow. #####
    // ########################################################################

    // Prepare Lix sprites in multiple colors
    recolor_into_vector(cb, style, magicnr_sheet);

    // Prepare the panel icons in multiple colors
    Cutbit* icon_ptr = (file_bitmap_game_icon.get_rootless_no_extension()
                       in internal);
    assert (icon_ptr, "missing image: in-game panel icon of a Lix");
    if (icon_ptr) {
        Cutbit cb_icons = *icon_ptr;
        AlBit  cb_bmp   = cb_icons.get_albit();
        mixin(temp_lock!"cb_bmp");
        recolor_into_vector(cb_icons, icons, magicnr_icons);
    }

    // Make GUI elements have the correct colors. We assume the user file
    // to have been loaded already, and therefore the correct GUI colors
    // have been computed.
    writefln("starting recoloring");
    eidrecol_api(file_bitmap_api_number);
    writefln("done recoloring the 1st one, api number");
    eidrecol_api(file_bitmap_checkbox);
    writefln("done recoloring the 2nd one, api checkbox");
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
    writefln("done recoloring");

    // DTODO: move load_all_file_replacements(); into obj_lib

    // DTODO: move this line ahead and see how much time we save, and whether
    // we get crashes
    if (basics.globconf.verify_mode) return;
}



void deinitialize()
{
    foreach (cb; internal) clear(cb);
    foreach (cb; style)    clear(cb);
    foreach (cb; icons)    clear(cb);
    internal    = null;
    style       = null;
    icons       = null;

    clear(null_cutbit);
    null_cutbit = null;
}



const(Cutbit) get(in Filename fn)
{
    immutable string str = fn.get_rootless_no_extension();
    if (str in internal) return internal[str];
    else return null_cutbit;
}



const(Cutbit) get_lix(in Style st)
{
    if (st in style) return style[st];
    else return null_cutbit;
}



const(Cutbit) get_icon(in Style st)
{
    if (st in icons) return icons[st];
    else return null_cutbit;
}



private:

void eidrecol_api(in Filename fn)
{
    Cutbit* cutbit = (fn.get_rootless_no_extension() in internal);
    if (cutbit) eidrecol_api(*cutbit);
}



void eidrecol_api(Cutbit cutbit, in int magicnr)
{
    AlBit bitmap = cutbit.get_al_bitmap();
    assert (bitmap);
    if (! bitmap) return;

    if (magicnr == 0) {
        auto region = al_lock_bitmap(bitmap,
         ALLEGRO_PIXEL_FORMAT.ALLEGRO_PIXEL_FORMAT_ANY,
         ALLEGRO_LOCK_READWRITE);
        assert (region, "can't lock bitmap despite magicnr == 0");
    }
    mixin(temp_target!"bitmap");

    alias al_put_pixel pp;

    immutable bmp_xl = al_get_bitmap_width (bitmap);
    immutable bmp_yl = al_get_bitmap_height(bitmap);

    if (! magicnr)
     for (int y = 0; y < bmp_yl; ++y) {
        immutable bool light = (y > cutbit.get_yl());
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
    else if (magicnr == magicnr_sheet)
     for (int y = 0; y < bmp_yl; ++y) {
        for (int x = 0; x < 2 * (cutbit.get_xl() + 1); ++x) {
            immutable AlCol c = al_get_pixel(bitmap, x, y);
            if      (c == color.gui_f_sha) pp(x, y, color.gui_sha);
            else if (x < cutbit.get_xl() + 1) continue;
            else if (c == color.black)   pp(x, y, color.transp);
            else if (c == color.gui_f_d) pp(x, y, color.gui_pic_d);
            else if (c == color.gui_f_m) pp(x, y, color.gui_pic_m);
            else if (c == color.gui_f_l) pp(x, y, color.gui_pic_l);
        }
    }
    else if (magicnr == magicnr_icons) {
        // Recolor the API things (except shadow, which will be done in
        // an upcoming loop) in the second row.
        for (int y = cutbit.get_yl() + 1; y < 2 * (cutbit.get_yl() + 1); ++y)
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
    const(Cutbit)     cutbit,
    ref Cutbit[Style] vector,
    int               magicnr
) {
    // We assume the bitmap to be locked already. If you write code calling
    // this function, make sure it's locked. Otherwise, everything will work
    // extremely slowly.

    // debugging
    import file.log;

    assert (cutbit.is_valid());
    Cutbit* rcl_p = (file_bitmap_lix_recol.get_rootless_no_extension()
                     in internal);
    assert (rcl_p && rcl_p.is_valid(), "can't recolor, missing map image");

    AlBit recol = rcl_p .get_albit();
    AlBit lix   = cutbit.get_albit();
    if (!recol || !lix) return;

    immutable int   recol_xl  = al_get_bitmap_width (recol);
    immutable int   recol_yl  = al_get_bitmap_height(recol);
    immutable int   lix_xl    = al_get_bitmap_width (lix);
    immutable int   lix_yl    = al_get_bitmap_height(lix);
    immutable AlCol col_break = al_get_pixel(lix, lix_xl - 1, 0);

    mixin(temp_lock!"recol");



    void recolor_one_bitmap(AlBit target, in int style_id)
    {
        assert(target);
        assert(style_id < recol_yl - 1);

        // Build the recolor array for this particular style
        AlCol[AlCol] recol_arr;
        for (int conv = 0; conv < recol_xl; ++conv) {
            recol_arr[al_get_pixel(recol, conv, 0)] =
                      al_get_pixel(recol, conv, style_id + 1);
        }

        mixin(temp_target!"target");

        // The first row (y == 0) contains the source pixels. The first style
        // (garden) is at y == 1. Thus the recol->h - 1 is correct as we count
        // styles starting at 0.
        for  (int y = 0; y < lix_yl; y++)
         for (int x = 0; x < lix_xl; x++) {

            // The large Lix spritesheet has a column with greyed-out
            // skills. These do not get recolored per player, skip them.
            if (x == cutbit.get_xl() + 1 && magicnr == magicnr_sheet) {
                // skip the column with the greyed out skill icons
                x += cutbit.get_xl();
                continue;
            }

            // I don't recall what this else-if does, it's probably important.
            else if (magicnr == magicnr_icons
             && y >= cutbit.get_yl() + 1
             && y <  2 * (cutbit.get_yl() + 1)) {
                // skip all x pixels in the second row in this
                continue;
            }

            immutable AlCol col = al_get_pixel(lix, x, y);
            if (col == col_break) {
                // bad solution here: immediately begin next pixel, too slow
                // bad solution too:  immediately begin next row, because
                //                    we may have separating col_break-colored
                //                    frames in the file.
                // good solution:     immediately begin next frame
                x += cutbit.get_xl();
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



    foreach (int i; 0 .. Style.STYLE_MAX) {
        Style st = cast (Style) i;
        vector[st] = new Cutbit(cutbit);
        AlBit target = vector[st].get_albit();
        assert (target);

        mixin(temp_lock!"target");
        writefln("recol in vec: bitmap locked: %d", i);
        recolor_one_bitmap(target, i);

        // Invoke eidrecol on the bitmap. Whenever eidrecol is invoked
        // with a magicnr != 0, it does not lock/unlock the bitmaps itself,
        // but assumes they are locked.
        // writefln("eidrecol now: %d", i);
        eidrecol_api(vector[st], magicnr);
    }

    // debugging: saving to files
    static if (false)
     foreach (int i; 0 .. Style.STYLE_MAX) {
        Style st = cast (Style) i;
        import std.string;
        al_save_bitmap(format("./nagetier-%d-%d.png", magicnr, i).toStringz, vector[st].get_albit());
        writefln("done saving: %d", i);
    }

}

