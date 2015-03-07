module hardware.mouse;

import basics.alleg5;
import basics.globals;
import basics.user;
import hardware.display;

void initialize();
void deinitialize();

void calc();

int  get_mickey_x() { return mickey_x;         }
int  get_mickey_y() { return mickey_y;         }
int  get_mx()       { return mouse_own_x;      }
int  get_my()       { return mouse_own_y;      }

bool get_ml()       { return mouse_click  [0]; }
bool get_mr()       { return mouse_click  [1]; }
bool get_mm()       { return mouse_click  [2]; }
bool get_mld()      { return mouse_double [0]; }
bool get_mrd()      { return mouse_double [1]; }
bool get_mmd()      { return mouse_double [2]; }

int  get_mlh()      { return mouse_hold   [0]; }
int  get_mrh()      { return mouse_hold   [1]; }
int  get_mmh()      { return mouse_hold   [2]; }
int  get_mlr()      { return mouse_release[0]; }
int  get_mrr()      { return mouse_release[1]; }
int  get_mmr()      { return mouse_release[2]; }

void set_trap_mouse(bool b) { trap_mouse = b; }
void center_mouse();
void freeze_mouse_x();
void freeze_mouse_y();



private:

    ALLEGRO_EVENT_QUEUE* queue;

    bool trap_mouse = true;
    bool center_mouse_at_next_update = true;

    int  mouse_own_x; // where the cursor will appear, != al_mouse
    int  mouse_own_y;
    int  mickey_x; // Difference of mouse_own_x since last main_loop
    int  mickey_y;
    int  mickey_leftover_x; // leftover movement from the previous mickeys,
    int  mickey_leftover_y; // yet unspent to mouse_own_xy, for smoothening

    // The mouse has 3 buttons: #0 is left, #1 is right, #2 is middle.
    bool mouse_click  [3]; // there just was a single click
    bool mouse_double [3]; // there just was a double click
    int  mouse_hold   [3]; // mouse button has been held for... (0 if not)
    int  mouse_release[3]; // just released button after being held for ...
    int  mouse_since  [3]; // how long ago was the last click, for doubleclick

    immutable int doubleclick_speed = basics.globals.ticks_per_sec / 3;
    immutable int doubleclick_for60 = 20;

    void set_mouse_accel_on_windows(bool);



public:

void initialize()
{
    // A5 and the A5 mouse must have been initialized already.
    assert (! queue);
    queue = al_create_event_queue();
    assert (queue);
    al_register_event_source(queue, al_get_mouse_event_source());
    center_mouse();
}



void deinitialize()
{
    assert (queue);
    if (queue) al_destroy_event_queue(queue);
    queue = null;
}



void calc()
{
    immutable int xl = al_get_display_width (display);
    immutable int yl = al_get_display_height(display);

    // Setting to zero all things that are good for only one main_loop,
    // incrementing the times on others.
    mickey_x = mickey_leftover_x;
    mickey_y = mickey_leftover_y;

    foreach (i; 0 .. 3) {
        mouse_click  [i] = false;
        mouse_double [i] = false;
        mouse_release[i] = 0;
        mouse_since  [i] += 1;
        if (mouse_hold[i]) ++mouse_hold[i];
    }

    // Local variables: current hardware mouse position, these are only used
    // to reset the mouse later if they differ too much from the following
    int mouse_cur_x = xl / 2;
    int mouse_cur_y = yl / 2;

    // I will adhere to my convention from C++/A4 Lix to multiply all incoming
    // mouse movements by the mouse speed, and then later divide by the
    // constant 20.
    ALLEGRO_EVENT event;
    while (al_get_next_event(queue, &event)) {
        // discard mouse events that do not pertain to our display
        if (event.mouse.display != display) continue;

        immutable int i = event.mouse.button - 1;

        switch (event.type) {
        case ALLEGRO_EVENT_MOUSE_AXES:
            // DTODO: Only use mouse_speed in fullscreen, not in window mode
            mickey_x += event.mouse.dx * basics.user.mouse_speed;
            mickey_y += event.mouse.dy * basics.user.mouse_speed;
            mouse_cur_x = event.mouse.x;
            mouse_cur_y = event.mouse.y;
            break;

        case ALLEGRO_EVENT_MOUSE_BUTTON_DOWN:
            if (i < 0 || i >= 3) break;
            mouse_click [i] = true;
            mouse_double[i] = (mouse_since[i] < doubleclick_speed);
            mouse_since [i] = 0;
            mouse_hold  [i] = 1;
            break;

        case ALLEGRO_EVENT_MOUSE_BUTTON_UP:
            if (i < 0 || i >= 3) break;
            mouse_release[i] = mouse_hold[i];
            mouse_hold   [i] = 0;
            break;

        case ALLEGRO_EVENT_MOUSE_WARPED:
            // This occurs after centralizing the mouse manually. Ignore.
            break;

        default:
            break;
        }
    }
    mouse_own_x      += mickey_x / 20;
    mouse_own_y      += mickey_y / 20;
    mickey_leftover_x = mickey_x % 20; // here we want signed %
    mickey_leftover_y = mickey_y % 20;

    if (mouse_own_x < 0)   mouse_own_x = 0;
    if (mouse_own_y < 0)   mouse_own_y = 0;
    if (mouse_own_x >= xl) mouse_own_x = xl - 1;
    if (mouse_own_y >= yl) mouse_own_y = yl - 1;

    if (trap_mouse) {
        al_hide_mouse_cursor(display);
        if (center_mouse_at_next_update) {
            center_mouse_at_next_update = false;
            immutable int x = al_get_display_width (display) / 2;
            immutable int y = al_get_display_height(display) / 2;
            al_set_mouse_xy(display, x, y);
            mouse_own_x = x;
            mouse_own_y = y;
        }
        if (mouse_cur_x < xl/4 || mouse_cur_x > xl*3/4
         || mouse_cur_y < yl/4 || mouse_cur_y > yl*3/4) {
             // do not call center_mouse, that would move mouse_own_xy
             al_set_mouse_xy(display, xl/2, yl/2);
        }
    }
    else {
        al_show_mouse_cursor(display);
    }
}
// end void update()



void center_mouse()
{
    center_mouse_at_next_update = true;
}



void freeze_mouse_x()
{
    immutable int xl = al_get_display_height(display);
    mouse_own_x -= mickey_x;
    if (mouse_own_x < 0)   mouse_own_x = 0;
    if (mouse_own_x >= xl) mouse_own_x = xl - 1;
    mickey_x = 0;
}



void freeze_mouse_y()
{
    immutable int yl = al_get_display_height(display);
    mouse_own_y -= mickey_y;
    if (mouse_own_y < 0)   mouse_own_y = 0;
    if (mouse_own_y >= yl) mouse_own_y = yl - 1;
    mickey_y = 0;
}
