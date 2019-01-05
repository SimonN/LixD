module graphic.color;

import std.random;

public import basics.alleg5 : Alcol;

import basics.alleg5;
import file.option;

public ColorPrivate color;

// bar graph 3D colors for a Lix style, or GUI button outlines
public struct Alcol3D {
    Alcol l, m, d;
    static assert (is (typeof(l.r) == float));
    bool isValid() const { return l.r == l.r; /* i.e., it's not NaN */ }
}

void initialize()
{
    computeColors(file.option.guiColorRed,
                  file.option.guiColorGreen,
                  file.option.guiColorBlue);
}

void deinitialize() { destroy(color); color = null; }

void computeColors(in int r, in int g, in int b)
{
    if (color)
        destroy(color);
    color = new ColorPrivate(r, g, b);
}

private class ColorPrivate {

    @property Alcol random()
    {
        alias rnd = uniform01!float;
        float[] arr = [rnd(), 0.7 + 0.3 * rnd(), 0.3 * rnd()];
        arr.randomShuffle();
        return al_map_rgb_f(arr[0], arr[1], arr[2]);
    }

    // This can't be an alias to al_map_rgb because al_map_rgb expects ubytes.
    Alcol makecol(in int r, in int g, in int b)
    {
        return al_map_rgb_f(r / 255f, g / 255f, b / 255f);
    }

    Alcol
        bad,
        transp,
        pink,
        cbBadFrame,
        cbBadBitmap,
        lixFileEye, // for detection of where exploder fuses are positioned

        white,
        black,
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
        guiD,
        guiM,
        guiL,
        guiDownD,
        guiDownM,
        guiDownL,
        guiOnD,
        guiOnM,
        guiOnL,

        guiText,
        guiTextOn,

        guiPicOnD,
        guiPicOnM,
        guiPicOnL,
        guiPicD,
        guiPicM,
        guiPicL;

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
        black = al_map_rgb_f(0, 0, 0);
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

        guiSha    = make_sepia(3f / 16f);
        guiD      = make_sepia(7.75f / 16f / 1.2f);
        guiM      = make_sepia(7.75f / 16f);
        guiL      = make_sepia(7.75f / 16f * 1.2f);
        guiDownD  = make_sepia(8.75f / 16f / 1.1f);
        guiDownM  = make_sepia(8.75f / 16f);
        guiDownL  = make_sepia(8.75f / 16f * 1.1f);
        guiOnD    = make_sepia(11f   / 16f / 1.1f);
        guiOnM    = make_sepia(11f   / 16f);
        guiOnL    = make_sepia(11f   / 16f * 1.1f);

        guiText   = make_sepia(14f   / 16f); // lighter than an image
        guiTextOn = make_sepia(1.0);         // pure white

        guiPicD   = make_sepia(11f   / 16f / 1.2f);
        guiPicM   = make_sepia(11f   / 16f);
        guiPicL   = make_sepia(11f   / 16f * 1.2f);
        guiPicOnD = make_sepia(14f   / 16f / 1.2f);
        guiPicOnM = make_sepia(14f   / 16f);
        guiPicOnL = make_sepia(1.0);
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
