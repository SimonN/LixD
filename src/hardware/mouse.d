module hardware.mouse;

import std.math; // abs

import basics.alleg5;
import basics.globals;
import basics.rect;
import basics.user;
import hardware.display;

void initialize();
void deinitialize();

void calc();

@property int   mouseMickeyX()  { return _mickeyX / mouseStandardDivisor; }
@property int   mouseMickeyY()  { return _mickeyY / mouseStandardDivisor; }
@property int   mouseX()        { return _mouseOwnX; }
@property int   mouseY()        { return _mouseOwnY; }
@property Point mouseOnScreen() { return Point(_mouseOwnX, _mouseOwnY); }

@property bool mouseClickLeft()         { return _mouseClick  [0]; }
@property bool mouseClickRight()        { return _mouseClick  [1]; }
@property bool mouseClickMiddle()       { return _mouseClick  [2]; }
@property bool mouseDoubleClickLeft()   { return _mouseDouble [0]; }
@property bool mouseDoubleClickRight()  { return _mouseDouble [1]; }
@property bool mouseDoubleClickMiddle() { return _mouseDouble [2]; }
@property int  mouseHeldLeft()          { return _mouseHeldFor[0]; }
@property int  mouseHeldRight()         { return _mouseHeldFor[1]; }
@property int  mouseHeldMiddle()        { return _mouseHeldFor[2]; }
@property bool mouseHeldLongLeft()      { return _mouseHeldFor[0] > _dSpeed; }
@property bool mouseHeldLongRight()     { return _mouseHeldFor[1] > _dSpeed; }
@property bool mouseHeldLongMiddle()    { return _mouseHeldFor[2] > _dSpeed; }
@property int  mouseReleaseLeft()       { return _mouseRelease[0]; }
@property int  mouseReleaseRight()      { return _mouseRelease[1]; }
@property int  mouseReleaseMiddle()     { return _mouseRelease[2]; }

@property int  mouseWheelNotches()      { return _wheelNotches; }

void trapMouse(bool b) { _trapMouse = b; }
void freezeMouseX();
void freezeMouseY();

// There seems to be a bug in Allegro 5.0.8: Clicking out of
// the window sends a switch-out event, correct. But alt-tabbing
// out of the window doesn't make a display-switch-out-event on
// Debian 6 + Gnome 2. I want to un-trap the mouse when we alt-tab
// out of the window, and use a workaround when we lack the event.
version (linux)
    enum issue118workaround = true;
else
    enum issue118workaround = false;

private:

    ALLEGRO_EVENT_QUEUE* _queue;

    bool _trapMouse = true;
    bool _centerMouseAtNextUpdate = true;

    int  _mouseOwnX; // where the cursor will appear, != al_mouse
    int  _mouseOwnY;
    int  _mickeyX; // Difference of _mouseOwnX since last mainLoop
    int  _mickeyY;
    int  _mickeyLeftoverX; // leftover movement from the previous mickeys,
    int  _mickeyLeftoverY; // yet unspent to _mouseOwnXy, for smoothening
    int  _wheelNotches;    // often 0, only != 0 when wheel was used

    // The mouse has 3 buttons: #0 is left, #1 is right, #2 is middle.
    bool[3] _mouseClick;   // there just was a single click
    bool[3] _mouseDouble;  // there just was a double click
    int [3] _mouseHeldFor; // mouse button has been held for... (0 if not)
    int [3] _mouseRelease; // just released button after being held for ...
    int [3] _mouseSince;   // how long ago was the last click, for doubleclick

    alias _dSpeed = basics.globals.ticksForDoubleClick;

    void set_mouse_accel_on_windows(bool);

public:

