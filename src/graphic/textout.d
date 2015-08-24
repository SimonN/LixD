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
AlFont djvu_s;
AlFont djvu_m;

private float _sha_offs;    // x and y offset for printing the text shadow
private float _djvu_m_offs; // Gui code should think this has a height of 20
                            // geoms, see gui.geometry. We compute this offset.
                            // This affects the y pos for djvu_m.

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

    if (! djvu_s) djvu_s = font_al;
    if (! djvu_m) djvu_m = font_al;
    assert (djvu_s);
    assert (djvu_m);

    _sha_offs    = magnif;
    _djvu_m_offs = magnif * 4 - 3;
}



void deinitialize()
{
    if (djvu_m != null && djvu_m != font_al) al_destroy_font(djvu_m);
    if (djvu_s != null && djvu_s != font_al) al_destroy_font(djvu_s);
    if (font_al)                             al_destroy_font(font_al);
    font_al = djvu_s = djvu_m = null;
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
    if (fla == ALLEGRO_ALIGN_CENTRE) x = to!int(x - sha_offs / 2);
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

// shortcut function for the demo screen, permanent debugging
void drtx(string str, int x, int y)
{
    draw_text(djvu_s, str, x, y, color.white);
}

void drtx(string str, int x, int y, AlCol c)
{
    draw_text(djvu_s, str, x, y, c);
}
