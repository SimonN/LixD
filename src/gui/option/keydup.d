module gui.option.keydup;

// This looks at several KeyButtons, checks whether any of those share
// keys, and sends a message to all registered KeyButtons whether the button
// has a shared keybind or not.

import std.algorithm;

import gui.button.key;

class KeyDuplicationWatcher : WatcherOfKB {
private:
    // _hasDupe[i] is true iff _watched[i] bites with some _watched[j].
    WatchedKB[] _watched;
    bool[] _hasDupe;

public:
    void watch(WatchedKB b)
    in {
        assert (! _watched.canFind(b), "Don't register b twice.");
    }
    do {
        _watched ~= b;
        _hasDupe ~= false;
        b.registerWatcher(this);
        scanForDuplicates();
    }

    bool areDuplicatesKnownFor(in WatchedKB b) const pure nothrow @safe @nogc
    {
        immutable id = _watched.countUntil!"a is b"(b);
        assert (id >= 0, "Don't ask about a non-watched button.");
        return _hasDupe[id];
    }

    /*
     * After a button has changed its keys, it should tell us to
     * scanForDuplicates. This merely records findings in _hasDupe[],
     * it doesn't tell any buttons. Buttons must ask us later for results.
     */
    void scanForDuplicates()
    {
        for (size_t id = 0; id < _watched.length; ++id) {
            if (_hasDupe[id]) {
                _hasDupe[id] = false;
                _watched[id].rememberToAskWatcher;
            }
        }
        for (size_t idA = 0; idA < _watched.length; ++idA) {
            for (size_t idB = idA + 1; idB < _watched.length; ++idB) {
                if (_watched[idA].keySet.intersects(_watched[idB].keySet)) {
                    _hasDupe[idA] = true;
                    _watched[idA].rememberToAskWatcher;
                    _hasDupe[idB] = true;
                    _watched[idB].rememberToAskWatcher;
                }
            }
        }
    }
}