void initialize()
{
    // A5 must have been initialized already.
    al_install_mouse();
    assert (! _queue);
    _queue = al_create_event_queue();
    assert (_queue);
    al_register_event_source(_queue, al_get_mouse_event_source());

    if (display) al_hide_mouse_cursor(display);
    _mouseOwnX = al_get_display_width (display) / 2;
    _mouseOwnY = al_get_display_height(display) / 2;
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
    immutable int xl = al_get_display_width (display);
    immutable int yl = al_get_display_height(display);

    // Setting to zero all things that are good for only one mainLoop,
    // incrementing the times on others.
    _mickeyX = _mickeyLeftoverX;
    _mickeyY = _mickeyLeftoverY;
    _wheelNotches = 0;

    foreach (i; 0 .. 3) {
        _mouseClick  [i] = false;
        _mouseDouble [i] = false;
        _mouseRelease[i] = 0;
        _mouseSince  [i] += 1;
        if (_mouseHeldFor[i]) ++_mouseHeldFor[i];
    }

    // Local variables: current hardware mouse position. We reset the hardware
    // mouse back to the screen center if the hardware mouse is close to edge.
    int hardwareSavedOnlyForResetX = xl / 2;
    int hardwareSavedOnlyForResetY = yl / 2;

    // I will adhere to my convention from C++/A4 Lix to multiply all incoming
    // mouse movements by the mouse speed, and then later divide by constant
    ALLEGRO_EVENT event;
    while (al_get_next_event(_queue, &event)) {
        if (event.mouse.display != display)
            continue;

        immutable int i = event.mouse.button - 1;

        switch (event.type) {
        case ALLEGRO_EVENT_MOUSE_AXES:
            // DTODO: Only use mouseSpeed in fullscreen, not in window mode
            _mickeyX += event.mouse.dx * basics.user.mouseSpeed;
            _mickeyY += event.mouse.dy * basics.user.mouseSpeed;
            hardwareSavedOnlyForResetX = event.mouse.x;
            hardwareSavedOnlyForResetY = event.mouse.y;
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
            static if (issue118workaround) {
                _trapMouse = true;
            }
            break;

        case ALLEGRO_EVENT_MOUSE_ENTER_DISPLAY:
            static if (! issue118workaround) {
                if (hardware.display.displayActive)
                    _trapMouse = true;
            }
            // Nepster 2016-06: When entering the display, the ingame
            // cursor should jump to where we entered.
            // This would sometimes trigger when the hardware mouse is close
            // to the window edge, and is reset to window center by
            // al_set_mouse_xy(), see further down this function calc().
            // To guard against this, we move the mouse only if hardware
            // x or y are sufficiently far away from the screen center.
            if (   abs(event.mouse.x - xl/2) > 5
                || abs(event.mouse.y - yl/2) > 5
            ) {
                _mouseOwnX = event.mouse.x;
                _mouseOwnY = event.mouse.y;
            }
            break;

        case ALLEGRO_EVENT_MOUSE_LEAVE_DISPLAY:
            _trapMouse = false;
            break;

        default:
            break;
        }
    }
    _mouseOwnX      += _mickeyX / mouseStandardDivisor;
    _mouseOwnY      += _mickeyY / mouseStandardDivisor;
    _mickeyLeftoverX = _mickeyX % mouseStandardDivisor; // we want signed %
    _mickeyLeftoverY = _mickeyY % mouseStandardDivisor;

    if (_mouseOwnX < 0)   _mouseOwnX = 0;
    if (_mouseOwnY < 0)   _mouseOwnY = 0;
    if (_mouseOwnX >= xl) _mouseOwnX = xl - 1;
    if (_mouseOwnY >= yl) _mouseOwnY = yl - 1;

    if (_trapMouse) {
        al_hide_mouse_cursor(display);

        bool isCloseToEdge(in int pos, in int length)
        {
            if (_mouseHeldFor[1] || _mouseHeldFor[2])
                // RMB scrolling should reset rather often.
                // Curiously, this is not responsible for trapping the mouse
                // in the window with guarantee. That's still magic to me.
                return pos * 4 < length || pos * 4 >= length * 3;
            else
                // Make it even easier for the mouse to leave window,
                // resetting closer to the edge => less speed to leave.
                return pos * 16 < length || pos * 16 >= length * 15;
        }

        if (   isCloseToEdge(hardwareSavedOnlyForResetX, xl)
            || isCloseToEdge(hardwareSavedOnlyForResetY, yl))
             // do not call centerMouse, that would move _mouseOwnX/Y
             al_set_mouse_xy(display, xl/2, yl/2);
    }
    else {
        assert (! _trapMouse);
        al_show_mouse_cursor(display);
    }
}
// end void update()

void freezeMouseX()
{
    immutable int xl = al_get_display_width(display);
    _mouseOwnX -= _mickeyX / mouseStandardDivisor;
    if (_mouseOwnX < 0)   _mouseOwnX = 0;
    if (_mouseOwnX >= xl) _mouseOwnX = xl - 1;
}

void freezeMouseY()
{
    immutable int yl = al_get_display_height(display);
    _mouseOwnY -= _mickeyY / mouseStandardDivisor;
    if (_mouseOwnY < 0)   _mouseOwnY = 0;
    if (_mouseOwnY >= yl) _mouseOwnY = yl - 1;
}
