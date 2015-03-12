module graphic.textout;

import std.string; // toStringz()

import basics.alleg5;
import graphic.color; // for the shortcut version only
import graphic.torbit;

AlFont font_al;
AlFont djvu_s;
AlFont djvu_m;

void initialize();
void deinitialize();

// DTODO: maybe remove Torbit/AlBit from these and have the caller
// make sure that the correct one is drawn to?
void draw_shaded_text(Torbit bmp, AlFont f, string str,
                      int x, int y, int r, int g, int b)
    { assert (false, "DTODO: unimplemented textout function"); }

void draw_shadow_text(Torbit bmp, AlFont f, string str,
                      int x, int y, AlCol c, AlCol sc);

void draw_shaded_centered_text(AlBit bmp, AlFont f, string str,
                               int x, int y, int r, int g, int b)
    { assert (false, "DTODO: unimplemented textout function"); }

void draw_shadow_centered_text(Torbit bmp, AlFont f, string str,
                               int x, int y, AlCol c, AlCol sc)
    { assert (false, "DTODO: unimplemented textout function"); }

void draw_shadow_fixed_number(Torbit bmp, AlFont f, int number,
                        int x, int y, AlCol c, bool right_to_left, AlCol sc)
    { assert (false, "DTODO: unimplemented textout function"); }

void draw_shadow_fixed_text(Torbit bmp, AlFont f, string str,
                        int x, int y, AlCol c, bool right_to_left, AlCol sc)
    { assert (false, "DTODO: unimplemented textout function"); }

void draw_shadow_fixed_updates_used(Torbit bmp, AlFont f, int number,
                        int x, int y, AlCol c, bool rtol, AlCol sc)
    { assert (false, "DTODO: unimplemented textout function"); }



void initialize()
{
    font_al = al_create_builtin_font();
    assert(font_al);

    immutable int flags = 0;
    djvu_s = al_load_ttf_font("./data/fonts/djvusans.ttf", 10, flags);
    djvu_m = al_load_ttf_font("./data/fonts/djvusans.ttf", 16, flags);

    if (! djvu_s) djvu_s = font_al;
    if (! djvu_m) djvu_m = font_al;
    assert(djvu_s);
    assert(djvu_m);
}



void deinitialize()
{
    if (djvu_m != null && djvu_m != font_al) al_destroy_font(djvu_m);
    if (djvu_s != null && djvu_s != font_al) al_destroy_font(djvu_s);
    if (font_al)                             al_destroy_font(font_al);
    font_al = djvu_s = djvu_m = null;
}

/*
void draw_shaded_text(Torbit& bmp, AlFont f, const char* s,
 int x, int y, int r, int g, int b) {
    textout_ex(bmp.get_al_bitmap(), f, s, x+2, y+2, makecol(r/4, g/4, b/4),-1);
    textout_ex(bmp.get_al_bitmap(), f, s, x+1, y+1, makecol(r/2, g/2, b/2),-1);
    textout_ex(bmp.get_al_bitmap(), f, s, x  , y  , makecol(r  , g  , b  ),-1);
}
*/

void draw_shadow_text(
    Torbit bmp, AlFont f, string str,
    int x, int y,
    AlCol c, AlCol sc
) {
    assert(f);
    immutable int   fla = ALLEGRO_ALIGN_LEFT;
    immutable char* s   = str.toStringz();
    mixin(temp_target!"bmp.get_al_bitmap()");

    al_draw_text(f, sc, x + 1, y + 1, fla, s);
    al_draw_text(f, c,  x,     y,     fla, s);
}

// shortcut function while debugging
void drtx(Torbit bmp, string str, int x, int y)
{
    draw_shadow_text(bmp, djvu_m, str, x, y, color.white, color.shadow);
}

void drtx(Torbit bmp, string str, int x, int y, AlCol c)
{
    draw_shadow_text(bmp, djvu_m, str, x, y, c, color.shadow);
}

/*
void draw_shaded_centered_text(BITMAP *bmp, AlFont f, const char* s,
 int x, int y, int r, int g, int b) {
    textout_centre_ex(bmp, f, s, x+1, y+2, makecol(r/4, g/4, b/4), -1);
    textout_centre_ex(bmp, f, s, x  , y+1, makecol(r/2, g/2, b/2), -1);
    textout_centre_ex(bmp, f, s, x-1, y  , makecol(r  , g  , b  ), -1);
}
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
