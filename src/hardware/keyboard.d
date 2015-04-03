module hardware.keyboard;

import std.array;
import std.utf;

import basics.alleg5;

void initialize();
void deinitialize();

void calc();

void clear_key_buffer_after_alt_tab();

string           get_utf8_input() { return buf_utf8; }
deprecated int   get_key();
deprecated dchar get_key_ascii();

bool key_enter_once();    // special because Alt+Enter shall not
bool key_enter_release(); // these two work for both Enter and Enter_Pad

bool key_once(int alkey) { return once[alkey]; }
bool key_hold(int alkey) { return hold[alkey]; }
bool key_rlsd(int alkey) { return rlsd[alkey]; }
bool get_backspace()     { return backspace;   } // must detect hold-repeats
bool get_ctrl ()         { return ctrl;        }
bool get_shift()         { return shift;       }
bool get_alt  ()         { return alt;         }

// another name for the same thing
bool key_release(int alkey) { return rlsd[alkey]; }



private:

    ALLEGRO_EVENT_QUEUE* queue;

    bool backspace;
    bool ctrl;  // holding at least one of the two Ctrl?
    bool shift; // holding at least one of the two Shift?
    bool alt;   // holding at least one of the two Alt that I consider equal?
    bool last_tick_ctrl;  // Hardware-internal variable, necessary to enable
    bool last_tick_shift; // get_key() to return modifiers, DTODO: A4 legacy
    bool last_tick_alt;

    bool[ALLEGRO_KEY_MAX] once;
    bool[ALLEGRO_KEY_MAX] hold;
    bool[ALLEGRO_KEY_MAX] rlsd;

    string buf_utf8;



public:

void initialize()
{
    al_install_keyboard();
    queue = al_create_event_queue();
    assert (queue);
    al_register_event_source(queue, al_get_keyboard_event_source());
}



void deinitialize()
{
    al_unregister_event_source(queue, al_get_keyboard_event_source());
    al_destroy_event_queue(queue);
    queue = null;
    al_uninstall_keyboard();
}



void calc()
{
    // zero both arrays
    once[]    = false;
    rlsd[]    = false;
    buf_utf8  = null;
    backspace = false;

    ALLEGRO_EVENT event;
    while(al_get_next_event(queue, &event))
    {
        if (event.type == ALLEGRO_EVENT_KEY_DOWN) {
            once[event.keyboard.keycode] = true;
        }
        else if (event.type == ALLEGRO_EVENT_KEY_UP) {
            rlsd[event.keyboard.keycode] = true;
        }
        else if (event.type == ALLEGRO_EVENT_KEY_CHAR) {
            immutable int c = event.keyboard.unichar;
            if (c >= 0x20    // ignore nonprintable ASCII
             && c != 0xFF) { // ignore the delete character
                char[] buf;
                std.utf.encode(buf, event.keyboard.unichar);
                buf_utf8 ~= buf;
            }
            else if (event.keyboard.keycode == ALLEGRO_KEY_BACKSPACE) {
                // A5 manual tells us to do this outside of the UTF8 scanning
                backspace = true;
            }
        }
    }
    for (int i = 0; i < hold.length; ++i) {
        // when the key is still held from last time, hold[i] == true right now
        if (hold[i] && rlsd[i]) hold[i] = false;
        if (once[i]) hold[i] = true;
    }
    ctrl  = hold[ALLEGRO_KEY_LCTRL]  || hold[ALLEGRO_KEY_RCTRL];
    shift = hold[ALLEGRO_KEY_LSHIFT] || hold[ALLEGRO_KEY_RSHIFT];
    alt   = hold[ALLEGRO_KEY_ALT]    || hold[ALLEGRO_KEY_ALTGR];
}



void clear_key_buffer_after_alt_tab()
{
    hold[] = false;
}



deprecated int get_key()
{
    for (int i = 0; i < once.length; ++i) {
        if (once[i]) return i;
    }
    return 0;
}



deprecated dchar get_key_ascii()
{
    if (buf_utf8.empty) return 0;
    else return buf_utf8[0];
}



bool key_enter_once()
{
    // Don't trigger on fullscreen/windowed switch
    // We still do it in D/A5 Lix, even though there's no Alt+Enter here
    return ! get_alt() && (key_once(ALLEGRO_KEY_ENTER)
                        || key_once(ALLEGRO_KEY_PAD_ENTER));
}



bool key_enter_release()
{
    return key_release(ALLEGRO_KEY_ENTER)
     ||    key_release(ALLEGRO_KEY_PAD_ENTER);
}
