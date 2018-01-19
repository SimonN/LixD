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

@property DisplayTryMode currentMode()
in { assert (display, "no current mode because no display exists"); }
body {
    DisplayTryMode ret;
    ret.x = displayXl;
    ret.y = displayYl;
    ret.mode = flagsToScreenMode(al_get_display_flags(display));
    return ret;
}

void flip_display()
{
    assert (display, "display hasn't been created");
    al_flip_display();
    computeFPS();
}

// This is like initialize() of other modules.
// For fullscreen, query the underlying desktop environment for resolution.
// For winwoded, use the wanted resolution, or fall back to 640 x 480.
void setScreenMode(in Cmdargs cmdargs)
{
    alias TryMode = DisplayTryMode;
    // FIFO queue of screen modes to try
    TryMode[] try_modes;

    // first priority goes to using setScreenMode()'s arguments, if they exist
    void addForcedMode(in ScreenMode mode)
    {
        try_modes ~= cmdargs.wantResolutionX > 0 && cmdargs.wantResolutionY > 0
            ? TryMode(mode, cmdargs.wantResolutionX, cmdargs.wantResolutionY)
            : TryMode(mode, 640, 480);
    }
    if (cmdargs.forceHardwareFullscreen)
        addForcedMode(ScreenMode.hardwareFullscreen);
    if (cmdargs.forceSoftwareFullscreen)
        try_modes ~= TryMode(ScreenMode.hardwareFullscreen, 0, 0);
    if (cmdargs.forceWindowed)
        addForcedMode(ScreenMode.windowed);

    // second priority goes to the normal fullscreen/windowed modes.
    void addTryModes(in ScreenMode mode)
    {
        if (screenWindowedX.value > 0 && screenWindowedY.value > 0)
            try_modes ~= TryMode(mode, screenWindowedX, screenWindowedY);
        try_modes ~= TryMode(mode, 640, 480);
    }
    switch (basics.user.screenMode.value) {
    case ScreenMode.windowed:
        addTryModes(ScreenMode.windowed);
        addTryModes(ScreenMode.softwareFullscreen);
        addTryModes(ScreenMode.hardwareFullscreen);
        break;
    case ScreenMode.hardwareFullscreen:
        addTryModes(ScreenMode.hardwareFullscreen);
        addTryModes(ScreenMode.softwareFullscreen);
        addTryModes(ScreenMode.windowed);
        break;
    default:
        addTryModes(ScreenMode.softwareFullscreen);
        addTryModes(ScreenMode.windowed);
        addTryModes(ScreenMode.hardwareFullscreen);
        break;
    }

    // now try the modes in the desired order
    foreach (ref tryMode; try_modes) {
        immutable int flags = al_get_new_display_flags()
            & ~ ALLEGRO_WINDOWED
            & ~ ALLEGRO_FULLSCREEN
            & ~ ALLEGRO_FULLSCREEN_WINDOW;
        al_set_new_display_flags(flags | screenModeToFlags(tryMode.mode));
        deinitialize();
        display = al_create_display(tryMode.x, tryMode.y);
        if (display) {
            al_flip_display();
            // don't try further modes on success
            break;
        }
    }

    // cleaning up after the change, (re)instantiating the event queue
    assert (display);
    _displayActive = true;
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

ScreenMode flagsToScreenMode(in int flags) pure nothrow @nogc
{
    if (flags & ALLEGRO_WINDOWED)
        return ScreenMode.windowed;
    if (flags & ALLEGRO_FULLSCREEN_WINDOW)
        return ScreenMode.softwareFullscreen;
    if (flags & ALLEGRO_FULLSCREEN)
        return ScreenMode.hardwareFullscreen;
    assert (false, "strange screen mode selected, can't decode flags");
}

int screenModeToFlags(in ScreenMode mode) pure nothrow @nogc
{
    final switch (mode) {
        case ScreenMode.windowed: return ALLEGRO_WINDOWED;
        case ScreenMode.softwareFullscreen: return ALLEGRO_FULLSCREEN_WINDOW;
        case ScreenMode.hardwareFullscreen: return ALLEGRO_FULLSCREEN;
    }
}

void computeFPS()
{
    _fpsArr ~= timerTicks;
    while (_fpsArr != null && _fpsArr[0] <= _fpsArr[$-1] - ticksPerSecond)
        _fpsArr = _fpsArr[1 .. $];
}
