module graphic.textout;

import std.algorithm; // min
import std.conv; // to!int for rounding the screen size division
import std.math;
import std.string; // toStringz()

public import basics.alleg5 : AlFont;

import basics.alleg5;
import graphic.color; // for the shortcut version only
import hardware.display; // make fonts in a size relative to the display

AlFont font_al;
AlFont djvu_s; // small font for editor's bitmap browser filenames
AlFont djvu_m; // medium font for most things, like button descriptions
AlFont djvu_l; // large font for number of skills in the game panel

private float _sha_offs;    // x and y offset for printing the text shadow

private float _djvu_m_offs; // Gui code should think this has a height of 20
                            // geoms, see gui.geometry. We compute this offset.
                            // This affects the y pos for djvu_m. No other
                            // font is affected.

public @property float sha_offs()    { return _sha_offs;    }
public @property float djvu_m_offs() { return _djvu_m_offs; }

/*  void initialize();
 *  void deinitialize();
 *
 *  void draw_text(font, str, x, y, col)
 *  void draw_text_centered(...)
 *  void draw_text_right(...)
 */

// legacy support: SiegeLord's D bindings don't have this enum flag yet in the
// latest release. This flag is possible in Allegro 5.0 though. I should
// remove this once SiegeLord does a release.
enum ALLEGRO_ALIGN_INTEGER = 4;

void initialize()
{
    font_al = al_create_builtin_font();
    assert (font_al);

    // We would like the fonts to be in relative size to our resolution.
    // See gui.geometry for details. Loading the fonts in size 16 gives the
    // correct height for 24 lines of text stacked vertically on 640 x 480.
    // Other resolutions require us to scale the font size.
    assert (display, "need display height to estimate font size");
    immutable float magnif = min(al_get_display_height(display) / 480f,
                                 al_get_display_width (display) / 640f);
    immutable int flags = 0; // we don't need this, A5 function wants it
    immutable string fn = "./data/fonts/djvusans.ttf";

    djvu_s = al_load_ttf_font(fn.ptr, to!int(floor(magnif *  8)), flags);
    djvu_m = al_load_ttf_font(fn.ptr, to!int(floor(magnif * 14)), flags);
    djvu_l = al_load_ttf_font(fn.ptr, to!int(floor(magnif * 20)), flags);

    if (! djvu_s) djvu_s = font_al;
    if (! djvu_m) djvu_m = font_al;
    if (! djvu_l) djvu_l = font_al;
    assert (djvu_s);
    assert (djvu_m);
    assert (djvu_l);

    _sha_offs = magnif;

    // djvu_m_offs should be set such that the font centers nicely on a
    // GUI button/bar having a height of 20 geoms -- equivalent to 1/24th
    // of the screen height. "yls" == y-length in screen pixels, not in geoms
    int bounds_yls;
    int dummy;
    al_get_text_dimensions(djvu_m, "A/f/g/y)(".toStringz,
        &dummy, &dummy, &dummy, &bounds_yls, &dummy, &dummy);
    int descent_yls = al_get_font_descent(djvu_m);

    float yls_20_geoms   = al_get_display_height(display) * 24 / 480f;
    _djvu_m_offs = (yls_20_geoms - bounds_yls - descent_yls) / 2f;
    // subtracting descent_yls looks better somehow, even though it should
    // have been included in bounds_yls. The main goal is to make it look
    // nice on various screen sizes, not to make it theoretically correct.
}



void deinitialize()
{
    if (djvu_l != null && djvu_l != font_al) al_destroy_font(djvu_l);
    if (djvu_m != null && djvu_m != font_al) al_destroy_font(djvu_m);
    if (djvu_s != null && djvu_s != font_al) al_destroy_font(djvu_s);
    if (font_al)                             al_destroy_font(font_al);
    font_al = djvu_s = djvu_m = djvu_l = null;
}



// the main public function, callable by everyone
// other public functions should pass font drawing to this one, it does
// some positional computations with x and y
void
draw_text(
    AlFont f, string str,
    float x, float y, AlCol col,
    int fla = ALLEGRO_ALIGN_LEFT
) {
    assert(f);
    immutable char* s = str.toStringz();
    if (fla == ALLEGRO_ALIGN_CENTRE) x = to!int(ceil(x - sha_offs / 2));
    y = to!int(y + (f == djvu_m ? djvu_m_offs : 0));
    fla |= ALLEGRO_ALIGN_INTEGER;

    al_draw_text(f, color.gui_sha, x + sha_offs, y + sha_offs, fla, s);
    al_draw_text(f, col,           x,            y,            fla, s);
}



void
draw_text_centered(
    AlFont f, string str,
    float x, float y, AlCol c
) {
    draw_text(f, str, x, y, c, ALLEGRO_ALIGN_CENTRE);
}



void
draw_text_right(
    AlFont f, string str,
    float x, float y, AlCol c
) {
    draw_text(f, str, x, y, c, ALLEGRO_ALIGN_RIGHT);
}
