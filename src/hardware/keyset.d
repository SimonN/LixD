module hardware.keyset;

/* struct KeySet: An arbitrary set of keys (no duplicates) that can be
 * be merged and queried for presses.
 */

import std.algorithm;
import std.array;
import std.conv;
import std.exception; // assumeUnique
import std.string;
import std.uni;
import std.utf;

import basics.alleg5;
import hardware.keyboard;
import hardware.keynames;

struct KeySet {
private:
    immutable(int)[] _keys;

public:
    this(int singleKey)        { _keys = [ singleKey ]; }
    this(immutable(int)[] arr) { _keys = arr; }

    this(const typeof(this)[] sets...)
    {
        if (sets.length == 0)
            return;
        else if (sets.length == 1)
            _keys = sets[0]._keys;
        else if (sets.length == 2
            && (sets[0].empty || sets[1].empty)
        ) {
            _keys = sets[0].empty ? sets[1]._keys : sets[0]._keys;
        }
        else {
            int[] toSort;
            foreach (set; sets)
                toSort ~= set._keys;
            _keys = toSort.sort().uniq.array.assumeUnique;
        }
    }

    @property bool empty() const { return _keys.empty; }
    @property int  len()   const { return _keys.length & 0x7FFF_FFFFu; }

    @property keyTapped()   const { return _keys.any!(k => k.keyTapped);   }
    @property keyHeld()     const { return _keys.any!(k => k.keyHeld);     }
    @property keyReleased() const { return _keys.any!(k => k.keyReleased); }

    @property keyTappedAllowingRepeats() const
    {
        return _keys.any!(k => k.keyTappedAllowingRepeats);
    }

    void remove(int keyToRm)
    {
        _keys = _keys.filter!(k => k != keyToRm).array;
    }

    @property int kludgeFirstEntry() const
    {
        return _keys.empty ? 0 : _keys[0];
    }

    @property string nameLong() const {
        switch (_keys.length) {
            case 0:  return null;
            case 1:  return _keys[0].hotkeyNiceLong;
            case 2:  return _keys.map!(k => k.hotkeyNiceShort).join(", ");
            default: return _keys.map!(k => k.hotkeyNiceShort(3)).join(',');
        }
    }

    @property string nameShort() const {
        switch (_keys.length) {
            case 0:  return null;
            case 1:  return _keys[0].hotkeyNiceShort;
            case 2:  return _keys.map!(k => k.hotkeyNiceShort).join('/');
            default: return _keys.map!(k => k.hotkeyNiceShort(2)).join;
        }
    }
}

unittest {
    KeySet a = KeySet(4);
    KeySet b = KeySet(2);
    KeySet c = KeySet(5, 4, 3);
    assert (KeySet(a, b, c)._keys == [2, 3, 4, 5]);
    c.remove(4);
    c.remove(6);
    assert (c._keys == [3, 5]);
}

// ############################################################################
// ########################################################## private functions

private string hotkeyNiceShort(in int hotkey, in int maxLen = 3)
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

private string hotkeyNiceLong(in int hotkey)
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
        // \u27BF = LMB, \u27C0 = MMB, \u27C1 = RMB, \u27C2 = generic mouse
        return "\u27C0";
    else if (hotkey == keyRMB)
        return "\u27C1";
    else if (hotkey == keyWheelUp)
        // gear, arrow up
        return "\u27C0\u2191";
    else if (hotkey == keyWheelDown)
        return "\u27C0\u2193";
    assert (false,
        "Unhandled extra key %d >= ALLEGRO_KEY_MAX == %d. Please name key."
        .format(hotkey, ALLEGRO_KEY_MAX));
}
