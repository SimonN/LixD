module hardware.keynames;

import std.conv;

import basics.alleg5;

// Assignable as hotkeys
enum keyMMB       = ALLEGRO_KEY_MAX;
enum keyRMB       = ALLEGRO_KEY_MAX + 1;
enum keyWheelUp   = ALLEGRO_KEY_MAX + 2;
enum keyWheelDown = ALLEGRO_KEY_MAX + 3;

// Constant for hardware.keyboard. Keep this as max(above names) + 1.
enum hardwareKeyboardArrLen = ALLEGRO_KEY_MAX + 4;

// To access the names from most of the application, use KeySet.nameLong()
// or KeySet.nameShort(). This array can't be read from other source dirs.
package enum string[hardwareKeyboardArrLen] keyNames = ()
{
    string[hardwareKeyboardArrLen] arr;
    enum strKeyPad = "\U0001D356"; // Tetagram For Fostering, 3x4 squares
    enum strBackspace = "\u232B"; // Erase to the left
    enum strDelete = "\u2326"; // Erase to the right
    enum strReturn = "\u21B2"; // Down arrow with tip towards the left
    enum strMinus = "\u2212"; // unicode minus
    enum strShift = "Shift"; // \u2302 house, because it's fatter than
                             // \u21E7 = upwards white arrow, shift arrow

    arr[ALLEGRO_KEY_TILDE] = "~";
    arr[ALLEGRO_KEY_MINUS] = strMinus;
    arr[ALLEGRO_KEY_EQUALS] = "=";
    arr[ALLEGRO_KEY_BACKSPACE] = strBackspace;
    arr[ALLEGRO_KEY_TAB] = "\u21B9"; // Tab symbol, two keys with bars
    arr[ALLEGRO_KEY_ENTER] = strReturn;
    arr[ALLEGRO_KEY_LEFT] = "\u2190";
    arr[ALLEGRO_KEY_RIGHT] = "\u2192";
    arr[ALLEGRO_KEY_UP] = "\u2191";
    arr[ALLEGRO_KEY_DOWN] = "\u2193";

    arr[ALLEGRO_KEY_FULLSTOP] = ".";
    arr[ALLEGRO_KEY_COMMA] = ",";
    arr[ALLEGRO_KEY_SLASH] = "Slash";
    arr[ALLEGRO_KEY_OPENBRACE] = "[";
    arr[ALLEGRO_KEY_CLOSEBRACE] = "]";
    arr[ALLEGRO_KEY_SEMICOLON] = ";";
    arr[ALLEGRO_KEY_QUOTE] = "\"";

    arr[ALLEGRO_KEY_LSHIFT] = strShift;
    arr[ALLEGRO_KEY_RSHIFT] = strShift;
    arr[ALLEGRO_KEY_LCTRL] = "Ctrl";
    arr[ALLEGRO_KEY_RCTRL] = "Ctrl";

    foreach (int padNr; 0 .. 10)
        arr[ALLEGRO_KEY_PAD_0 + padNr] = strKeyPad ~ ('0' + padNr).to!char;
    arr[ALLEGRO_KEY_PAD_SLASH] = strKeyPad ~ "/";
    arr[ALLEGRO_KEY_PAD_ASTERISK] = strKeyPad ~ "*";
    arr[ALLEGRO_KEY_PAD_MINUS] = strKeyPad ~ strMinus;
    arr[ALLEGRO_KEY_PAD_PLUS] = strKeyPad ~ "+";
    arr[ALLEGRO_KEY_PAD_DELETE] = strKeyPad ~ strBackspace;
    arr[ALLEGRO_KEY_PAD_ENTER] = strKeyPad ~ strReturn;

    // geoo has drawn these symbols into DejaVu Sans:
    // \u27BF = LMB, \u27C0 = MMB, \u27C1 = RMB, \u27C2 = generic mouse
    arr[keyMMB] = "\u27C0";
    arr[keyRMB] = "\u27C1";
    arr[keyWheelUp] = "\u27C0\u2191"; // MMB, arrow up
    arr[keyWheelDown] = "\u27C0\u2193";

    return arr;
}();
