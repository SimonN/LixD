module hardware.display;

import std.array;
import std.string;

import basics.help; // positive mod
import basics.alleg5;
import basics.globals; // nameOfTheGame
import basics.globconf;
import graphic.color; // inside displayStartupMessage()
import graphic.textout; // inside displayStartupMessage()
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

deprecated bool clearScreenAtNextBlit;

private:

    ALLEGRO_EVENT_QUEUE* queue;
    bool _displayCloseWasClicked;
    long[] _fpsArr;



public:

bool
displayCloseWasClicked() {
    return _displayCloseWasClicked;
}




void
flip_display() {
    assert (display, "display hasn't been created");
    al_flip_display();

    // compute FPS, query result with displayFps()
    _fpsArr ~= al_get_timer_count(timer);
    while (_fpsArr != null && _fpsArr[0] <= _fpsArr[$-1] - ticksPerSecond)
        _fpsArr = _fpsArr[1 .. $];
}



@property int
displayFps()
{
    return _fpsArr.len;
}



@property int
displayXl()
{
    assert(display, "display hasn't been created");
    return al_get_display_width(display);
}



@property int
displayYl()
{
    assert(display, "display hasn't been created");
    return al_get_display_height(display);
}



// This is like initialize() of other modules.
// Will use global variables if res == (0, 0).
// If res == (0, 0) and the global variables are also (0, 0),
// then query the underlying desktop environment for fullscreen resolution,
// or, if window mode is desired, fall back to 640 x 480.
void setScreenMode(bool wantFull, int wantX = 0, int wantY = 0)
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

    // FIFO queue of screen modes to try
    TryMode[] try_modes;

    // top priority goes to using setScreenMode()'s arguments
    if (wantX > 0 && wantY > 0) {
        try_modes ~= TryMode(wantFull, wantX, wantY);
    }

    // two more modes for fullscreen, two more modes for windowed,
    // but choose the order of these additions based on wantFull
    void addFullscreenTryModes() {
        if (screenResolutionX > 0 && screenResolutionY > 0) {
            try_modes ~= TryMode(true, screenResolutionX,
                                       screenResolutionY);
        }
        try_modes  ~= TryMode(true, 640, 480);
    }
    void addWindowedTryModes() {
        if (screenWindowedX > 0 && screenWindowedY > 0) {
            try_modes ~= TryMode(false, screenWindowedX, screenWindowedY);
        }
        try_modes  ~= TryMode(false, 640, 480);
    }

    if (wantFull) {
        addFullscreenTryModes();
        addWindowedTryModes();
    }
    else {
        addWindowedTryModes();
        addFullscreenTryModes();
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

    immutable int al_x = al_get_display_width (display);
    immutable int al_y = al_get_display_height(display);
    immutable int al_f = al_get_display_flags (display) & fullscreen_flag;

    assert (al_x > 0);
    assert (al_y > 0);

    al_set_window_title(display, nameOfTheGame.toStringz);

    queue = al_create_event_queue();
    al_register_event_source(queue, al_get_display_event_source(display));

    hardware.mouse.centerMouse();

    gui.Geom.setScreenXYls(al_x, al_y);

    // if we didn't get what we wanted, make an entry in the log file
    if (wantX > 0 && wantY > 0
     && (wantX    != al_x
      || wantY    != al_y
      || wantFull != al_f))
    {
        // DTODOLANG
        logf("Your wanted %s mode at %dx%d cannot be used.",
            wantFull ? "fullscreen" : "windowed",
            wantX, wantY);
        logf("    -> Falling back to %s at %dx%d.",
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
            _displayCloseWasClicked = true;
        }
        else if (event.type == ALLEGRO_EVENT_DISPLAY_SWITCH_OUT) {
            hardware.mouse.trapMouse(false);
        }
        else if (event.type == ALLEGRO_EVENT_DISPLAY_SWITCH_IN) {
            hardware.keyboard.clearKeyBufferAfterAltTab();
            // Don't affect the mouse: the mouse shall only be trapped
            // when it is clicked in the game window
        }
    }
}



void displayStartupMessage(string str)
{
    static string[] msgs;
    msgs ~= str;

    auto drata = DrawingTarget(al_get_backbuffer(display));

    al_clear_to_color(color.black);
    int y = 0;
    foreach (msg; msgs) {
        al_draw_text(djvuS, color.white, 20, y += 20, ALLEGRO_ALIGN_LEFT,
         msg.toStringz());
    }
    al_flip_display();
}
