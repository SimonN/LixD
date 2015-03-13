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

const(Cutbit) get     (in const(Filename));
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
    void eidrecol_api       (in const(Filename));
    void eidrecol_api       (Cutbit, int = 0);
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

    // Make GUI elements have the correct colors
    eidrecol_api(gloB->file_bitmap_api_number);
    eidrecol_api(gloB->file_bitmap_checkbox);
    eidrecol_api(gloB->file_bitmap_edit_flip);
    eidrecol_api(gloB->file_bitmap_edit_hatch);
    eidrecol_api(gloB->file_bitmap_edit_panel);
    eidrecol_api(gloB->file_bitmap_game_arrow);
    eidrecol_api(gloB->file_bitmap_game_icon);
    eidrecol_api(gloB->file_bitmap_game_nuke);
    eidrecol_api(gloB->file_bitmap_game_panel);
    eidrecol_api(gloB->file_bitmap_game_panel_2);
    eidrecol_api(gloB->file_bitmap_game_panel_hints);
    eidrecol_api(gloB->file_bitmap_game_spi_fix);
    eidrecol_api(gloB->file_bitmap_game_pause);
    eidrecol_api(gloB->file_bitmap_lobby_spec);
    eidrecol_api(gloB->file_bitmap_menu_checkmark);
    eidrecol_api(gloB->file_bitmap_preview_icon);

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



const(Cutbit) get(in const(Filename) fn)
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

