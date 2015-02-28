import alleg5;
import std.stdio;

class MainLoop {

public:

    // create an object and call this method once, then exit the program
    void main_loop();

private:

    bool  exit;
    int   tick;
    AlBit wurstbit;

    void process_events();
    void calc();
    void draw();



public:

void main_loop()
{
    exit = false;
    tick = 0;

    wurstbit = albit_create(310, 380);
    scope (exit) {
        if (wurstbit) al_destroy_bitmap(wurstbit);
        wurstbit = null;
    }

    while (! exit) {
        process_events();
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
    al_set_target_bitmap(alleg5.pre_screen);
    al_clear_to_color(AlCol(tick/600.0, 0.5, 1-(tick/800.0), 1));
    al_draw_triangle(20, 20, 300, 30, 200, 200, AlCol(1, 1, 1, 1), 4);
    foreach (i; 0 .. 10) al_draw_bitmap(wurstbit, tick + 20, 100 + 10*i, 0);
}



void draw()
{
    // draw prescreen to screen
    al_set_target_backbuffer(alleg5.display);
    al_draw_bitmap(pre_screen, 0, 0, 0);
    al_flip_display();
    //al_wait_for_vsync();
}

}
// end class
