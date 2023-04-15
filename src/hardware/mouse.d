module hardware.mouse;

import std.math; // abs

import basics.alleg5;
import basics.globals;
import basics.rect;
import opt = file.option.allopts;
import hardware.display;

void initialize();
void deinitialize();

void calc();

@property nothrow @safe @nogc {
    int   mouseX()        { return _mouseOwn.x; }
    int   mouseY()        { return _mouseOwn.y; }
    Point mouseOnScreen() { return _mouseOwn; }
    Point mouseMickey()   { return _mickey / mouseStandardDivisor; }

    bool mouseClickLeft()         { return _mouseClick  [0]; }
    bool mouseClickRight()        { return _mouseClick  [1]; }
    bool mouseClickMiddle()       { return _mouseClick  [2]; }
    bool mouseDoubleClickLeft()   { return _mouseDouble [0]; }
    bool mouseDoubleClickRight()  { return _mouseDouble [1]; }
    bool mouseDoubleClickMiddle() { return _mouseDouble [2]; }
    int  mouseHeldLeft()          { return _mouseHeldFor[0]; }
    int  mouseHeldRight()         { return _mouseHeldFor[1]; }
    int  mouseHeldMiddle()        { return _mouseHeldFor[2]; }
    bool mouseHeldLongLeft()      { return _mouseHeldFor[0] > _dSpeed; }
    bool mouseHeldLongRight()     { return _mouseHeldFor[1] > _dSpeed; }
    bool mouseHeldLongMiddle()    { return _mouseHeldFor[2] > _dSpeed; }
    int  mouseReleaseLeft()       { return _mouseRelease[0]; }
    int  mouseReleaseRight()      { return _mouseRelease[1]; }
    int  mouseReleaseMiddle()     { return _mouseRelease[2]; }
    int  mouseWheelNotches()      { return _wheelNotches; }

    bool hardwareMouseInsideWindow() { return _trapMouse; }
}

void trapMouse(bool b) { _trapMouse = b; }

private:
    ALLEGRO_EVENT_QUEUE* _queue;
    bool _trapMouse = true;

    Point _mouseOwn; // where is the cursor on the Lix screen
    Point _mouseFreezeRevert; // previous main loop's _mouseOwn
    Point _mickey; // Difference of _mouseOwnX since last mainLoop
    Point _mickeyLeftover; // leftover movement from the previous mickeys,
                           // yet unspent to _mouseOwnXy, for smoothening
    int _wheelNotches; // often 0, only != 0 when wheel was used

    // The mouse has 3 buttons: #0 is left, #1 is right, #2 is middle.
    bool[3] _mouseClick;   // there just was a single click
    bool[3] _mouseDouble;  // there just was a double click
    int [3] _mouseHeldFor; // mouse button has been held for... (0 if not)
    int [3] _mouseRelease; // just released button after being held for ...
    int [3] _mouseSince;   // how long ago was the last click, for doubleclick

    alias _dSpeed = basics.globals.ticksForDoubleClick;

    int xl() { assert (theA5display); return al_get_display_width (theA5display); }
    int yl() { assert (theA5display); return al_get_display_height(theA5display); }

public:

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
        al_destroy_event_queue(_queue);
        _queue = null;
        al_uninstall_mouse();
    }
}

void calc()
{
    // Setting to zero all things that are good for only one mainLoop,
    // incrementing the times on others.
    _mickey = _mickeyLeftover;
    _wheelNotches = 0;

    foreach (i; 0 .. 3) {
        _mouseClick  [i] = false;
        _mouseDouble [i] = false;
        _mouseRelease[i] = 0;
        _mouseSince  [i] += 1;
        if (_mouseHeldFor[i]) ++_mouseHeldFor[i];
    }

    consumeAllegroMouseEvents();
    handleTrappedMouse();

    _mouseFreezeRevert = _mouseOwn; // make backup from previous calc()
    _mouseOwn += _mickey / mouseStandardDivisor;
    _mickeyLeftover = _mickey % mouseStandardDivisor; // we want signed %

    if (_mouseOwn.x < 0) _mouseOwn.x = 0;
    if (_mouseOwn.y < 0) _mouseOwn.y = 0;
    if (_mouseOwn.x >= xl) _mouseOwn.x = xl - 1;
    if (_mouseOwn.y >= yl) _mouseOwn.y = yl - 1;
}
// end void update()

void freezeMouseX() { _mouseOwn.x = _mouseFreezeRevert.x; }
void freezeMouseY() { _mouseOwn.y = _mouseFreezeRevert.y; }

private:

void consumeAllegroMouseEvents()
{
    // I will adhere to my convention from C++/A4 Lix to multiply all incoming
    // mouse movements by the mouse speed, and then later divide by constant
    ALLEGRO_EVENT event;
    while (al_get_next_event(_queue, &event)) {
        if (event.mouse.display != theA5display)
            continue;

        immutable int i = event.mouse.button - 1;

        switch (event.type) {
        case ALLEGRO_EVENT_MOUSE_AXES:
            if (! isBuggyJump(&event)) {
                _mickey += Point(event.mouse.dx, event.mouse.dy)
                        * opt.mouseSpeed.value;
            }
            _wheelNotches -= event.mouse.dz;
            break;

        case ALLEGRO_EVENT_MOUSE_BUTTON_DOWN:
            if (i < 0 || i >= 3) break;
            _mouseClick  [i] = true;
            _mouseDouble [i] = (_mouseSince[i] < _dSpeed);
            _mouseSince  [i] = 0;
            _mouseHeldFor[i] = 1;
            _trapMouse       = true;
            break;

        case ALLEGRO_EVENT_MOUSE_BUTTON_UP:
            if (i < 0 || i >= 3) break;
            _mouseRelease[i] = _mouseHeldFor[i];
            _mouseHeldFor[i] = 0;
            break;

        // This occurs after centralizing the mouse manually.
        case ALLEGRO_EVENT_MOUSE_WARPED:
            break;

        case ALLEGRO_EVENT_MOUSE_ENTER_DISPLAY:
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
