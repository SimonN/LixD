import alleg5;
import std.stdio;
import torbit;

class MainLoop {

public:

    // create an object and call this method once, then exit the program
    void main_loop();

private:

    bool   exit;
    int    tick;
    AlBit  wurstbit;
    Torbit osd;

    void process_events();
    void calc();
    void draw();



public:

void main_loop()
{
    exit = false;
    tick = 0;

    wurstbit = albit_create(50, 35);
    al_set_target_bitmap(wurstbit);
    al_clear_to_color(AlCol(0, 0, 0, 1));
    scope (exit) {
        if (wurstbit) al_destroy_bitmap(wurstbit);
        wurstbit = null;
    }

    osd = new Torbit(alleg5.map_xl, alleg5.map_yl, true, true);

    while (true) {
        process_events();
        if (exit) break;
        calc();
        draw(); // we're not doing too well with frameskipping right now

        ++tick;
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
    al_set_target_bitmap(wurstbit);
    al_clear_to_color(AlCol(tick % 400 / 400.0, tick % 95 / 95.0, 0, 1));

    al_set_target_backbuffer(alleg5.display);
    al_clear_to_color(AlCol(tick/600.0, 0.3, 1-(tick/800.0), 1));
    al_draw_triangle(20, 20, 300, 30, 200, 200, AlCol(1, 1, 1, 1), 4);

    import std.conv;
    import std.math;
    foreach (i; 0 .. 1) osd.draw_from(wurstbit, tick,
        to!int(100 + tick / 2.1 + sin(tick / 300.0) * 40.0));
}



void draw()
{
    osd.copy_to_screen();
    al_flip_display();
    //al_wait_for_vsync();
}

}
// end class
