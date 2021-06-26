module gui.context;

/* GUI context: Encapsulates almost-globals like fonts and the GUI scaling
 * factor. Usually, we need only one context. For exporting levels to
 * images with GUI components drawn onto the level, we'd like a second context
 * that forces unscaled rendering.
 *
 * I never dispose or destroy contexts or fonts.
 */

import std.algorithm; // min
import std.conv; // to!int for rounding the screen size division
import std.math;
import std.string; // toStringz()
public import basics.alleg5 : Alfont;
import basics.alleg5;
import file.filename;
import graphic.color; // gui shadow color

void initialize(in int aScreenXl, in int aScreenYl)
{
    if (_scaled) {
        assert (aScreenXl == _scaled._screenXls
            &&  aScreenYl == _scaled._screenYls,
            "if you want to switch resolutions, deinitialize the GUI first");
        return;
    }
    _scaled = new Context(aScreenXl, aScreenYl);
    if (aScreenXl == 640 && aScreenYl == 480)
        _unscaled = _scaled;
}

void deinitialize()
{
    void deinitImpl(ref Context ct) {
        if (ct) {
            ct.dispose();
            ct = null;
        }
    }
    deinitImpl(_scaled);
    deinitImpl(_unscaled); // safe even when _scaled was _unscaled before
}

bool forceUnscaledGUIDrawing = false; // public, set to true to choose context

// thickg != 2, because thicks was floored from 2!
@property thickg() { return currentContext._thicks / stretchFactor; }
@property thicks()        { return currentContext._thicks; }
@property screenXlg()     { return currentContext._screenXlg; }
@property screenYlg()     { return currentContext._screenYlg; }
@property screenXls()     { return currentContext._screenXls; }
@property screenYls()     { return currentContext._screenYls; }
@property stretchFactor() { return currentContext._stretchFactor; }
@property mapYls()        { return currentContext.mapYls; }
@property panelYls()      { return screenYls - mapYls; }
@property panelYlg()      { return panelYls / stretchFactor; }
@property mapYlg()        { return mapYls   / stretchFactor; }

@property djvuS() { return currentContext.djvuS; } // terrain browser names
@property djvuM() { return currentContext.djvuM; } // most labels
@property djvuL() { return currentContext.djvuL; } // skill button labels

void drawText(int tplFlag = ALLEGRO_ALIGN_LEFT)(
    in Alfont f, in string str, float x, float y, in Alcol col
) {
    currentContext.drawText!tplFlag(f, str, x, y, col);
}

alias drawTextCentered = drawText!ALLEGRO_ALIGN_CENTRE;
alias drawTextRight    = drawText!ALLEGRO_ALIGN_RIGHT;

// ############################################################################
// #################################################################### private
// ############################################################################

private:

Context _scaled;
Context _unscaled;

const(Context) currentContext()
{
    if (forceUnscaledGUIDrawing) {
        if (! _unscaled)
            _unscaled = new Context(640, 480);
        return _unscaled;
    }
    else {
        assert (_scaled, "call initialize() before using the context");
        return _scaled;
    }
}

final class Context {
    immutable float _screenXlg;
    enum      float _screenYlg = 480f;
    immutable float _screenXls;
    immutable float _screenYls;
    immutable float _stretchFactor;
    immutable int   _thicks;

    // x and y offset for printing the text shadow
    immutable(float) _shaOffset;

    // Gui code should think this has a height of 20 geoms, see gui.geometry.
    // We compute this offset. This affects the y pos for djvuM only.
    // djvuMOffset should be set such that the font centers nicely on a
    // GUI button/bar having a height of 20 geoms.
    immutable(float) _djvuMOffset;

    // To combat blurry screens, print djvuS without shadow on small screens,
    // but print with a dark surrounding
    immutable(bool) _smallScreenDjvuSSurround;

    ALLEGRO_FONT* djvuL; // must be non-const to allow destruction
    ALLEGRO_FONT* djvuM;
    ALLEGRO_FONT* djvuS;

