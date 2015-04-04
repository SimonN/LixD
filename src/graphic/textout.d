module graphic.textout;

import std.conv; // to!int for rounding the screen size division
import std.math;
import std.string; // toStringz()

import basics.alleg5;
import graphic.color; // for the shortcut version only
import hardware.display; // make fonts in a size relative to the display

AlFont font_al;
AlFont djvu_s;
AlFont djvu_m;

private float sha_offs; // x and y offset for printing the text shadow

/*  void initialize();
 *  void deinitialize();
 *
 *  void draw_text(font, str, x, y, col)
 *  void draw_text_centered(...)
 */


void initialize()
{
    font_al = al_create_builtin_font();
    assert (font_al);

    // We would like the fonts to be in relative size to our resolution.
    // See gui.geometry for details. Loading the fonts in size 16 gives the
    // correct height for 24 lines of text stacked vertically on 640 x 480.
    // Other resolutions require us to scale the font size.
    assert (display, "need display height to estimate font size");
    sha_offs            = al_get_display_height(display) / 480f;
    immutable int size  = floor(sha_offs).to!int;
    immutable int flags = 0;

    djvu_s = al_load_ttf_font("./data/fonts/djvusans.ttf", size * 10, flags);
    djvu_m = al_load_ttf_font("./data/fonts/djvusans.ttf", size * 16, flags);

    if (! djvu_s) djvu_s = font_al;
    if (! djvu_m) djvu_m = font_al;
    assert (djvu_s);
    assert (djvu_m);
}



void deinitialize()
{
    if (djvu_m != null && djvu_m != font_al) al_destroy_font(djvu_m);
    if (djvu_s != null && djvu_s != font_al) al_destroy_font(djvu_s);
    if (font_al)                             al_destroy_font(font_al);
    font_al = djvu_s = djvu_m = null;
}



void
draw_text(
    AlFont f, string str,
    float x, float y, AlCol col, in int fla = ALLEGRO_ALIGN_LEFT
) {
    assert(f);
    immutable char* s = str.toStringz();
    if (fla == ALLEGRO_ALIGN_CENTRE) x = to!int(x - sha_offs / 2);
    y = to!int(y);

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



// shortcut function while debugging
void drtx(string str, int x, int y)
{
    draw_text(djvu_s, str, x, y, color.white);
}

void drtx(string str, int x, int y, AlCol c)
{
    draw_text(djvu_s, str, x, y, c);
}

/*
void draw_shadow_centered_text(
 Torbit& bmp, AlFont f, const char* s, int x, int y, int c, int sc) {
    textout_centre_ex(bmp.get_al_bitmap(), f, s, x+1, y+1, sc, -1);
    textout_centre_ex(bmp.get_al_bitmap(), f, s, x  , y  , c,  -1);
}
void draw_shadow_fixed_number(
 Torbit& bmp, AlFont f, int number, int x, int y,
 int c, bool right_to_left, int sc) {
    std::ostringstream s;
    s << number;
    draw_shadow_fixed_text(bmp,
     f, s.str(), x, y, c, right_to_left, sc);
}
void draw_shadow_fixed_text(
 Torbit& bmp, AlFont f, const std::string& s, int x, int y,
 int c, bool right_to_left, int sc) {
    char ch[2]; ch[1] = '\0';
    for (std::string::const_iterator i
     =  (right_to_left ? --s.end() : s.begin());
     i!=(right_to_left ? --s.begin() : s.end());
        (right_to_left ? --i : ++i))
    {
        if (right_to_left) x -= 10;
        ch[0] = *i;
        if (ch[0] >= '0' && ch[0] <= '9')
             Help::draw_shadow_text         (bmp, f, ch, x,     y, c, sc);
        else Help::draw_shadow_centered_text(bmp, f, ch, x + 5, y, c, sc);
        if (!right_to_left) x += 10;
    }
}
void draw_shadow_fixed_updates_used(
 Torbit& bmp, AlFont f, int number, int x, int y,
 int c, bool right_left, int sc) {
    // Minuten
    std::ostringstream s;
    s << number / (gloB->updates_per_second * 60);
    s << ':';
    // Sekunden
    if  ((number / gloB->updates_per_second) % 60 < 10) s << '0';
    s << (number / gloB->updates_per_second) % 60;
    // s += useR->language == Language::GERMAN ? ',' : '.';
    // Sekundenbruchteile mit zwei Stellen
    // ...schreiben wir nicht. Wird zu unuebersichtlich.
    // int frac = number % Gameplay::updates_per_second
    //            * 100  / Gameplay::updates_per_second;
    // if (frac < 10) s += '0';
    // s += frac;
    draw_shadow_fixed_text(bmp, f, s.str(), x, y, c, right_left, sc);
}
// Ende der Schattentexte
*/
