module basics.demo;

import basics.alleg5;
import basics.globals;
import file.filename;
import game.lookup;
import graphic.cutbit;
import graphic.gralib;
import graphic.graphic;
import graphic.textout;
import graphic.torbit;
import gui;
import hardware.mouse;
import hardware.mousecur;
import hardware.keyboard;
import hardware.display;
import hardware.sound;
import level.tilelib;

/* right now, this class tests various other classes. There will be a lot
 * of random things created here.
 * the loop runs by itself until ESC is pressed, because it's an old class.
 *
 *  void main_loop()
 *
 *      create an object and call this method once, then kill the demo.
 */

class Demo {

private:

    enum demo_mode_max = 7; // demo mode must be smaller than this

    bool   exit;
    int    demo_mode; // 0 == what you normally get
                      // 1 -- 6 == for geoo's code
    Albit[] wuerste;
    Torbit osd;
    Graphic myhatch1;
    Graphic myhatch2;
    Element[] elems;

    Torbit land;
    Lookup lookup;



public:

this(in int arg_demo_mode = 0)
{
    exit = false;
    demo_mode = arg_demo_mode;
    assert (demo_mode >= 0 && demo_mode < demo_mode_max);

    import graphic.color;

    wuerste ~= al_load_bitmap("./images/matt/earth/07b.png");
    wuerste ~= al_load_bitmap("./images/matt/oriental/bonsaitree.png");
    assert (wuerste[0]);
    assert (wuerste[1]);
    al_convert_mask_to_alpha(wuerste[0], AlCol(1,0,1,1));
    al_convert_mask_to_alpha(wuerste[1], AlCol(1,0,1,1));
    foreach (i; 1 .. 4) {
        Albit wurst = albit_create(50 + 31 * (i % 2), 50 + 21 * (i/2));
        auto drata = DrawingTarget(wurst);
        al_clear_to_color(AlCol(1,0,0,1));
        wuerste ~= wurst;
    }

    osd = new Torbit(al_get_display_width (display),
                     al_get_display_height(display), true, true);

    const(Cutbit) hatch_cb = get_tile("geoo/construction/Hatch.H").cb;
    myhatch1 = new Graphic(hatch_cb, osd);
    myhatch2 = new Graphic(hatch_cb, osd);

    // test gui elements
    elems ~= new Frame (new Geom(40, 50, 60, 70, Geom.From.BOTTOM_RIGHT));
    elems ~= new Button(new Geom(40, 50, 60, 50, Geom.From.BOTTOM_RIGHT));
    elems ~= () {
        auto a = new TextButton(new Geom(0, 20, 100, 20, Geom.From.BOTTOM));
        import file.language;
        a.text = Lang.editor_button_SELECT_COPY.transl;
        return a;
    } ();
    foreach (e; elems) gui.add_elder(e);

    // This test class does lots of drawing during calc().
    // Since that is skipped when it's first created, make one osd-clear here.
    auto drata = DrawingTarget(osd.albit);
    al_clear_to_color(AlCol(0, 0, 0, 1));
}



~this()
{
    if (lookup) destroy(lookup);
    if (land)   destroy(land);

    destroy(myhatch2);
    destroy(myhatch1);

    destroy(osd);

    foreach (ref wurst; wuerste) {
        if (wurst) al_destroy_bitmap(wurst);
        wurst = null;
    }
    assert (wuerste[0] == null);
}



private double
wurstrotation(int tick)
{
    int phase = tick / 150;
    int mod = tick % 150;

    if (mod >= 100) {
        mod = 0;
        phase += 1;
    }
    return phase + mod / 100.0;
}


void
calc()
{
    int tick = al_get_timer_count(basics.alleg5.timer) % (2 << 30);

    auto drata = DrawingTarget(osd.albit);
    al_clear_to_color(AlCol(0, 0, 0, 1));

    perform_geoo_benchmarks();

    al_draw_triangle(20+tick, 20, 30, 80, 40, 20, AlCol(0.3, 0.5, 0.7, 1), 3);

    osd.draw_rectangle(100 + tick*2, 100 + tick*3, 130, 110, AlCol(0.2, 1, 0.3, 1));
    osd.draw_from(wuerste[1], 100 + 0, 100, false, wurstrotation(tick));
    osd.draw_from(wuerste[2], 200 + 0, 100, true, wurstrotation(tick/2));
    osd.draw_from(wuerste[3], 100 + 0, 200, true, wurstrotation(tick/3));
    osd.draw_from(wuerste[4], 200 + 0, 200, false, wurstrotation(tick/5));

    import std.math, std.conv;
    myhatch1.set_xy(300 + to!int(40*sin(tick/41.0)),
                    300 + to!int(30*sin(tick/25.0)));
    myhatch2.set_xy(450 + to!int(50*sin(tick/47.0)),
                    280 + to!int(42*sin(tick/27.0)));
    myhatch1.xf = to!int(2.5 + 2.49 * sin(tick/20.0));
    myhatch2.xf = to!int(2.5 + 6.3  * sin(tick/25.0));
    myhatch1.draw();
    myhatch2.draw();

    static string typetext = "Type some UTF-8 chars: ";
    typetext ~= get_utf8_input();
    if (get_backspace()) {
        typetext = basics.help.backspace(typetext);
    }
    if (key_once(ALLEGRO_KEY_A)) {
        play_loud(Sound.CLOCK);
    }

    import basics.user;
    import std.string;
    import lix.enums;

    drtx(typetext ~ (tick % 30 < 15 ? "_" : ""), 300, 100);
    drtx(format("Your builder hotkey scancode: %d", key_skill[Ac.BUILDER]), 20, 400);
    drtx("Builder key once: " ~ (key_once(key_skill[Ac.BUILDER])?"now":"--"), 20, 420);
    drtx("Builder key hold: " ~ (key_hold(key_skill[Ac.BUILDER])?"now":"--"), 20, 440);
    drtx("Builder key rlsd: " ~ (key_rlsd(key_skill[Ac.BUILDER])?"now":"--"), 20, 460);
    drtx("Press [A] to playback a sound. Does it play immediately (correct) or with 0.5 s delay (bug)?", 20, 480);
    drtx("Non-square rectangles jump when they", 300, 120);
    drtx("finish a half rotation, this is intended.", 300, 140);

    if (demo_mode == 0 && (tick % 120 >= 30 || tick % 10 < 5))
        drtx("--> PRESS [SHIFT] + [ESC] TO EXIT! <--", 5, 5);

    import basics.globals;
    import basics.globconf;
    import basics.versioning;
    import file.language;
    drtx(transl(Lang.net_chat_welcome_unstable)
        ~ " or enjoy hacking in D. " ~ get_version_string(), 20, 360);

    static bool showstring = false;
    import std.array;
    if (basics.globconf.user_name.empty) {
        drtx("Enter your username in data/config.txt for a greeting", 20, 380);
    }
    else {
        drtx("Hello " ~ user_name ~ ", loading the config file works.", 20, 380);
    }

    // random text in the text button
    if (tick % 50 == 0) {
        import std.random;
        auto but = cast (TextButton) elems[2];
        but.text = uniform(0, Lang.MAX).to!Lang.transl;

        switch (tick / 50 % 4) {
        case 0: but.align_left  = true;  break;
        case 1: but.check_frame = 1;     break;
        case 2: but.align_left  = false; break;
        case 3: but.check_frame = 0;     break;
        default: break;
        }
    }
    if (tick % 240 == 0) {
        play_loud(Sound.HATCH_OPEN);
    }

    import level.tilelib;
    import level.tile;
    const(Tile) mytile = get_tile("geoo/sandstone/arc_big");
    assert (mytile, "mytile not exist");
    assert (mytile.cb, "mytile.cb not exist");
    mytile.cb.draw(osd, 500 + to!int(50 * sin(tick / 30.0)), 10);
}



void
perform_geoo_benchmarks()
{
    import hardware.tharsis;
    import std.string;

    int sx = al_get_bitmap_width(wuerste[0]);
    int sy = al_get_bitmap_height(wuerste[0]);

    // one single call to al_draw_prim
    // this suddenly becomes slow after 20 seconds or so? Some memory leak?
    if (demo_mode == 1) {
        auto my_zone = Zone(profiler, "demo-prim-triangle-list");
        ALLEGRO_VERTEX[] vertices;
        foreach (y; 0..100) {
            foreach (x; 0..100) {
                // note that in theory this could be reduced to only one bigger
                // triangle capturing the rectangle to be drawn
                ALLEGRO_VERTEX[] w = [
                    {    2*x,     2*y,  0,  0,  0, al_map_rgba_f(1.0, 1.0, 1.0, 1.0)},
                    { 2*x+sx,     2*y,  0, sx,  0, al_map_rgba_f(1.0, 1.0, 1.0, 1.0)},
                    { 2*x+sx,  2*y+sy,  0, sx, sy, al_map_rgba_f(1.0, 1.0, 1.0, 1.0)},
                    {    2*x,     2*y,  0,  0,  0, al_map_rgba_f(1.0, 1.0, 1.0, 1.0)},
                    {    2*x,  2*y+sy,  0,  0, sy, al_map_rgba_f(1.0, 1.0, 1.0, 1.0)},
                    { 2*x+sx,  2*y+sy,  0, sx, sy, al_map_rgba_f(1.0, 1.0, 1.0, 1.0)}

                ];
                vertices ~= w;
            }
        }
        al_draw_prim(vertices.ptr, null, wuerste[0], 0, cast(int) vertices.length, ALLEGRO_PRIM_TYPE.ALLEGRO_PRIM_TRIANGLE_LIST);
    }

    // one single call to al_draw_prim, 4 times as many pieces
    if (demo_mode == 2) {
        auto my_zone = Zone(profiler, "demo-prim-triangle-list-more");
        ALLEGRO_VERTEX[] vertices;
        foreach (y; 0..100) {
            foreach (x; 0..400) {
                // note that in theory this could be reduced to only one bigger
                // triangle capturing the rectangle to be drawn
                ALLEGRO_VERTEX[] w = [
                    {    2*x,     2*y,  0,  0,  0, al_map_rgba_f(1.0, 1.0, 1.0, 1.0)},
                    { 2*x+sx,     2*y,  0, sx,  0, al_map_rgba_f(1.0, 1.0, 1.0, 1.0)},
                    { 2*x+sx,  2*y+sy,  0, sx, sy, al_map_rgba_f(1.0, 1.0, 1.0, 1.0)},
                    {    2*x,     2*y,  0,  0,  0, al_map_rgba_f(1.0, 1.0, 1.0, 1.0)},
                    {    2*x,  2*y+sy,  0,  0, sy, al_map_rgba_f(1.0, 1.0, 1.0, 1.0)},
                    { 2*x+sx,  2*y+sy,  0, sx, sy, al_map_rgba_f(1.0, 1.0, 1.0, 1.0)}

                ];
                vertices ~= w;
            }
        }
        al_draw_prim(vertices.ptr, null, wuerste[0], 0, cast(int) vertices.length, ALLEGRO_PRIM_TYPE.ALLEGRO_PRIM_TRIANGLE_LIST);
    }

    // one single call to al_draw_prim, large bitmap
    if (demo_mode == 3) {
        int sx2 = al_get_bitmap_width(wuerste[1]);
        int sy2 = al_get_bitmap_height(wuerste[1]);

        auto my_zone = Zone(profiler, "demo-prim-triangle-list-large");
        ALLEGRO_VERTEX[] vertices;
        foreach (y; 0..100) {
            foreach (x; 0..100) {
                // note that in theory this could be reduced to only one bigger
                // triangle capturing the rectangle to be drawn
                ALLEGRO_VERTEX[] w = [
                    {    2*x,     2*y,  0,  0,  0, al_map_rgba_f(1.0, 1.0, 1.0, 1.0)},
                    { 2*x+sx2,     2*y,  0, sx2,  0, al_map_rgba_f(1.0, 1.0, 1.0, 1.0)},
                    { 2*x+sx2,  2*y+sy2,  0, sx2, sy2, al_map_rgba_f(1.0, 1.0, 1.0, 1.0)},
                    {    2*x,     2*y,  0,  0,  0, al_map_rgba_f(1.0, 1.0, 1.0, 1.0)},
                    {    2*x,  2*y+sy2,  0,  0, sy2, al_map_rgba_f(1.0, 1.0, 1.0, 1.0)},
                    { 2*x+sx2,  2*y+sy2,  0, sx2, sy2, al_map_rgba_f(1.0, 1.0, 1.0, 1.0)}

                ];
                vertices ~= w;
            }
        }
        al_draw_prim(vertices.ptr, null, wuerste[1], 0, cast(int) vertices.length, ALLEGRO_PRIM_TYPE.ALLEGRO_PRIM_TRIANGLE_LIST);
    }

    // simple bitmap drawing
    if (demo_mode == 4) {
        auto my_zone = Zone(profiler, "demo-bitmap-using-holding");
        al_hold_bitmap_drawing(true);
            foreach (y; 0..100) {
                foreach (x; 0..100) {
                    al_draw_bitmap(wuerste[0], 2*x, 2*y, 0);
                    al_draw_bitmap(wuerste[0], 2*x, 2*y, 0);
                }
            }
        al_hold_bitmap_drawing(false);
    }

    // simple bitmap drawing, large bitmap
    if (demo_mode == 5) {
        auto my_zone = Zone(profiler, "demo-bitmap-using-holding-large");
        al_hold_bitmap_drawing(true);
            foreach (y; 0..100) {
                foreach (x; 0..100) {
                    al_draw_bitmap(wuerste[1], 2*x, 2*y, 0);
                    al_draw_bitmap(wuerste[1], 2*x, 2*y, 0);
                }
            }
        al_hold_bitmap_drawing(false);
    }

    // This is super slow, don't use.
    if (demo_mode == 6) {
        auto my_zone = Zone(profiler, "demo-prim-triangle-calls");
        foreach (y; 0..100) {
            foreach (x; 0..100) {
                ALLEGRO_VERTEX[] w = [
                    {    2*x,     2*y,  0,  0,  0, al_map_rgba_f(1.0, 1.0, 1.0, 1.0)},
                    { 2*x+sx,     2*y,  0, sx,  0, al_map_rgba_f(1.0, 1.0, 1.0, 1.0)},
                    { 2*x+sx,  2*y+sy,  0, sx, sy, al_map_rgba_f(1.0, 1.0, 1.0, 1.0)},
                    {    2*x,     2*y,  0,  0,  0, al_map_rgba_f(1.0, 1.0, 1.0, 1.0)},
                    {    2*x,  2*y+sy,  0,  0, sy, al_map_rgba_f(1.0, 1.0, 1.0, 1.0)},
                    { 2*x+sx,  2*y+sy,  0, sx, sy, al_map_rgba_f(1.0, 1.0, 1.0, 1.0)}
                ];
                al_draw_prim(w.ptr, null, wuerste[0], 0, 3, ALLEGRO_PRIM_TYPE.ALLEGRO_PRIM_TRIANGLE_LIST);
            }
        }
    }

    if (demo_mode != 0) {
        drtx(format("Mode: %d", demo_mode), 20, 20);
    }
    
}



void
draw()
{
    osd.copy_to_screen();
}

}
// end class