    this(in int aScreenXl, in int aScreenYl)
    in { assert (aScreenYl > 0); }
    do {
        _screenXls     = aScreenXl;
        _screenYls     = aScreenYl;
        _stretchFactor = _screenYls / _screenYlg;
        _screenXlg     = _screenXls / _stretchFactor;
        _thicks = std.math.floor(2.0 * _stretchFactor).to!int;

        // We want the fonts to be in relative size to our resolution.
        // See gui.geometry for details. Loading the fonts in size 16 gives
        // correct height for 24 text lines stacked vertically on 640x480.
        // Other resolutions require us to scale the font size.
        // Unscaled is equivalent to magnif == 1f.
        immutable float magnif = min(aScreenXl / 640f, aScreenYl / 480f);
        djvuS = makeFont( 8 * magnif);
        djvuM = makeFont(14 * magnif);
        djvuL = makeFont(20 * magnif);
        _shaOffset = min(magnif, magnif / 2.0f + 2);
        _smallScreenDjvuSSurround = magnif <= 1.3f;
        _djvuMOffset = (aScreenYl / 24f - al_get_font_line_height(djvuM)) / 2f;
    }

    void dispose()
    {
        void disposeImpl(ref ALLEGRO_FONT* fo)
        {
            al_destroy_font(fo);
            fo = null;
        }
        disposeImpl(djvuS);
        disposeImpl(djvuM);
        disposeImpl(djvuL);
    }

    ALLEGRO_FONT* makeFont(in float size)
    {
        immutable fn = new VfsFilename("./data/fonts/djvusans.ttf");
        ALLEGRO_FONT* f = al_load_ttf_font(
            fn.stringForReading.toStringz, to!int(floor(size)), 0);
        return f ? f : al_create_builtin_font();
    }

    void drawText(int tplFlag = ALLEGRO_ALIGN_LEFT)(
        in Alfont f, in string str, float x, float y, in Alcol col) const
    {
        assert(f);
        immutable char* s = str.toStringz();

        static if (tplFlag == ALLEGRO_ALIGN_CENTRE) {
            // not "- _shaOffset / 2.0" because that looks too far right
            x = (x - _shaOffset).ceil.to!int;
        }
        else static if (tplFlag == ALLEGRO_ALIGN_RIGHT)
            x = (x - _shaOffset).ceil.to!int;

        y = to!int(y + (f == djvuM ? _djvuMOffset : 0));
        enum fla = tplFlag | ALLEGRO_ALIGN_INTEGER;

        if (f == djvuS && _smallScreenDjvuSSurround) {
            // On small screens like 640x480 (where _yls20g is 20),
            // print sharper the small font. Re Nepster's complaint.
            al_draw_text(f, color.guiSha, x - _shaOffset, y, fla, s);
            al_draw_text(f, color.guiSha, x + _shaOffset, y, fla, s);
            al_draw_text(f, color.guiSha, x, y - _shaOffset, fla, s);
            al_draw_text(f, color.guiSha, x, y + _shaOffset, fla, s);
            al_draw_text(f, col, x, y, fla, s);
            al_draw_text(f, col, x, y, fla, s);
        }
        else {
            al_draw_text(f, color.guiSha, x+_shaOffset, y+_shaOffset, fla, s);
            al_draw_text(f, col, x, y, fla, s);
        }
    }

    // Screen pixels (in y direction) that the map should occupy, i.e.,
    // the part of the screen that is _not_ covered by the panel at the bottom.
    @property float mapYls() const
    out (result) {
        assert (result >= 0);
        assert (result <= screenYls);
    }
    do {
        immutable float unroundedMapYls
            = _screenYls - (_screenYls / panelYlgDivisor);
        // The pixels for the map above the panel should be a
        // multiple of the max zoom level, to make the zoom look nice.
        // It's fine to make the panel minimally larger/smaller to accomodate.
        enum int multipleForZoom = 4;
        return floor(unroundedMapYls / multipleForZoom) * multipleForZoom;
    }

    // 1 / panelYlgDivisor is the ratio of vertical space occupied by the
    // game/editor panels. Higher values mean less y-space for panels.
    float panelYlgDivisor() const
    {
        assert (_screenXls > 0, "necessary for division; bad init?");
        assert (_screenYls > 0, "necessary for division; bad init?");
        immutable float aspectRatio = _screenXls / _screenYls;
        if (aspectRatio >= 16f / 10f + 0.01f // Widescreen
            && _screenYls < 1000f // Small screen, hard to upscale skill icons
        ) {
            /*
             * Hack to make skill icons look nice on smaller widescreens.
             * The skill icons can't be upscaled automatically to 1.5x,
             * which would be really nice. Until I draw the skill icons at
             * at 1.5x, I'll enlarge the panel by this hack. On this larger
             * panel, the GUI will autoscale the skill CutbitElement to 2x.
             *
             * This hack is especially important when we set the default
             * resolution to 1280x720 in July 2021.
             *
             * Without the hack, the function should always return 6.
             */
            return 5.6f;
        }
        return 6;
    }
}
