module hardware.keynames;

import std.conv;
import std.string;
import std.uni;
import std.utf;

import basics.alleg5;

// Assignable as hotkeys
enum keyMMB       = ALLEGRO_KEY_MAX;
enum keyRMB       = ALLEGRO_KEY_MAX + 1;
enum keyWheelUp   = ALLEGRO_KEY_MAX + 2;
enum keyWheelDown = ALLEGRO_KEY_MAX + 3;

// Constant for hardware.keyboard. Keep this as max(above names) + 1.
enum hardwareKeyboardArrLen = ALLEGRO_KEY_MAX + 4;

string hotkeyNiceBrackets(in int hotkey)
{
    if (hotkey <= 0 || ! al_is_keyboard_installed())
        return null;
    return "[" ~ hotkeyNiceShort(hotkey) ~ "]";
}

string hotkeyNiceShort(in int hotkey)
{
    string s = hotkeyNiceLong(hotkey);
    try {
        // return up to 3 unicode chars of s
        int index = 0;
        int charsEaten = 0;
        while (index < s.length && charsEaten < 3) {
            index += s.stride(index);
            ++charsEaten;
        }
        return s[0 .. index];
    }
    catch (Exception)
        return s;
}

string hotkeyNiceLong(in int hotkey)
{
    if (hotkey <= 0 || ! al_is_keyboard_installed())
        return null;
    else if (hotkey < ALLEGRO_KEY_MAX) {
        string s = al_keycode_to_name(hotkey).to!string;
        string ret;
        foreach (int i, dchar c; s) {
            if (i == 0) ret ~= std.uni.toUpper(c);
            else if (c != '_') ret ~= c;
        }
        return ret;
    }
    else if (hotkey == keyMMB)
        // open parallelogram, filled one, open one
        return "\u25B1\u25B0\u25B1";
    else if (hotkey == keyRMB)
        return "\u25B1\u25B1\u25B0";
    else if (hotkey == keyWheelUp)
        // gear, arrow up
        return "\u2699\u2191";
    else if (hotkey == keyWheelDown)
        return "\u2699\u2193";
    assert (false,
        "Unhandled extra key %d >= ALLEGRO_KEY_MAX == %d. Please name key."
        .format(hotkey, ALLEGRO_KEY_MAX));
}
