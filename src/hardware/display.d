module hardware.display;

import std.array;
import std.string;

import basics.cmdargs;
import basics.help; // positive mod
import basics.alleg5;
import basics.globals; // nameOfTheGame
import basics.user; // what windowed resolution does the user want
import file.log;

static import hardware.keyboard; // clear after changing resolution
static import hardware.mouse; // untrap the mouse when we leave the display

/* A module for setting a screen resolution.
 * Right now, if you switch the screen resolution after having created all
 * the bitmaps, they will be put into RAM, and subsequent drawing will be
 * extremely slow. Avoid switching the resolution at all costs, or implement
 * something to improve performance after the switch.
 */

ALLEGRO_DISPLAY* display;

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
    _fpsArr ~= timerTicks;
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
// For fullscreen, query the underlying desktop environment for resolution.
// For winwoded, use the wanted resolution, or fall back to 640 x 480.
void setScreenMode(in Cmdargs cmdargs)
{
    struct TryMode {
        bool full;
        int x, y;
    }

    // FIFO queue of screen modes to try
    TryMode[] try_modes;

    // first priority goes to using setScreenMode()'s arguments, if they exist
    if (cmdargs.forceHardwareFullscreen) {
        if (cmdargs.wantResolutionX > 0 && cmdargs.wantResolutionY > 0)
            try_modes ~= TryMode(true, cmdargs.wantResolutionX,
                                       cmdargs.wantResolutionY);
        else try_modes ~= TryMode(true, 640, 480);
    }
    if (cmdargs.forceWindowed) {
        if (cmdargs.wantResolutionX > 0 && cmdargs.wantResolutionY > 0)
            try_modes ~= TryMode(false, cmdargs.wantResolutionX,
                                        cmdargs.wantResolutionY);
        else try_modes ~= TryMode(false, 640, 480);
    }

    // second priority goes to the normal fullscreen/windowed modes.
    void addTryModes(bool full) {
        if (screenWindowedX.value > 0 && screenWindowedY.value > 0)
            try_modes ~= TryMode(full, screenWindowedX.value,
                                       screenWindowedY.value);
        try_modes ~= TryMode(full, 640, 480);
    }
    immutable preferWindowed = ! cmdargs.forceSoftwareFullscreen
        && (cmdargs.forceWindowed || basics.user.screenWindowed.value);
    addTryModes(! preferWindowed);
    addTryModes(preferWindowed);

    immutable fullscreen_flag = cmdargs.forceHardwareFullscreen
        ? ALLEGRO_FULLSCREEN : ALLEGRO_FULLSCREEN_WINDOW;

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

        if (display) {
            // Shotgun debugging to prevent Icho's white window.
            // An Allegro 5 user reported that this makes the window black.
            al_flip_display();
            // If that doesn't help with Icho, try this instead:
            // al_clear_to_color(ALLEGRO_COLOR(0, 0, 0, 1)); // black
            // al_flip_display();

            // don't try further modes on success
            break;
        }
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
