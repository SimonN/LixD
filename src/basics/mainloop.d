module basics.mainloop;

import basics.alleg5;
import file.filename;
import graphic.cutbit;
import graphic.textout;
import graphic.torbit;

class MainLoop {

public:

    // create an object and call this method once, then exit the program
    void main_loop();

private:

    bool   exit;
    AlBit[] wuerste;
    Torbit osd;
    Cutbit mycut;

    void process_events();
    void calc();
    void draw();



public:

void main_loop()
{
    exit = false;

    wuerste ~= al_load_bitmap("./images/piece.png");
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

    Filename fn = new Filename("./images/constr-hatch.png");
    mycut = new Cutbit(fn, true);

    osd = new Torbit(basics.alleg5.map_xl, basics.alleg5.map_yl, true, true);

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

    ALLEGRO_EVENT event;
    while(al_get_next_event(basics.alleg5.queue, &event))
    {
        if (event.type == ALLEGRO_EVENT_DISPLAY_CLOSE) {
            exit = true;
        }
        else if (event.type == ALLEGRO_EVENT_KEY_DOWN
         && event.keyboard.keycode == ALLEGRO_KEY_ESCAPE) {
            exit = true;
        }
        else if (event.type == ALLEGRO_EVENT_MOUSE_BUTTON_DOWN) {
            exit = true;
        }
    }
    // end while (get next event)
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
    mycut.draw(osd, 300 + to!int(40*sin(tick/41.0)),
                    300 + to!int(30*sin(tick/25.0)),
                    to!int(2.5 + 2.49 * sin(tick/20.0))); // x_frame

    drtx(osd, "Hi with a TTF font from Allegro 5.", 300, 100);
    drtx(osd, "Non-square rectangles jump when they", 300, 120);
    drtx(osd, "finish a half rotation, this is intended.", 300, 140);
    import basics.globals;
    import basics.globconf;
    import basics.versioning;
    import file.language;
    drtx(osd, Lang["net_chat_unstable_1"] ~ Lang["nage"] ~ " " ~ get_version_string(), 20, 360);

    static bool showstring = false;
    import std.array;
    if (basics.globconf.user_name.empty) {
        drtx(osd, "Enter your username in data/config.txt for a greeting", 20, 380);
    }
    else {
        drtx(osd, "Hello " ~ user_name ~ ", loading the config file works.", 20, 380);
    }

}



void draw()
{
    osd.copy_to_screen();
    al_flip_display();
}

}
// end class
