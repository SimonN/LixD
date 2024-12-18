module file.key.set;

/* struct KeySet: An arbitrary set of keys (no duplicates) that can be
 * be merged and queried for presses.
 */

import std.algorithm;
import std.array;
import std.conv;
import std.exception : assumeUnique;

import file.key.key;

struct KeySet {
private:
    /*
     * A nogc implementation of a set, with anemic maximum capacity.
     * When you reach an invalid entry (! Key.isValid), e.g., Key.init,
     * you should ignore it and all subsequent entries. It's allowed for
     * the set to contain only valid entries and no terminating invalid one.
     */
    static assert (! Key.init.isValid);
    Key[6] _keys;

public:
pure:
nothrow:
@nogc:
@safe:
    this(Key k)
    {
        if (k.isValid) {
            _keys[0] = k;
        }
    }

    this(in typeof(this) first, in typeof(this) second)
    {
        _keys = first._keys;
        for (int i = 0; i < second.len; ++i) {
            immutable Key k = second[i];
            assert (k.isValid);
            if (len < _keys.length && ! _keys[].canFind(k)) {
                _keys[len] = k;
            }
        }
        _keys[].sort;
    }

    bool empty() const { return ! _keys[0].isValid; }

    int len() const
    {
        for (int i = 0; i < _keys.length; ++i) {
            if (! _keys[i].isValid) {
                return i;
            }
        }
        return _keys.length & 0x7FFF_FFFF;
    }

    KeySet butWithOneKeyFewer() const
    {
        KeySet ret = this;
        ret._keys[0] = Key.init;
        ret._keys[].sort;
        assert (! ret._keys[$-1].isValid,
            "Invalid keys sort at the end, and we introduced one");
        return ret;
    }

    const(Key)[] opIndex() const return
    {
        return _keys[0 .. len];
    }

    const(Key) opIndex(in int i) const
    {
        return _keys[i];
    }
}

unittest {
    Key f(in int i) { return Key.byA5KeyId(i); }

    KeySet a = KeySet(f(4));
    KeySet b = KeySet(f(2));
    KeySet c = KeySet(KeySet(KeySet(f(4)), KeySet(f(5))), KeySet(f(3)));
    auto mergedABC = KeySet(a, KeySet(b, c));
    auto mergedCAB = KeySet(c, KeySet(a, b));

    assert (mergedABC == mergedCAB);
    assert (mergedABC[].equal([
        Key.byA5KeyId(2),
        Key.byA5KeyId(3),
        Key.byA5KeyId(4),
        Key.byA5KeyId(5)]));

    c = c.butWithOneKeyFewer;
    assert (c[].equal([
        Key.byA5KeyId(4),
        Key.byA5KeyId(5)]));
}
