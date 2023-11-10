module hardware.keyset;

/* struct KeySet: An arbitrary set of keys (no duplicates) that can be
 * be merged and queried for presses.
 */

import std.algorithm;
import std.array;
import std.conv;
import std.exception; // assumeUnique

import basics.alleg5;
import hardware.keyboard;

struct KeySet {
private:
    immutable(int)[] _keys;

public:
    this(int singleKey) pure { _keys = [ singleKey ]; }

    this(const typeof(this)[] sets...) pure
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

    bool empty() const pure nothrow @safe @nogc { return _keys.empty; }
    int len() const pure nothrow @safe @nogc
    {
        return _keys.length & 0x7FFF_FFFFu;
    }

    bool keyTapped()   const { return _keys.any!(k => k.keyTapped);   }
    bool keyHeld()     const { return _keys.any!(k => k.keyHeld);     }
    bool keyReleased() const { return _keys.any!(k => k.keyReleased); }
    bool keyTappedAllowingRepeats() const
    {
        return _keys.any!(k => k.keyTappedAllowingRepeats);
    }

    void remove(int keyToRm)
    {
        _keys = _keys.filter!(k => k != keyToRm).array;
    }

    immutable(int)[] keysAsInts() const pure nothrow @safe @nogc
    {
        return _keys;
    }
}

unittest {
    KeySet a = KeySet(4);
    KeySet b = KeySet(2);
    KeySet c = KeySet(KeySet(4), KeySet(5), KeySet(3));
    assert (KeySet(a, b, c)._keys == [2, 3, 4, 5]);
    c.remove(4);
    c.remove(6);
    assert (c._keys == [3, 5]);
}
