module hardware.display;

/*
 * Switching the screen resolution: Look at basics.resol to do that from
 * within the program. That deinitializes all bitmaps, then switches by
 * calling hardware.display.setScreenMode, then reloads all bitmaps.
 * Thus, all bitmaps are always tied to VRAM screens, otherwise they're slow.
 */

import std.array;
import std.string;
import std.exception;

import basics.alleg5;
import basics.cmdargs;
import basics.help; // positive mod
import basics.globals; // nameOfTheGame
import basics.user;
import file.log;

static import hardware.keyboard; // clear after changing resolution
static import hardware.mouse; // untrap the mouse when we leave the display

ALLEGRO_DISPLAY* display;

private:
    ALLEGRO_EVENT_QUEUE* queue;
    Albit _appIcon = null;
    bool _displayActive;
    bool _displayCloseWasClicked;
    long[] _fpsArr;

public:

@property @nogc nothrow {
    bool displayCloseWasClicked() { return _displayCloseWasClicked; }
    bool displayActive() { return _displayActive; }
    int displayFps() { return _fpsArr.len; }
    int displayXl()
    {
        assert(display, "display hasn't been created");
        return al_get_display_width(display);
    }

    int displayYl()
    {
        assert(display, "display hasn't been created");
        return al_get_display_height(display);
    }

    DisplayTryMode currentMode()
    in { assert (display, "no current mode because no display exists"); }
    body {
        DisplayTryMode ret;
        ret.x = displayXl;
        ret.y = displayYl;
        ret.mode = flagsToScreenMode(al_get_display_flags(display));
        return ret;
    }
}

void flip_display()
{
    assert (display, "display hasn't been created");
    al_flip_display();
    computeFPS();
}

// This is like initialize() of other modules.
void setScreenMode(in Cmdargs cmdargs)
{
    immutable int flags = al_get_new_display_flags()
        & ~ ALLEGRO_WINDOWED
        & ~ ALLEGRO_FULLSCREEN
        & ~ ALLEGRO_FULLSCREEN_WINDOW;
    foreach (ref tryMode;
        cmdArgModes(cmdargs) ~ userFileModes() ~ fallbackModes()
    ) {
        deinitialize();
        al_set_new_display_flags(flags | screenModeToFlags(tryMode.mode));
        display = al_create_display(tryMode.x, tryMode.y);
        if (display) {
            al_flip_display();
            // don't try further modes on success
            break;
        }
    }
    enforce(display, "Can't instantiate a display even though we want"
        ~ " to run Lix in interactive mode. This is very strange; normally,"
        ~ " at least a window of size 640x480 should have spawned.");
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

DisplayTryMode[] cmdArgModes(in Cmdargs args)
{
    immutable wantX = args.wantResolutionX > 0 ? args.wantResolutionX : 640;
    immutable wantY = args.wantResolutionY > 0 ? args.wantResolutionY : 480;
    typeof(return) ret;
    if (args.forceHardwareFullscreen)
        ret ~= DisplayTryMode(ScreenMode.hardwareFullscreen, wantX, wantY);
    if (args.forceSoftwareFullscreen)
        // Software fullscreen won't work (display won't be created by A5)
        // if we want software fullscreen with dimensions 0x0. We have to
        // pass arbitrary numbers > 0 here to entice A5 to use the desktop res.
        // Thus, we may as well pass wantX, wantY.
        ret ~= DisplayTryMode(ScreenMode.softwareFullscreen, wantX, wantY);
    if (args.forceWindowed)
        ret ~= DisplayTryMode(ScreenMode.windowed, wantX, wantY);
    return ret;
}

DisplayTryMode[] userFileModes()
{
    immutable wantX = screenWindowedX.value > 0 ? screenWindowedX.value : 640;
    immutable wantY = screenWindowedY.value > 0 ? screenWindowedY.value : 480;
    typeof(return) ret;
    switch (basics.user.screenMode.value) {
    case ScreenMode.windowed:
        ret ~= DisplayTryMode(ScreenMode.windowed, wantX, wantY);
        ret ~= DisplayTryMode(ScreenMode.softwareFullscreen, wantX, wantY);
        ret ~= DisplayTryMode(ScreenMode.hardwareFullscreen, wantX, wantY);
        return ret;
    case ScreenMode.hardwareFullscreen:
        ret ~= DisplayTryMode(ScreenMode.hardwareFullscreen, wantX, wantY);
        ret ~= DisplayTryMode(ScreenMode.softwareFullscreen, wantX, wantY);
        ret ~= DisplayTryMode(ScreenMode.windowed, wantX, wantY);
        return ret;
    default:
        ret ~= DisplayTryMode(ScreenMode.softwareFullscreen, wantX, wantY);
        ret ~= DisplayTryMode(ScreenMode.windowed, wantX, wantY);
        ret ~= DisplayTryMode(ScreenMode.hardwareFullscreen, wantX, wantY);
        return ret;
    }
}

DisplayTryMode[] fallbackModes()
{
    return [ DisplayTryMode(ScreenMode.windowed, 640, 480) ];
}

void loadIcon()
{
    assert (display);
    if (! _appIcon)
        _appIcon = al_load_bitmap(fileImageAppIcon.stringForReading.toStringz);
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

void computeFPS() nothrow
{
    _fpsArr ~= timerTicks;
    while (_fpsArr != null && _fpsArr[0] <= _fpsArr[$-1] - ticksPerSecond)
        _fpsArr = _fpsArr[1 .. $];
}
