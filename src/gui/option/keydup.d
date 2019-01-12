module gui.option.keydup;

// This looks at several KeyButtons, checks whether any of those share
// keys, and sends a message to all registered KeyButtons whether the button
// has a shared keybind or not.

import std.algorithm;

import gui.button.key;

class KeyDuplicationWatcher {
private:
    KeyButton[] _watched;

public:
    void watch(KeyButton b)
    {
        if (! _watched.canFind(b))
            _watched ~= b;
    }

    void checkForDuplicateBindings()
    {
        foreach (KeyButton but; _watched)
            but.warnAboutDuplicateBindings(false);

        foreach (const size_t id, KeyButton button; _watched)
            foreach (other; _watched[id + 1 .. $])
                if (button.keySet.keysAsInts.any!(key =>
                    other.keySet.keysAsInts.canFind(key))
                ) {
                    button.warnAboutDuplicateBindings(true);
                    other.warnAboutDuplicateBindings(true);
                }
    }
}
