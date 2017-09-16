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
    Albit _appIcon = null;
    bool _displayActive;
    bool _displayCloseWasClicked;
    long[] _fpsArr;

public:

@property bool displayCloseWasClicked()
{
    return _displayCloseWasClicked;
}

@property bool displayActive()
{
    return _displayActive;
}

void flip_display()
{
    assert (display, "display hasn't been created");
    al_flip_display();

    // compute FPS, query result with displayFps()
    _fpsArr ~= timerTicks;
    while (_fpsArr != null && _fpsArr[0] <= _fpsArr[$-1] - ticksPerSecond)
        _fpsArr = _fpsArr[1 .. $];
}

@property int displayFps()
{
    return _fpsArr.len;
}

@property int displayXl()
{
    assert(display, "display hasn't been created");
    return al_get_display_width(display);
}

@property int displayYl()
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
            al_flip_display();
            // don't try further modes on success
            break;
        }
    }

    // cleaning up after the change, (re)instantiating the event queue
    assert (display);
    _displayActive = true;

    immutable int al_x = al_get_display_width (display);
    immutable int al_y = al_get_display_height(display);
    immutable int al_f = al_get_display_flags (display) & fullscreen_flag;
    assert (al_x > 0);
    assert (al_y > 0);

    al_set_window_title(display, nameOfTheGame.toStringz);
    loadIcon();
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
    if (_appIcon) {
        albitDestroy(_appIcon);
        _appIcon = null;
    }
    _displayActive = false;
}

void calc()
{
    ALLEGRO_EVENT event;
    while (al_get_next_event(queue, &event))
    {
        if (event.type == ALLEGRO_EVENT_DISPLAY_CLOSE) {
            _displayCloseWasClicked = true;
        }
        else if (event.type == ALLEGRO_EVENT_DISPLAY_SWITCH_OUT) {
            _displayActive = false;
            hardware.mouse.trapMouse = false;
            // This isn't generated on Debian 6 + Gnome 2 + Allegro 5.0.8
            // on Alt-Tabbing out of Lix. See the comment at
            // hardware.mouse.issue118workaround.
        }
        else if (event.type == ALLEGRO_EVENT_DISPLAY_SWITCH_IN) {
            _displayActive = true;
            hardware.keyboard.clearKeyBufferAfterAltTab();
            // Don't affect the mouse: the mouse shall only be trapped
            // when you click in the game window. The mouse will be trapped
            // when you move it back into the active window -- this is related
            // to DISPLAY_SWITCH_IN, and it queries displayActive, but happens
            // on a mouse event, not on a display event.
        }
    }
}

private:

void loadIcon()
{
    assert (display);
    if (! _appIcon)
        _appIcon = al_load_bitmap(fileImageAppIcon.stringzForReading);
    if (_appIcon)
        al_set_display_icon(display, _appIcon);
}
