module graphic.gralib;

import basics.alleg5;
import basics.globconf; // skip Lix recoloring loading in verify mode
import basics.globals;  // name of internal bitmap dir
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
    void eidrecol_api       (in Filename);
    void eidrecol_api       (Cutbit, in int = 0);
    void recolor_into_vector(const(Cutbit), Cutbit[], int = 0);

    // I believe these magic numbers are only to separate between recoloring
    // lixes and recoloring icons. eidrecol behaves differently based on
    // the magic number. recolor_into_vector skips some rows based on them.
    // These magic numbers are a relic from C++/A4 Lix.
    immutable int magicnr_sheet = 1;
    immutable int magicnr_icons = 2;



public:

void initialize()
{
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

    // Make GUI elements have the correct colors. We assume the user file
    // to have been loaded already, and therefore the correct GUI colors
    // have been computed.
    eidrecol_api(file_bitmap_api_number);
    eidrecol_api(file_bitmap_checkbox);
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

    // commented-out test output of the eidrecoloring
    // al_save_bitmap("./atest.png", get(file_bitmap_game_panel).get_albit());

/*
    // Countdown-Matrix erstellen
    const Cutbit& cb = internal[gloB->file_bitmap_lix.
                                get_rootless_no_extension()];
          BITMAP* b  = cb.get_al_bitmap();
    Lixxie::countdown = Lixxie::Matrix(
     cb.get_x_frames(), std::vector <Lixxie::XY> (cb.get_y_frames()) );
    // fx, fy = welcher X- bzw. Y-Frame
    // x,  y  = wo in diesem Frame
    for  (int fy = 0; fy < cb.get_y_frames(); ++fy)
     for (int fx = 0; fx < cb.get_x_frames(); ++fx) {
        for  (int y = 0; y < cb.get_yl(); ++y )
         for (int x = 0; x < cb.get_xl(); ++x ) {
            // Is it the pixel of the eye?
            const int real_x = 1 + fx * (cb.get_xl() + 1) + x;
            const int real_y = 1 + fy * (cb.get_yl() + 1) + y;
            if (_getpixel16(b, real_x, real_y) == color[COL_LIXFILE_EYE]) {
                Lixxie::countdown[fx][fy].x = x;
                Lixxie::countdown[fx][fy].y = y - 1;
                goto GOTO_NEXTFRAME;
            }
            // If not yet gone to GOTO_NEXTFRAME:
            // Use the XY of the frame left to the current one if there was
            // nothing found, and a default value for the leftmost frames.
            // Frames (0, y) and (1, y) are the skill button images.
            if (y == cb.get_yl() - 1 && x == cb.get_xl() - 1) {
                if (fx < 3) {
                    Lixxie::countdown[fx][fy].x = cb.get_xl() / 2 - 1;
                    Lixxie::countdown[fx][fy].y = 12;
                }
                else Lixxie::countdown[fx][fy] = Lixxie::countdown[fx - 1][fy];
            }
        }
        GOTO_NEXTFRAME:
        if (fy == LixEn::BLOCKER - 1) {
            Lixxie::countdown[fx][fy].x = LixEn::ex_offset;
        }
    }
    // Alle Pixel sind abgegrast.
*/

/*
    // Prepare Lix sprites in multiple colors and
    // prepare panel icons in multiple colors. recolor_lix is a speed switch:
    // In replay verify mode, there is no relocoring, only copying
    recolor_into_vector(recolor_lix, cb, style, magicnr_sheet);
    recolor_into_vector(recolor_lix, internal[gloB->file_bitmap_game_icon.
                        get_rootless_no_extension()], icons, magicnr_icons);

    load_all_file_replacements();
*/
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

    mixin(temp_lock!"bitmap");
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
    else assert (false, "DTODO: other magignrs not implemented!");
/*
    else if (magicnr == magicnr_sheet)
     for (int y = 0; y < bitmap->h; ++y) {
        for (int x = 0; x < 2 * (cutbit.get_xl() + 1); ++x) {
            const AlCol c = ::getpixel(bitmap, x, y);
            if      (c == color[COL_API_FILE_SHADOW]) putpixel(bitmap, x, y,
                          color[COL_API_SHADOW]);
            else if (x < cutbit.get_xl() + 1) continue;
            else if (c == color[COL_BLACK]) putpixel(bitmap, x, y,
                          color[COL_PINK]);
            else if (c == color[COL_API_FILE_D]) putpixel(bitmap, x, y,
                          color[COL_API_PIC_D]);
            else if (c == color[COL_API_FILE_M]) putpixel(bitmap, x, y,
                          color[COL_API_PIC_M]);
            else if (c == color[COL_API_FILE_L]) putpixel(bitmap, x, y,
                          color[COL_API_PIC_L]);
        }
    }
    else if (magicnr == magicnr_icons) {
        // Recolor the API things (except shadow, which will be done in
        // an upcoming loop) in the second row.
        for (int y = cutbit.get_yl() + 1; y < 2 * (cutbit.get_yl() + 1); ++y)
         for (int x = 0; x < bitmap->w; ++x) {
            const AlCol c = ::getpixel(bitmap, x, y);
            if      (c == color[COL_BLACK]) putpixel(bitmap, x, y,
                          color[COL_PINK]);
            else if (c == color[COL_API_FILE_D]) putpixel(bitmap, x, y,
                          color[COL_API_PIC_D]);
            else if (c == color[COL_API_FILE_M]) putpixel(bitmap, x, y,
                          color[COL_API_PIC_M]);
            else if (c == color[COL_API_FILE_L]) putpixel(bitmap, x, y,
                          color[COL_API_PIC_L]);
        }
        // Recolor the shadow of all frames
        for (int y = 0; y < bitmap->h; ++y)
         for (int x = 0; x < bitmap->w; ++x) {
            const AlCol c = ::getpixel(bitmap, x, y);
            if (c == color[COL_API_FILE_SHADOW]) putpixel(bitmap, x, y,
                          color[COL_API_SHADOW]);
        }
    }
*/
}
