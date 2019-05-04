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
import file.option;
import file.log;

static import hardware.keyboard; // clear after changing resolution
static import hardware.mouse; // untrap the mouse when we leave the display

ALLEGRO_DISPLAY* theA5display;

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
        assert (theA5display, "display hasn't been created");
        return al_get_display_width(theA5display);
    }

    int displayYl()
    {
        assert (theA5display, "display hasn't been created");
        return al_get_display_height(theA5display);
    }

    ScreenChoice currentMode()
    in { assert (theA5display, "no current mode because no display exists"); }
    body {
        ScreenChoice ret;
        ret.x = displayXl;
        ret.y = displayYl;
        ret.type = flagsToScreenType(al_get_display_flags(theA5display));
        return ret;
    }
}

void flip_display()
{
    assert (theA5display, "display hasn't been created");
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
    foreach (ref tryMode; cmdArgModes(cmdargs)
        ~ file.option.screen.screenChoice
        ~ ScreenChoice(ScreenType.windowed, 640, 480) // a fallback mode
    ) {
        deinitialize();
        al_set_new_display_flags(flags | screenTypeToFlags(tryMode.type));
        theA5display = al_create_display(tryMode.x, tryMode.y);
        if (theA5display) {
            al_flip_display();
            // don't try further modes on success
            break;
        }
    }
    enforce(theA5display, "Can't instantiate a display even though we want"
        ~ " to run Lix in interactive mode. This is very strange; normally,"
        ~ " at least a window of size 640x480 should have spawned.");
    _displayActive = true;
    al_set_window_title(theA5display, nameOfTheGame.toStringz);
    loadIcon();
    queue = al_create_event_queue();
    al_register_event_source(queue, al_get_display_event_source(theA5display));
}

void deinitialize()
{
    if (theA5display) {
        al_unregister_event_source(
            queue, al_get_display_event_source(theA5display));
        al_destroy_display(theA5display);
        theA5display = null;
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

ScreenChoice[] cmdArgModes(in Cmdargs args)
{
    immutable wantX = args.wantResolutionX > 0 ? args.wantResolutionX : 640;
    immutable wantY = args.wantResolutionY > 0 ? args.wantResolutionY : 480;
    typeof(return) ret;
    if (args.forceHardwareFullscreen) {
        ret ~= ScreenChoice(ScreenType.hardwareFullscreen, wantX, wantY);
    }
    if (args.forceSoftwareFullscreen) {
        // Software fullscreen won't work (display won't be created by A5)
        // if we want software fullscreen with dimensions 0x0. We have to
        // pass arbitrary numbers > 0 here to entice A5 to use the desktop res.
        // Thus, we may as well pass wantX, wantY.
        ret ~= ScreenChoice(ScreenType.softwareFullscreen, wantX, wantY);
    }
    if (args.forceWindowed) {
        ret ~= ScreenChoice(ScreenType.windowed, wantX, wantY);
    }
    return ret;
}

void loadIcon()
{
    assert (theA5display);
    if (! _appIcon)
        _appIcon = al_load_bitmap(fileImageAppIcon.stringForReading.toStringz);
    if (_appIcon)
        al_set_display_icon(theA5display, _appIcon);
}

ScreenType flagsToScreenType(in int flags) pure nothrow @nogc
{
    if (flags & ALLEGRO_WINDOWED)
        return ScreenType.windowed;
    if (flags & ALLEGRO_FULLSCREEN_WINDOW)
        return ScreenType.softwareFullscreen;
    if (flags & ALLEGRO_FULLSCREEN)
        return ScreenType.hardwareFullscreen;
    assert (false, "strange screen mode selected, can't decode flags");
}

int screenTypeToFlags(in ScreenType st) pure nothrow @nogc
{
    final switch (st) {
        case ScreenType.windowed: return ALLEGRO_WINDOWED;
        case ScreenType.softwareFullscreen: return ALLEGRO_FULLSCREEN_WINDOW;
        case ScreenType.hardwareFullscreen: return ALLEGRO_FULLSCREEN;
    }
}

void computeFPS() nothrow
{
    _fpsArr ~= timerTicks;
    while (_fpsArr != null && _fpsArr[0] <= _fpsArr[$-1] - ticksPerSecond)
        _fpsArr = _fpsArr[1 .. $];
}
