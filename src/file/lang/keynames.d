module file.lang.keynames;

import std.algorithm;
import std.array;
import std.conv;
import std.uni;
import std.utf;

import basics.alleg5; // The scancode enum
import file.lang.enum_;
import hardware.keyenum;
import hardware.keyset;

package struct KeyNamesForOneLanguage {
private:
    /*
     * We'll fill this from three possible sources.
     * First choice: Outside calls to addTranslatedKeyName(),
     * second choiec: My fancy unicode key names,
     * third choice: Allegro 5's English key names.
     *
     * Ask it via nameLong() or nameShort().
     */
    string[hardwareKeyboardArrLen] _keyNames;

public:
    string nameLong(in KeySet set) {
        switch (set.len) {
            case 0: return null;
            case 1: return hotkeyNiceLong(set.keysAsInts[0]);
            default: return nameShort(set);
        }
    }

    string nameShort(in KeySet set) {
        switch (set.len) {
            case 0: return null;
            case 1: return hotkeyNiceShort(set.keysAsInts[0], 3);
            case 2: return set.keysAsInts
                .map!(k => hotkeyNiceShort(k, 3)).join(' ');
            default: return set.keysAsInts
                .map!(k => hotkeyNiceShort(k, 2)).join;
        }
    }

    /*
     * First choice: A key name wanted from outside.
     * Usually, these key names are language-dependent names from the
     * translations files.
     */
    void addTranslatedKeyName(in Lang forScancode, in string customName)
    {
        immutable int scancodeInArray = langToA5ScancodeOrZero(forScancode);
        if (scancodeInArray < 1) {
            return;
        }
        _keyNames[scancodeInArray] = customName;
    }

private:
    string hotkeyNiceShort(in int hotkey, in int maxLen)
    {
        string s = hotkeyNiceLong(hotkey);
        try {
            // return up to maxLen unicode chars of s
            int index = 0;
            int charsEaten = 0;
            while (index < s.length && charsEaten < maxLen) {
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
        assert (hotkey >= 0);
        assert (hotkey < hardwareKeyboardArrLen);
        if (_keyNames[hotkey] == null) {
            _keyNames[hotkey] = createFancyDefaultKeyNameOrNullFor(hotkey);
            if (_keyNames[hotkey] == null) {
                _keyNames[hotkey] = createAllegroDefaultKeyNameFor(hotkey);
            }
        }
        return _keyNames[hotkey];
    }

    // Third choice: Allegro's English key name.
    static string createAllegroDefaultKeyNameFor(in int hotkey)
    {
        if (! al_is_keyboard_installed())
            return null;
        string s = al_keycode_to_name(hotkey).to!string;
        string ret;
        foreach (size_t i, dchar c; s) {
            if (i == 0) {
                ret ~= std.uni.toUpper(c);
            }
            else if (c != '_') {
                ret ~= std.uni.toLower(c);
            }
        }
        // On Windows Allgero, unknown keys are called KEY79. We have changed
        // this to Key97, but still, remove uninformative bloat.
        if (ret.length >= 3 && ret[0] == 'K' && ret[1] == 'e' && ret[2] == 'y')
            ret = ret[3 .. $];
        return ret;
    }

    // Second choice: My language-independent unicode key name.
    static string createFancyDefaultKeyNameOrNullFor(in int hotkey)
    {
        enum strKeyPad = "\U0001D356"; // Tetagram For Fostering, 3x4 squares
        enum strBackspace = "\u232B"; // Erase to the left
        enum strDelete = "\u2326"; // Erase to the right
        enum strReturn = "\u21B2"; // Down arrow with tip towards the left
        enum strMinus = "\u2212"; // unicode minus

        switch (hotkey) {
            case ALLEGRO_KEY_TILDE: return "~";
            case ALLEGRO_KEY_MINUS: return strMinus;
            case ALLEGRO_KEY_EQUALS: return "=";
            case ALLEGRO_KEY_BACKSPACE: return strBackspace;
            case ALLEGRO_KEY_DELETE: return strDelete;
            case ALLEGRO_KEY_TAB: return "\u21B9"; // Two arrows with bars
            case ALLEGRO_KEY_ENTER: return strReturn;
            case ALLEGRO_KEY_LEFT: return "\u2190";
            case ALLEGRO_KEY_RIGHT: return "\u2192";
            case ALLEGRO_KEY_UP: return "\u2191";
            case ALLEGRO_KEY_DOWN: return "\u2193";

            case ALLEGRO_KEY_FULLSTOP: return ".";
            case ALLEGRO_KEY_COMMA: return ",";
            case ALLEGRO_KEY_SLASH: return "/";
            case ALLEGRO_KEY_OPENBRACE: return "[";
            case ALLEGRO_KEY_CLOSEBRACE: return "]";
            case ALLEGRO_KEY_SEMICOLON: return ";";
            case ALLEGRO_KEY_QUOTE: return "\"";

            case ALLEGRO_KEY_PAD_SLASH: return strKeyPad ~ "/";
            case ALLEGRO_KEY_PAD_ASTERISK: return strKeyPad ~ "*";
            case ALLEGRO_KEY_PAD_MINUS: return strKeyPad ~ strMinus;
            case ALLEGRO_KEY_PAD_PLUS: return strKeyPad ~ "+";
            case ALLEGRO_KEY_PAD_DELETE: return strKeyPad ~ strDelete;
            case ALLEGRO_KEY_PAD_ENTER: return strKeyPad ~ strReturn;

            case ALLEGRO_KEY_PAD_0: return strKeyPad ~ "0";
            case ALLEGRO_KEY_PAD_1: return strKeyPad ~ "1";
            case ALLEGRO_KEY_PAD_2: return strKeyPad ~ "2";
            case ALLEGRO_KEY_PAD_3: return strKeyPad ~ "3";
            case ALLEGRO_KEY_PAD_4: return strKeyPad ~ "4";
            case ALLEGRO_KEY_PAD_5: return strKeyPad ~ "5";
            case ALLEGRO_KEY_PAD_6: return strKeyPad ~ "6";
            case ALLEGRO_KEY_PAD_7: return strKeyPad ~ "7";
            case ALLEGRO_KEY_PAD_8: return strKeyPad ~ "8";
            case ALLEGRO_KEY_PAD_9: return strKeyPad ~ "9";

            // geoo has drawn these symbols into DejaVu Sans:
            // \u27BF = LMB, \u27C0 = MMB, \u27C1 = RMB, \u27C2 = generic mouse
            case keyMMB: return "\u27C0";
            case keyRMB: return "\u27C1";
            case keyWheelUp: return "\u27C0\u2191"; // MMB, arrow up
            case keyWheelDown: return "\u27C0\u2193";
            default: return null;
        }
    }

    static int langToA5ScancodeOrZero(in Lang lang) pure nothrow @safe @nogc
    {
        switch (lang) {
            case Lang.keyboardKeyCapsLock: return ALLEGRO_KEY_CAPSLOCK;
            case Lang.keyboardKeyLeftShift: return ALLEGRO_KEY_LSHIFT;
            case Lang.keyboardKeyRightShift: return ALLEGRO_KEY_RSHIFT;
            case Lang.keyboardKeyLeftCtrl: return ALLEGRO_KEY_LCTRL;
            case Lang.keyboardKeyRightCtrl: return ALLEGRO_KEY_RCTRL;
            case Lang.keyboardKeyLeftAlt: return ALLEGRO_KEY_ALT;
            case Lang.keyboardKeyRightAlt: return ALLEGRO_KEY_ALTGR;
            case Lang.keyboardKeyLeftWin: return ALLEGRO_KEY_LWIN;
            case Lang.keyboardKeyRightWin: return ALLEGRO_KEY_RWIN;
            case Lang.keyboardKeyContextMenu: return ALLEGRO_KEY_MENU;

            case Lang.keyboardKeyInsert: return ALLEGRO_KEY_INSERT;
            case Lang.keyboardKeyDelete: return ALLEGRO_KEY_DELETE;
            case Lang.keyboardKeyHome: return ALLEGRO_KEY_HOME;
            case Lang.keyboardKeyEnd: return ALLEGRO_KEY_END;
            case Lang.keyboardKeyPageUp: return ALLEGRO_KEY_PGUP;
            case Lang.keyboardKeyPageDown: return ALLEGRO_KEY_PGDN;
            case Lang.keyboardKeyPrint: return ALLEGRO_KEY_PRINTSCREEN;
            case Lang.keyboardKeyScrollLock: return ALLEGRO_KEY_SCROLLLOCK;
            case Lang.keyboardKeyPause: return ALLEGRO_KEY_PAUSE;
            case Lang.keyboardKeyNumLock: return ALLEGRO_KEY_NUMLOCK;
            default: return 0;
        }
    }
}
