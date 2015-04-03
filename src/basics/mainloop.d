module basics.mainloop;

import basics.alleg5;
import basics.globals;
import file.filename;
import graphic.cutbit;
import graphic.gralib;
import graphic.graphic;
import graphic.textout;
import graphic.torbit;
import hardware.mouse;
import hardware.keyboard;
import hardware.display;
import hardware.sound;

// right now, this class tests various other classes. There will be a lot
// of random things created here.

class MainLoop {

public:

    this();

    // create an object and call this method once, then exit the program
    void main_loop();

private:

    bool   exit;
    AlBit[] wuerste;
    Torbit osd;
    const(Cutbit) mouse;
    Graphic myhatch1;
    Graphic myhatch2;

    void process_events();
    void calc();
    void draw();



public:



this()
{
    mouse = graphic.gralib.get(file_bitmap_mouse);
    assert (mouse.is_valid());
}



void main_loop()
{
    exit = false;

    import graphic.color;

    wuerste ~= al_load_bitmap("./images/proxima/tile/blue1a.png");
    assert (wuerste[0]);
    al_convert_mask_to_alpha(wuerste[0], AlCol(1,0,1,1));
    foreach (i; 1 .. 4) {
        AlBit wurst = albit_create(50 + 31 * (i % 2), 50 + 21 * (i/2));
        mixin(temp_target!"wurst");
        al_clear_to_color(AlCol(1,0,0,1));
        wuerste ~= wurst;
    }
    scope (exit) {
        foreach (ref wurst; wuerste) {
            if (wurst) al_destroy_bitmap(wurst);
            wurst = null;
        }
        assert (wuerste[0] == null);
    }

    osd = new Torbit(al_get_display_width (display),
                     al_get_display_height(display), true, true);
    scope (exit) destroy(osd);

    Cutbit hatch_cb = new Cutbit(new Filename("./images/geoo/construction/Hatch.H.png"));
    myhatch1 = new Graphic(hatch_cb, osd);
    myhatch2 = new Graphic(hatch_cb, osd);
    scope (exit) {
        destroy(myhatch2);
        destroy(myhatch1);
        destroy(hatch_cb);
    }

    // test level input/output
    import level.level;
    display_startup_message("loading test level");
    Level lv = new Level(new Filename("./levels/atest.txt"));
    display_startup_message("saving test level");
    lv.save_to_file(new Filename("./levels/aout.txt"));

    import game.lookup;
    display_startup_message("making test land and lookup map");

    Torbit land   = new Torbit(lv.size_x, lv.size_y, lv.torus_x, lv.torus_y);
    scope (exit) destroy(land);

    Lookup lookup = new Lookup(lv.size_x, lv.size_y, lv.torus_x, lv.torus_y);
    scope (exit) destroy(lookup);

    display_startup_message("drawing to test land and lookup map");
    lv.draw_terrain_to(land, lookup);
    display_startup_message("saving test land");
    land.save_to_file(new Filename("z-landtest.png"));
    display_startup_message("saving test lookup map");
    lookup.save_to_file(new Filename("y-lookuptest.png"));



    display_startup_message("entering main loop");

    long last_tick;

    while (true) {
        last_tick = al_get_timer_count(basics.alleg5.timer);
        process_events();
        if (exit) break;
        calc();
        draw();

        while (last_tick == al_get_timer_count(basics.alleg5.timer)) {
            al_rest(0.001);
        }
    }
}



private:

void process_events()
{
    hardware.display .calc();
    hardware.keyboard.calc();
    hardware.mouse   .calc();

    if (get_mrh()) freeze_mouse_y();

    exit = hardware.display.get_display_close_was_clicked()
     ||    key_once(ALLEGRO_KEY_ESCAPE);
}


double wurstrotation(int tick)
{
    int phase = tick / 150;
    int mod = tick % 150;

    if (mod >= 100) {
        mod = 0;
        phase += 1;
    }
    return phase + mod / 100.0;
}


void calc()
{
    int tick = al_get_timer_count(basics.alleg5.timer) % (2 << 30);

    mixin(temp_target!"osd.get_albit()");
    al_clear_to_color(AlCol(0, 0, 0, 1));
    al_draw_triangle(20 + tick, 20, 30, 80, 40, 20, AlCol(1, 1, 1, 1), 2);

    osd.draw_rectangle(100 + tick*2, 100 + tick*3, 130, 110, AlCol(0.2, 1, 0.3, 1));
    osd.draw_from(wuerste[0], 100 + 0, 100, false, wurstrotation(tick));
    osd.draw_from(wuerste[1], 200 + 0, 100, true, wurstrotation(tick/2));
    osd.draw_from(wuerste[2], 100 + 0, 200, true, wurstrotation(tick/3));
    osd.draw_from(wuerste[3], 200 + 0, 200, false, wurstrotation(tick/5));

    import std.math, std.conv;
    myhatch1.set_xy(300 + to!int(40*sin(tick/41.0)),
                    300 + to!int(30*sin(tick/25.0)));
    myhatch2.set_xy(450 + to!int(50*sin(tick/47.0)),
                    280 + to!int(42*sin(tick/27.0)));
    myhatch1.set_x_frame(to!int(2.5 + 2.49 * sin(tick/20.0)));
    myhatch2.set_x_frame(to!int(2.5 + 6.3  * sin(tick/25.0)));
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

    drtx(osd, typetext ~ (tick % 30 < 15 ? "_" : ""), 300, 100);
    drtx(osd, format("Your builder hotkey scancode: %d", key_skill[Ac.BUILDER]), 20, 400);
    drtx(osd, "Builder key once: " ~ (key_once(key_skill[Ac.BUILDER])?"now":"--"), 20, 420);
    drtx(osd, "Builder key hold: " ~ (key_hold(key_skill[Ac.BUILDER])?"now":"--"), 20, 440);
    drtx(osd, "Builder key rlsd: " ~ (key_rlsd(key_skill[Ac.BUILDER])?"now":"--"), 20, 460);
    drtx(osd, "Press [A] to playback a sound. Does it play immediately (correct) or with 0.5 s delay (bug)?", 20, 480);
    drtx(osd, "Non-square rectangles jump when they", 300, 120);
    drtx(osd, "finish a half rotation, this is intended.", 300, 140);

    import basics.globals;
    import basics.globconf;
    import basics.versioning;
    import file.language;
    drtx(osd, Lang["net_chat_unstable_1"] ~ " " ~ get_version_string(), 20, 360);

    static bool showstring = false;
    import std.array;
    if (basics.globconf.user_name.empty) {
        drtx(osd, "Enter your username in data/config.txt for a greeting", 20, 380);
    }
    else {
        drtx(osd, "Hello " ~ user_name ~ ", loading the config file works.", 20, 380);
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

    mouse.draw(osd, get_mx() - mouse.get_xl()/2 + 1,
                    get_my() - mouse.get_yl()/2 + 1);

}



void draw()
{
    osd.copy_to_screen();
    al_flip_display();

    draw_scheduled_sounds();
}

}
// end class
