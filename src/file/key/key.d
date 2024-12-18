module file.key.key;

/*
 * A key is either
 *      the ID of a keyboard key,
 *      the ID of a mouse button,
 *      or a mouse wheel direction.
 *
 * See hardware.keyset.KeySet for the struct that you really bind to functions
 * in the options menu. A KeySet contains zero or more Keys.
 */

struct Key {
private:
    // A = 1, B = 2, ..., this runs through all Allegro-mapped keyboard keys.
    short _kb;

    // 1 = LMB, 2 = RMB, 3 = some third button, ...
    byte _mb;

    // 1 = Wheel up, 2 = Wheel down, >= 3 is invalid
    byte _wh;

public:
    static Key byA5KeyId(in int a5KeyId) pure nothrow @safe @nogc
    {
        return Key(a5KeyId & 0x7FFF, 0, 0);
    }

    static Key byMouseButtonId(in int mButtonId) pure nothrow @safe @nogc
    {
        return Key(0, mButtonId & 0x7F, 0);
    }

    enum Key lmb = Key(0, 1, 0);
    enum Key rmb = Key(0, 2, 0);
    enum Key mmb = Key(0, 3, 0);
    enum Key wheelUp = Key(0, 0, 1);
    enum Key wheelDown = Key(0, 0, 2);

    enum typeof(_kb) firstInvalidKeyboardKey = 240;
    enum typeof(_kb) firstInvalidMouseButton = 32;
    enum typeof(_wh) firstInvalidWheelDirection = 3;

    enum Type {
        keyboardKey,
        mouseButton,
        mouseWheelDirection,
    }

    Type type() const pure nothrow @safe @nogc
    {
        return _kb != 0 ? Type.keyboardKey
            :  _mb != 0 ? Type.mouseButton
            :  _wh != 0 ? Type.mouseWheelDirection : Type.keyboardKey;
    }

    bool isValid() const pure nothrow @safe @nogc
    {
        // Valid keys have one of _kb, _mb, _wh != 0 and the two others 0.
        final switch (type) {
        case Type.keyboardKey:
            return _kb > 0 && _mb == 0 && _wh == 0
                && _kb < firstInvalidKeyboardKey;
        case Type.mouseButton:
            return _kb == 0 && _mb > 0 && _wh == 0
                && _mb < firstInvalidMouseButton;
        case Type.mouseWheelDirection:
            return _kb == 0 && _mb == 0 && _wh > 0
                && _wh < firstInvalidWheelDirection;
        }
    }

    int opCmp(in typeof(this) rhs) const pure nothrow @safe @nogc
    {
        immutable typediff = sortingWeightOfTypes - rhs.sortingWeightOfTypes;
        return typediff != 0 ? typediff
            : sortingWeightOfInts - rhs.sortingWeightOfInts;
    }

    int keyboardKey() const pure nothrow @safe @nogc
    in { assert (type == Type.keyboardKey, "It's not a keyboard key"); }
    do { return _kb; }

    int mouseButton() const pure nothrow @safe @nogc
    in { assert (type == Type.mouseButton, "It's not a mouse button"); }
    do { return _mb; }

private:
    this(short a, byte b, byte c) pure nothrow @safe @nogc
    {
        _kb = a;
        _mb = b;
        _wh = c;
    }

    /*
     * Sort valid Keys first, according to their type.
     * After the valid Keys, sort Type.init. Only then sort other invalid Keys.
     */
    int sortingWeightOfTypes() const pure nothrow @safe @nogc
    {
        return isValid * -0x0010_0000
            + type
            + (this == Key.init) * -0x0000_1000;
    }

    int sortingWeightOfInts() const pure nothrow @safe @nogc
    {
        static assert (_kb.sizeof + _mb.sizeof < int.sizeof);
        return _kb
            + (_mb << (8 * _kb.sizeof))
            + (_wh << (8 * (_kb.sizeof + _mb.sizeof)));
    }
}

unittest {
    assert (! Key.init.isValid);
    assert (Key.init.type == Key.Type.keyboardKey,
        "Safety precaution. We return Key.init often as an invalid default.");
    assert (Key.lmb < Key.init);

    immutable garbage = Key(12, 34, 56);
    assert (! garbage.isValid);
    assert (Key.init < garbage);
}
