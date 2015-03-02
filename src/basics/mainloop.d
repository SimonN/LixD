import alleg5;
import std.stdio;
import torbit;

class MainLoop {

public:

    // create an object and call this method once, then exit the program
    void main_loop();

private:

    bool   exit;
    AlBit  wurstbit;
    Torbit osd;

    void process_events();
    void calc();
    void draw();



public:

void main_loop()
{
    exit = false;

    wurstbit = al_load_bitmap("./images/piece.png");
    al_convert_mask_to_alpha(wurstbit, AlCol(1, 0, 1, 1));

    scope (exit) {
        if (wurstbit) al_destroy_bitmap(wurstbit);
        wurstbit = null;
    }

    osd = new Torbit(alleg5.map_xl, alleg5.map_yl, true, true);

    long last_tick;

    while (true) {
        last_tick = al_get_timer_count(alleg5.timer);
        process_events();
        if (exit) break;
        calc();
        draw();

        while (last_tick == al_get_timer_count(alleg5.timer)) {
            //al_rest(0.001);
        }
    }
}



private:

void process_events()
{

    ALLEGRO_EVENT event;
    while(al_get_next_event(alleg5.queue, &event))
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



void calc()
{
    int tick = al_get_timer_count(alleg5.timer) % (2 << 30);
    import std.string;
    al_set_window_title(alleg5.display, format("%d", tick).toStringz);
    writefln("%d" ~ (tick % 60 == 0 ? "------------" : ""), tick);

    mixin(temp_target!"osd.get_albit()");
    al_clear_to_color(AlCol(0, 0, 0, 1));
    al_draw_triangle(20 + tick, 20, 30, 30, 40, 20, AlCol(1, 1, 1, 1), 2);

    osd.draw_from(wurstbit, 100 + tick, 100, false, tick / 100.0);
    osd.draw_from(wurstbit, 200 + tick, 100, true);
    osd.draw_from(wurstbit, 100 + tick, 200);
}



void draw()
{
    osd.copy_to_screen();
    al_flip_display();
}

}
// end class
