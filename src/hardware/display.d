module hardware.display;


import std.array;
import std.string;

import basics.help; // positive mod
import basics.alleg5;
import basics.globals; // main_name_of_game
import basics.globconf;
import graphic.color; // inside display_startup_message()
import graphic.textout; // inside display_startup_message()
import file.log;
import gui;
import hardware.mouse; // center mouse after changing resolution

/* A module for setting a screen resolution.
 * Right now, if you switch the screen resolution after having created all
 * the bitmaps, they will be put into RAM, and subsequent drawing will be
 * extremely slow. Avoid switching the resolution at all costs, or implement
 * something to improve performance after the switch.
 */

ALLEGRO_DISPLAY* display;

/*  void set_screen_mode(bool want_full, int want_x = 0, int want_y = 0);
 *
 *  void deinitialize();
 *
 *  void calc()
 *
 *      call once per main_loop to trap/untrap mouse
 *
 *  @property int display_xl()
 *  @property int display_yl()
 *
 *  @property int display_fps()
 *
 *  void display_startup_message(string)
 *
 *      before main_loop draws
 */

bool
get_display_close_was_clicked() {
    return display_close_was_clicked;
}



private bool[basics.globals.ticks_per_sec] _fps_arr;
private int _fps_previous_arr_entry;

void
flip_display() {
    assert(display, "display hasn't been created");
    al_flip_display();

    // compute FPS
    immutable int cur_entry = al_get_timer_count(timer) % _fps_arr.len;
    _fps_arr[cur_entry] = true;
    for (int null_entry = positive_mod(cur_entry - 1, _fps_arr.len);
        null_entry != _fps_previous_arr_entry;
        null_entry = positive_mod(null_entry - 1, _fps_arr.len)
    ) {
        _fps_arr[null_entry] = false;
    }
    _fps_previous_arr_entry = cur_entry;
}



@property int
display_fps()
{
    int sum = 0;
    foreach (entry; _fps_arr)
        sum += entry;
    return sum;
}



@property int
display_xl()
{
    assert(display, "display hasn't been created");
    return al_get_display_width(display);
}



@property int
display_yl()
{
    assert(display, "display hasn't been created");
    return al_get_display_height(display);
}



// Globally writable variable, set this to true to force a redraw of all GUI
// components next time, this is probably a C++/A4 Lix legacy variable
public bool clear_screen_at_next_blit;



private :

    ALLEGRO_EVENT_QUEUE* queue;
    bool display_close_was_clicked;



public:

// This is like initialize() of other modules.
// Will use global variables if res == (0, 0).
// If res == (0, 0) and the global variables are also (0, 0),
// then query the underlying desktop environment for fullscreen resolution,
// or, if window mode is desired, fall back to 640 x 480.
void set_screen_mode(bool want_full, int want_x = 0, int want_y = 0)
{
    struct TryMode {
        bool full;
        int x, y;
        this(bool _f, int _x, int _y) {
            full = _f; x = _x; y = _y;
            // TryMode shall not use 0, it shall only hold real possibilities.
            assert (x > 0);
            assert (y > 0);
        }
    }

    // try_modes lists interesting screen modes in the order we wish to try
    // them, using the first one that works. The earlier a mode appears in
    // try_modes, the earlier it is tried.
    TryMode[] try_modes;

    // top priority goes to the mode using set_screen_mode()'s arguments
    if (want_x > 0 && want_y > 0) {
        try_modes ~= TryMode(want_full, want_x, want_y);
    }

    // add two more modes for fullscreen, and two more modes for windowed,
    // but choose the order of these additions based on want_full
    void add_fullscreen_try_modes() {
        if (screen_resolution_x > 0 && screen_resolution_y > 0) {
            try_modes ~= TryMode(true, screen_resolution_x,
                                       screen_resolution_y);
        }
        try_modes  ~= TryMode(true, 640, 480);
    }
    void add_windowed_try_modes() {
        if (screen_windowed_x > 0 && screen_windowed_y > 0) {
            try_modes ~= TryMode(false, screen_windowed_x, screen_windowed_y);
        }
        try_modes  ~= TryMode(false, 640, 480);
    }

    if (want_full) {
        add_fullscreen_try_modes();
        add_windowed_try_modes();
    }
    else {
        add_windowed_try_modes();
        add_fullscreen_try_modes();
    }

    immutable fullscreen_flag = ALLEGRO_FULLSCREEN_WINDOW;

    // now try the modes in the desired order
    foreach (ref mode; try_modes) {
        int flags = al_get_new_display_flags()
         & ~ ALLEGRO_WINDOWED
         & ~ ALLEGRO_FULLSCREEN
         & ~ ALLEGRO_FULLSCREEN_WINDOW;
        if (mode.full) flags = flags | fullscreen_flag;
        else           flags = flags | ALLEGRO_WINDOWED;
        al_set_new_display_flags(flags);

        deinitialize();
        display = al_create_display(mode.x, mode.y);

        // if successfully created, don't try further modes
        if (display) break;
    }

    // cleaning up after the change, (re)instantiating the event queue
    assert (display);
    al_set_window_title(display, main_name_of_game.toStringz);

    queue = al_create_event_queue();
    al_register_event_source(queue, al_get_display_event_source(display));

    clear_screen_at_next_blit = true;
    hardware.mouse.center_mouse();

    immutable int al_x = al_get_display_width (display);
    immutable int al_y = al_get_display_height(display);
    immutable int al_f = al_get_display_flags (display)
                       & fullscreen_flag;

    gui.Geom.set_screen_xyls(al_x, al_y);

    // if we didn't get what we wanted, make an entry in the log file
    if (want_x > 0 && want_y > 0
     && (want_x    != al_x
      || want_y    != al_y
      || want_full != al_f))
    {
        // DTODOLANG
        Log.logf("Your wanted %s mode at %dx%d cannot be used.",
            want_full ? "fullscreen" : "windowed",
            want_x, want_y);
        Log.logf("  ..falling back to %s at %dx%d.",
            al_f ? "fullscreen" : "windowed",
            al_x, al_y);
    }
}



void deinitialize()
{
    if (display) {
        al_unregister_event_source(queue,al_get_display_event_source(display));
        al_destroy_display(display);
        display = null;
    }
    if (queue) {
        al_destroy_event_queue(queue);
        queue = null;
    }
}



void calc()
{
    ALLEGRO_EVENT event;
    while(al_get_next_event(queue, &event))
    {
        if (event.type == ALLEGRO_EVENT_DISPLAY_CLOSE) {
            display_close_was_clicked = true;
        }
        else if (event.type == ALLEGRO_EVENT_DISPLAY_SWITCH_OUT) {
            hardware.mouse.set_trap_mouse(false);
        }
        else if (event.type == ALLEGRO_EVENT_DISPLAY_SWITCH_IN) {
            hardware.keyboard.clear_key_buffer_after_alt_tab();
            // Don't affect the mouse: the mouse shall only be trapped
            // when it is clicked in the game window
        }
    }
}



void display_startup_message(string str)
{
    static string[] msgs;
    msgs ~= str;

    AlBit backbuffer = al_get_backbuffer(display);
    mixin(temp_target!"backbuffer");

    al_clear_to_color(color.black);
    int y = 0;
    foreach (msg; msgs) {
        al_draw_text(djvu_s, color.white, 20, y += 20, ALLEGRO_ALIGN_LEFT,
         msg.toStringz());
    }
    al_flip_display();
}
