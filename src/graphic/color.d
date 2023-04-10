module graphic.color;

public import basics.alleg5 :
    Alcol,
    al_map_rgb, al_unmap_rgb, al_map_rgb_f, al_unmap_rgb_f,
    al_map_rgba, al_unmap_rgba, al_map_rgba_f, al_unmap_rgba_f;

import basics.alleg5;
import opt = file.option.allopts;

public ColorPrivate color;

// bar graph 3D colors for a Lix style, or GUI button outlines
public struct Alcol3D {
    Alcol l, m, d;
    Alcol3D retro() const pure nothrow @safe @nogc { return Alcol3D(d, m, l); }
    bool isValid() const pure nothrow @safe @nogc
    {
        static assert (is (typeof(l.r) == const float));
        return l.r == l.r; // I.e., it's not NaN
    }
}

void initialize()
{
    computeColors(opt.guiColorRed.value,
                  opt.guiColorGreen.value,
                  opt.guiColorBlue.value);
}

void deinitialize() { destroy(color); color = null; }

void computeColors(in int r, in int g, in int b)
{
    if (color)
        destroy(color);
    color = new ColorPrivate(r, g, b);
}

private class ColorPrivate {
    // This can't be an alias to al_map_rgb because al_map_rgb expects ubytes.
    Alcol makecol(in int r, in int g, in int b)
    {
        return al_map_rgb_f(r / 255f, g / 255f, b / 255f);
    }

    // Handy to have this available without color initialization, for Level
    enum Alcol black = Alcol(0f, 0f, 0f, 1f);

    Alcol
        bad,
        transp,
        pink,
        cbBadFrame,
        cbBadBitmap,
        lixFileEye, // for detection of where exploder fuses are positioned

        white,
        red,

        guiFileSha, // how it looks in an image file, these get
        guiFileD,   // recolored to guiD, guiOnD, ..., accordingly.
        guiFileM,
        guiFileL,

        screenBorder,
        triggerArea,
        torusSeamD,
        torusSeamL,

        guiSha,
        guiText,
        guiTextDark,
        guiTextOn,
        guiTextHotkeyInCorner;

    Alcol3D
        gui,
        guiDown,
        guiOn,
        guiPic,
        guiPicOn;

private:
    int _guiColorRed, _guiColorGreen, _guiColorBlue;

    this(in int _r, in int _g, in int _b)
    {
        _guiColorRed   = _r;
        _guiColorGreen = _g;
        _guiColorBlue  = _b;

        bad = al_map_rgba_f(0, 0, 0, 0.5f);
        transp = al_map_rgba_f(0, 0, 0, 0);
        pink = al_map_rgb_f(1, 0, 1);
        cbBadFrame = al_map_rgb_f(0.8f, 0.8f, 0.8f);
        cbBadBitmap = al_map_rgb_f(1, 0.5f, 0.5f);
        lixFileEye = makecol(0x50, 0x50, 0x50);

        white = al_map_rgb_f(1, 1, 1);
        red = al_map_rgb_f(1, 0, 0);

        // how it looks in an image file
        guiFileSha = makecol(0x40, 0x40, 0x40);
        guiFileD   = makecol(0x80, 0x80, 0x80);
        guiFileM   = makecol(0xC0, 0xC0, 0xC0);
        guiFileL   = makecol(0xFF, 0xFF, 0xFF);

        screenBorder = make_sepia(2f / 16f);
        triggerArea  = makecol(0x60, 0xFF, 0xFF);
        torusSeamD   = make_sepia(0.25f);
        torusSeamL   = make_sepia(0.4f);

        gui = Alcol3D(
            make_sepia(7.75f / 16f * 1.2f),
            make_sepia(7.75f / 16f),
            make_sepia(7.75f / 16f / 1.2f));
        guiDown = Alcol3D(
            make_sepia(8.75f / 16f * 1.1f),
            make_sepia(8.75f / 16f),
            make_sepia(8.75f / 16f / 1.1f));
        guiOn = Alcol3D(
            make_sepia(11f / 16f * 1.1f),
            make_sepia(11f / 16f),
            make_sepia(11f / 16f / 1.1f));
        guiPic = Alcol3D(
            make_sepia(11f / 16f * 1.2f),
            make_sepia(11f / 16f),
            make_sepia(11f / 16f / 1.2f));
        guiPicOn = Alcol3D(
            make_sepia(1.0),
            make_sepia(14f / 16f),
            make_sepia(14f / 16f / 1.2f));

        guiSha = make_sepia(3f / 16f);
        guiText = make_sepia(14f / 16f); // lighter than an image
        guiTextOn = make_sepia(1.0); // pure white
        guiTextDark = guiOn.m;
        guiTextHotkeyInCorner = make_sepia(13f / 16f);
    }

    // light: max is 1.0, min is 0.0
    Alcol make_sepia(in float light)
    {
        if (light <= 0.0) {
            return al_map_rgb_f(0, 0, 0);
        }
        else if (light >= 1.0) {
            return al_map_rgb_f(1, 1, 1);
        }
        // the user file suggests a base color via integers in 0 .. 255+1
        alias r = _guiColorRed;
        alias g = _guiColorGreen;
        alias b = _guiColorBlue;
        r = (r > 0xFF ? 0xFF : r < 0 ? 0 : r);
        g = (g > 0xFF ? 0xFF : g < 0 ? 0 : g);
        b = (b > 0xFF ? 0xFF : b < 0 ? 0 : b);
        if (light == 0.5) {
            return al_map_rgb_f(r / 255f, g / 255f, b / 255f);
        }
        else if (light < 0.5) {
            return al_map_rgb_f(
                r * 2 * light / 255f,
                g * 2 * light / 255f,
                b * 2 * light / 255f);
        }
        else {
            return al_map_rgb_f(
                (r + (255 - r) * 2 * (light - 0.5)) / 255f,
                (g + (255 - g) * 2 * (light - 0.5)) / 255f,
                (b + (255 - b) * 2 * (light - 0.5)) / 255f);
        }
    }
}
