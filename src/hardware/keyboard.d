module hardware.keyboard;

import std.array;
import std.utf;

import basics.globals : ticksPerSecond;
import basics.alleg5;

string utf8Input() { return _bufferUTF8; }

bool keyTapped  (int alkey) { return _once[alkey];     }
bool keyHeld    (int alkey) { return _hold[alkey] > 0; }
bool keyReleased(int alkey) { return _rlsd[alkey];     }

// For moving around terrain in the editor, and similar things that are
// meaningful if executed many times in a row. Move once, wait for repetitions.
bool keyTappedAllowingRepeats(int alkey)
{
    return _once[alkey]
        || _hold[alkey] > basics.globals.ticksForDoubleClick;
}

@property bool backspace()  { return _backspace;   } // detects hold-repeats
@property bool ctrlHeld ()  { return _ctrl;        }
@property bool shiftHeld()  { return _shift;       }
@property bool altHeld  ()  { return _alt;         }

@property int scancodeTapped() // For the hotkey-mapping button
{
    foreach (int scancode, bool tapped; _once)
        if (tapped)
            return scancode;
    return 0;
}

void clearKeyBufferAfterAltTab() { _hold[] = 0; }



private:

    ALLEGRO_EVENT_QUEUE* _queue;

    bool _backspace;
    bool _ctrl;  // holding at least one of the two Ctrl?
    bool _shift; // holding at least one of the two Shift?
    bool _alt;   // holding at least one of the two Alt that I consider equal?

    bool[ALLEGRO_KEY_MAX] _once;
    int [ALLEGRO_KEY_MAX] _hold;
    bool[ALLEGRO_KEY_MAX] _rlsd;

    string _bufferUTF8;



public:

void initialize()
{
    al_install_keyboard();
    _queue = al_create_event_queue();
    assert (_queue);
    al_register_event_source(_queue, al_get_keyboard_event_source());
}



void deinitialize()
{
    if (_queue) {
        al_unregister_event_source(_queue, al_get_keyboard_event_source());
        al_destroy_event_queue(_queue);
        _queue = null;
        al_uninstall_keyboard();
    }
}



void calc()
{
    // zero both arrays
    _once[]     = false;
    _rlsd[]     = false;
    _bufferUTF8 = null;
    _backspace  = false;

    ALLEGRO_EVENT event;
    while(al_get_next_event(_queue, &event))
    {
        if (event.type == ALLEGRO_EVENT_KEY_DOWN) {
            _once[event.keyboard.keycode] = true;
        }
        else if (event.type == ALLEGRO_EVENT_KEY_UP) {
            _rlsd[event.keyboard.keycode] = true;
        }
        else if (event.type == ALLEGRO_EVENT_KEY_CHAR) {
            immutable int c = event.keyboard.unichar;
            if (c >= 0x20    // ignore nonprintable ASCII
             && c != 0x7F) { // ignore the delete character
                char[] buf;
                std.utf.encode(buf, event.keyboard.unichar);
                _bufferUTF8 ~= buf;
            }
            else if (event.keyboard.keycode == ALLEGRO_KEY_BACKSPACE) {
                // A5 manual tells us to do this outside of the UTF8 scanning
                _backspace = true;
            }
        }
    }
    for (int i = 0; i < _hold.length; ++i) {
        // when the key is still held from last time, hold[i] > 0 right now
        if      (_hold[i] > 0 && _rlsd[i]) _hold[i] = 0;
        else if (_once[i])                 _hold[i] = 1;
        else if (_hold[i] > 0)             _hold[i] += 1;
    }
    _ctrl  = _hold[ALLEGRO_KEY_LCTRL]  || _hold[ALLEGRO_KEY_RCTRL];
    _shift = _hold[ALLEGRO_KEY_LSHIFT] || _hold[ALLEGRO_KEY_RSHIFT];
    _alt   = _hold[ALLEGRO_KEY_ALT]    || _hold[ALLEGRO_KEY_ALTGR];

    // Lump Enter and Keypad-Enter together already in the hardware. We had
    // ugly button code in A4/C++ Lix like this copied over and over:
    //      if (_hotkey == ALLEGRO_KEY_ENTER) b = b || key_enter_once();
    //      else                              b = b || keyTapped(_hotkey);
    enum e1 = ALLEGRO_KEY_ENTER;
    enum e2 = ALLEGRO_KEY_PAD_ENTER;
    _once[e1] = (_once[e2] = _once[e1] || _once[e2]);
    _rlsd[e1] = (_rlsd[e2] = _rlsd[e1] || _rlsd[e2]);
}
