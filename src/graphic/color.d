module graphic.color;

import std.random;

public import basics.alleg5 : AlCol;

import basics.alleg5;
import basics.user;

public ColorPrivate color;

void initialize()   { if (color) destroy(color); color = new ColorPrivate(); }
void deinitialize() { destroy(color); color = null; }

void compute_new_user_colors() { initialize(); }

private class ColorPrivate {

    @property AlCol random()
    {
        alias rnd = uniform01!float;
        float r = rnd(), g = rnd(), b = rnd();
        return AlCol(r, g, b, 1);
    }

    AlCol makecol(int r, int g, int b)
    {
        return AlCol(r / 255f, g / 255f, b / 255f, 1);
    }

    AlCol
        bad,
        transp,
        pink,

        cb_bad_frame,
        cb_bad_bitmap,

        white,
        red,
        black,

        lixfile_eye, // for detection of where exploder fuses are positioned

        gui_f_sha, // how it looks in an image file, these get
        gui_f_d,   // recolored to gui_d, gui_on_d, ..., accordingly.
        gui_f_m,
        gui_f_l,

        screen_border,
        editor_dark,
        gui_sha,
        gui_d,
        gui_m,
        gui_l,
        gui_down_d,
        gui_down_m,
        gui_down_l,
        gui_on_d,
        gui_on_m,
        gui_on_l,

        gui_text,
        gui_text_on,

        gui_pic_on_d,
        gui_pic_on_m,
        gui_pic_on_l,
        gui_pic_d,
        gui_pic_m,
        gui_pic_l;

private:

    AlCol make_sepia(in float li);

    this() {
        //                    red   green blue  alpha
        bad           = AlCol(0.00, 0.00, 0.00, 0.5);
        transp        = AlCol(0.00, 0.00, 0.00, 0  );
        pink          = AlCol(1,    0,    1,    1  );

        cb_bad_frame  = AlCol(0.8,  0.8,  0.8,  1  );
        cb_bad_bitmap = AlCol(1,    0.5,  0.5,  1  );

        lixfile_eye   = makecol(0x50, 0x50, 0x50);

        white         = AlCol(1,    1,    1,    1  );
        red           = AlCol(1,    0,    0,    1  );
        black         = AlCol(0,    0,    0,    1  );

        // how it looks in an image file
        gui_f_sha = makecol(0x40, 0x40, 0x40);
        gui_f_d   = makecol(0x80, 0x80, 0x80);
        gui_f_m   = makecol(0xC0, 0xC0, 0xC0);
        gui_f_l   = makecol(0xFF, 0xFF, 0xFF);

        screen_border = make_sepia(2f / 16f);
        editor_dark   = makecol   (0x20, 0x20, 0x20); // erasor pieces
        gui_sha       = make_sepia(3f / 16f);
        gui_d         = make_sepia(7.75f / 16f / 1.2f);
        gui_m         = make_sepia(7.75f / 16f);
        gui_l         = make_sepia(7.75f / 16f * 1.2f);
        gui_down_d    = make_sepia(8.75f / 16f / 1.1f);
        gui_down_m    = make_sepia(8.75f / 16f);
        gui_down_l    = make_sepia(8.75f / 16f * 1.1f);
        gui_on_d      = make_sepia(11f   / 16f / 1.1f);
        gui_on_m      = make_sepia(11f   / 16f);
        gui_on_l      = make_sepia(11f   / 16f * 1.1f);

        gui_text      = make_sepia(14f   / 16f); // lighter than an image
        gui_text_on   = make_sepia(1.0);         // pure white

        gui_pic_d     = make_sepia(11f   / 16f / 1.2f);
        gui_pic_m     = make_sepia(11f   / 16f);
        gui_pic_l     = make_sepia(11f   / 16f * 1.2f);
        gui_pic_on_d  = make_sepia(14f   / 16f / 1.2f);
        gui_pic_on_m  = make_sepia(14f   / 16f);
        gui_pic_on_l  = make_sepia(1.0);
    }

    // light: max is 1.0, min is 0.0
    AlCol make_sepia(in float light)
    {
        if      (light <= 0.0) return AlCol(0, 0, 0, 1);
        else if (light >= 1.0) return AlCol(1, 1, 1, 1);

        // the user file suggests a base color via integers in 0 .. 255+1
        alias gui_color_red   r;
        alias gui_color_green g;
        alias gui_color_blue  b;
        r = (r > 0xFF ? 0xFF : r < 0 ? 0 : r);
        g = (g > 0xFF ? 0xFF : g < 0 ? 0 : g);
        b = (b > 0xFF ? 0xFF : b < 0 ? 0 : b);
        if      (light == 0.5) return AlCol(r / 255f, g / 255f, b / 255f, 1);
        else if (light <  0.5) return AlCol(r * 2 * light / 255f,
                                            g * 2 * light / 255f,
                                            b * 2 * light / 255f, 1);
        else return AlCol((r + (255 - r) * 2 * (light - 0.5)) / 255f,
                          (g + (255 - g) * 2 * (light - 0.5)) / 255f,
                          (b + (255 - b) * 2 * (light - 0.5)) / 255f, 1);
    }

}
