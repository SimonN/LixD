module hardware.mouse;

import std.math; // abs

import basics.alleg5;
import basics.globals;
import basics.rect;
import file.key.key;
import opt = file.option.allopts;
import hardware.display;
import hardware.keyhist;

nothrow @safe @nogc {
    int   mouseX()        { return _mouseOwn.x; }
    int   mouseY()        { return _mouseOwn.y; }
    Point mouseOnScreen() { return _mouseOwn; }
    Point mouseMickey()   { return _mickey / mouseStandardDivisor; }

    bool mouseClickLeft()     { return _mbHist[1].wasTapped; }
    bool mouseClickRight()    { return _mbHist[2].wasTapped; }
    int  mouseHeldLeft()      { return _mbHist[1].isHeldForAlticks; }
    int  mouseHeldRight()     { return _mbHist[2].isHeldForAlticks; }
    bool mouseHeldLongLeft()  { return _mbHist[1].isHeldForAlticks > _dSpeed; }
    bool mouseHeldLongRight() { return _mbHist[2].isHeldForAlticks > _dSpeed; }
    int  mouseReleaseLeft()   { return _mbHist[1].wasReleased; }
    int  mouseReleaseRight()  { return _mbHist[2].wasReleased; }
    int  mouseWheelNotches()  { return _wheelNotches; }

    bool hardwareMouseInsideWindow() { return _trapMouse; }
}

void trapMouse(bool b) { _trapMouse = b; }

void initialize()
{
    // A5 must have been initialized already.
    al_install_mouse();
    assert (! _queue);
    _queue = al_create_event_queue();
    assert (_queue);
    al_register_event_source(_queue, al_get_mouse_event_source());

    if (theA5display) {
        al_hide_mouse_cursor(theA5display);
        _mouseOwn = Point(xl / 2, yl / 2);
        _mouseFreezeRevert = _mouseOwn;
    }
}

void deinitialize()
{
    if (_queue) {
        al_unregister_event_source(_queue, al_get_mouse_event_source());
        al_destroy_event_queue(_queue);
        _queue = null;
        al_uninstall_mouse();
    }
}

void calc()
{
    foreach (ref hist; _mbHist) hist.resetTappedAndReleased;
    foreach (ref hist; _whHist) hist.resetTappedAndReleased;
    _mickey = _mickeyLeftover;
    _wheelNotches = 0;

    consumeAllegroMouseEvents();
    foreach (ref hist; _mbHist) {
        hist.updateHeldAccordingToTapped();
    }
    // Do nothing for _whHist. You can't hold wheel-notch-counting hotkeys.

    handleTrappedMouse();

    _mouseFreezeRevert = _mouseOwn; // make backup from previous calc()
    _mouseOwn += _mickey / mouseStandardDivisor;
    _mickeyLeftover = _mickey % mouseStandardDivisor; // we want signed %

    if (_mouseOwn.x < 0) _mouseOwn.x = 0;
    if (_mouseOwn.y < 0) _mouseOwn.y = 0;
    if (_mouseOwn.x >= xl) _mouseOwn.x = xl - 1;
    if (_mouseOwn.y >= yl) _mouseOwn.y = yl - 1;
}

void freezeMouseX() { _mouseOwn.x = _mouseFreezeRevert.x; }
void freezeMouseY() { _mouseOwn.y = _mouseFreezeRevert.y; }

package:

// _mbHist: 0 = unused, 1 = lmb, 2 = rmb, 3 = mmb, 4+ = extras
// _whHist: 0 = unused, 1 = Wheel notch up, 2 = wheel notch down
KeyHistory[Key.firstInvalidMouseButton] _mbHist;
KeyHistory[Key.firstInvalidWheelDirection] _whHist;

///////////////////////////////////////////////////////////////////////////////
private: ///////////////////////////////////////////////////////////// :private
///////////////////////////////////////////////////////////////////////////////

ALLEGRO_EVENT_QUEUE* _queue;

bool _trapMouse = true;

Point _mouseOwn; // where is the cursor on the Lix screen
Point _mouseFreezeRevert; // previous main loop's _mouseOwn
Point _mickey; // Difference of _mouseOwnX since last mainLoop
Point _mickeyLeftover; // leftover movement from the previous mickeys,
                       // yet unspent to _mouseOwnXy, for smoothening
