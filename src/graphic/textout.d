module graphic.textout;

import std.algorithm; // min
import std.conv; // to!int for rounding the screen size division
import std.math;
import std.string; // toStringz()

public import basics.alleg5 : AlFont;

import basics.alleg5;
import file.filename;
import graphic.color; // gui shadow color
import hardware.display; // make fonts in a size relative to the display

AlFont fontAl;
AlFont djvuS; // small font for editor's bitmap browser filenames
AlFont djvuM; // medium font for most things, like button descriptions
AlFont djvuL; // large font for number of skills in the game panel

private float _shaOffset;   // x and y offset for printing the text shadow
private float _djvuSYls;    // height of the small font in screen pixels,
                            // used to print text at the bottom of a button
private float _djvuMOffset; // Gui code should think this has a height of 20
                            // geoms, see gui.geometry. We compute this offset.
                            // This affects the y pos for djvuM. No other
                            // font is affected.

public @property float shaOffset()   { return _shaOffset;   }
public @property float djvuMOffset() { return _djvuMOffset; }
public @property float djvuSYls()    { return _djvuSYls;    }

// legacy support: SiegeLord's D bindings don't have this enum flag yet in the
// latest release. This flag is possible in Allegro 5.0 though. I should
// remove this once SiegeLord does a release.
enum ALLEGRO_ALIGN_INTEGER = 4;

void initialize()
{
    fontAl = al_create_builtin_font();
    assert (fontAl);

    immutable float magnif =
        // We would like the fonts to be in relative size to our resolution.
        // See gui.geometry for details. Loading the fonts in size 16 gives the
        // correct height for 24 lines of text stacked vertically on 640 x 480.
        // Other resolutions require us to scale the font size.
        display ? min(al_get_display_height(display) / 480f,
                      al_get_display_width (display) / 640f)
        // If no display exists, we're in noninteractive mode. Since we want
        // text, we'll probably export levels as images. These images should
        // be unscaled.
        : 1f;
    immutable int flags = 0; // we don't need this, A5 function wants it
    immutable Filename fn = new VfsFilename("./data/fonts/djvusans.ttf");
    const(char*) fnp = fn.stringzForReading;

    djvuS = al_load_ttf_font(fnp, to!int(floor(magnif *  8)), flags);
    djvuM = al_load_ttf_font(fnp, to!int(floor(magnif * 14)), flags);
    djvuL = al_load_ttf_font(fnp, to!int(floor(magnif * 20)), flags);
    if (! djvuS) djvuS = fontAl;
    if (! djvuM) djvuM = fontAl;
    if (! djvuL) djvuL = fontAl;
    assert (djvuS);
    assert (djvuM);
    assert (djvuL);

    _shaOffset = min(magnif, magnif / 2.0f + 2);
    _djvuSYls = al_get_font_line_height(djvuS);

    // djvuMOffset should be set such that the font centers nicely on a
    // GUI button/bar having a height of 20 geoms -- equivalent to 1/24th
    // of the screen height. "yls" == y-length in screen pixels, not in geoms
    float yls20g = display ? al_get_display_height(display) / 24f : 20f;
    _djvuMOffset = (yls20g - al_get_font_line_height(djvuM)) / 2f;
}

void deinitialize()
{
    if (djvuL != null && djvuL != fontAl) al_destroy_font(djvuL);
    if (djvuM != null && djvuM != fontAl) al_destroy_font(djvuM);
    if (djvuS != null && djvuS != fontAl) al_destroy_font(djvuS);
    if (fontAl)                           al_destroy_font(fontAl);
    fontAl = djvuS = djvuM = djvuL = null;
}

void
drawText(int tplFlag = ALLEGRO_ALIGN_LEFT)(
    in AlFont f, in string str, float x, float y, in AlCol col
) {
    assert(f);
    immutable char* s = str.toStringz();

    static if (tplFlag == ALLEGRO_ALIGN_CENTRE)
        x = (x - shaOffset / 2).ceil.to!int;
    else static if (tplFlag == ALLEGRO_ALIGN_RIGHT)
        x = (x - shaOffset).ceil.to!int;

    y = to!int(y + (f == djvuM ? djvuMOffset : 0));
    enum fla = tplFlag | ALLEGRO_ALIGN_INTEGER;

    al_draw_text(f, color.guiSha, x + shaOffset, y + shaOffset, fla, s);
    al_draw_text(f, col,          x,             y,             fla, s);
}

alias drawTextCentered = drawText!ALLEGRO_ALIGN_CENTRE;
alias drawTextRight    = drawText!ALLEGRO_ALIGN_RIGHT;