/*
 * Often 0. Only != 0 if we had mouse wheel activity in this main loop
 * iteration. If it's < 0, the wheel turned up. If > 0, the wheel turned down.
 * This is inverted from how Allegro 5's mice events report the wheel axis.
 *
 * For fast wheel movement (scrolling through a list), you'll want to see
 * directly by how many notches (possibly more than a single one) we moved
 * this altick. It won't be enough to treat the wheel as a mere hotkey then.
 */
int _wheelNotches;

alias _dSpeed = basics.globals.ticksForDoubleClick;

int xl() { assert (theA5display); return al_get_display_width (theA5display); }
int yl() { assert (theA5display); return al_get_display_height(theA5display); }



void consumeAllegroMouseEvents()
{
    // I will adhere to my convention from C++/A4 Lix to multiply all incoming
    // mouse movements by the mouse speed, and then later divide by constant
    ALLEGRO_EVENT event;
    while (al_get_next_event(_queue, &event)) {
        if (event.mouse.display != theA5display)
            continue;

        switch (event.type) {
        case ALLEGRO_EVENT_MOUSE_AXES:
            if (! isBuggyJump(&event)) {
                _mickey += Point(event.mouse.dx, event.mouse.dy)
                        * opt.mouseSpeed.value;
            }
            if (event.mouse.dz != 0) {
                _wheelNotches -= event.mouse.dz;
                _whHist[event.mouse.dz > 0 ? 1 : 2].wasTapped = true;
            }
            break;

        case ALLEGRO_EVENT_MOUSE_BUTTON_DOWN:
            if (event.mouse.button < 0 || event.mouse.button >= _mbHist.length)
                break;
            _mbHist[event.mouse.button].wasTapped = true;
            _trapMouse = true;
            break;

        case ALLEGRO_EVENT_MOUSE_BUTTON_UP:
            if (event.mouse.button < 0 || event.mouse.button >= _mbHist.length)
                break;
            _mbHist[event.mouse.button].wasReleased = true;
            break;

        // This occurs after centralizing the mouse manually.
        case ALLEGRO_EVENT_MOUSE_WARPED:
            break;

        case ALLEGRO_EVENT_MOUSE_ENTER_DISPLAY:
            if (hardware.display.displayActive)
                _trapMouse = true;
            // Nepster 2016-06: When entering the display, the ingame
            // cursor should jump to where we entered.
            // This would sometimes trigger when the hardware mouse is close
            // to the window edge, and is reset to window center by
            // al_set_mouse_xy(), see further down this function calc().
            // To guard against this, we move the mouse only if hardware
            // x or y are sufficiently far away from the screen center.
            if (   abs(event.mouse.x - xl/2) > 5
                || abs(event.mouse.y - yl/2) > 5) {
                _mouseOwn = Point(event.mouse.x, event.mouse.y);
            }
            break;

        case ALLEGRO_EVENT_MOUSE_LEAVE_DISPLAY:
            _trapMouse = false;
            break;

        default:
            break;
        }
    }
}

bool isBuggyJump(const ALLEGRO_EVENT* event)
in {
    assert (event.type == ALLEGRO_EVENT_MOUSE_AXES
        ||  event.type == ALLEGRO_EVENT_MOUSE_WARPED);
}
do {
    // I had massive jumps on hardware mouse warp on Arch 2017, Al 5.2.
    // So did Forestidia: https://www.lemmingsforums.net/index.php?topic=3487
    // Guard only against huge jumps over almost half the screen.
    return event.mouse.dx.abs > xl/3 || event.mouse.dy.abs > yl/3;
}

void handleTrappedMouse()
{
    if (! _trapMouse) {
        al_show_mouse_cursor(theA5display);
        return;
    }
    bool isCloseToEdge(in int pos, in int length)
    {
        return ! opt.fastMovementFreesMouse.value
            ? pos != length/2 // hard to leave
            : pos * 16 < length || pos * 16 >= length * 15; // easy to leave
    }
    al_hide_mouse_cursor(theA5display);
    ALLEGRO_MOUSE_STATE state;
    al_get_mouse_state(&state);
    if (   isCloseToEdge(al_get_mouse_state_axis(&state, 0), xl)
        || isCloseToEdge(al_get_mouse_state_axis(&state, 1), yl)
    ) {
        al_set_mouse_xy(theA5display, xl/2, yl/2);
    }
}
