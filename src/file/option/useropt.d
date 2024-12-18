module file.option.useropt;

/* This expresses a single global option settable by the user. This option
 * will be saved into the user file, not the all-user global config file.
 *
 * For the collection of all user options, including the methods to save/load
 * them all at once to/from the user file see module file.option.allopts.
 *
 * Contract with file.language.Lang:
 * Each short option description (caption in the options menu)
 * is immediately followed in Lang by the long description, for the option bar.
 */

import std.algorithm;
import std.array;
import std.conv;
import std.string;

import sdlang;

import file.filename;
import file.language;
import file.key.key;
import file.key.set;
import hardware.keyboard; // Convenience: Call wasTapped directly on the option

abstract class AbstractUserOption {
private:
    immutable string _userFileKey;
    immutable Lang _lang; // translatable name for the options dialog

public:
    this(string aKey, Lang aLang)
    {
        _userFileKey = aKey;
        _lang = aLang;
    }

    final Lang lang() const pure nothrow @safe @nogc { return _lang; }

    final void set(Tag tag)
    {
        assert (tag.name == _userFileKey,
            "this.name == '" ~ _userFileKey
            ~ "' != tag.name == '" ~ tag.name ~ "'");
        setImpl(tag);
    }

    final Tag createTag() const
    {
        Tag tag = new Tag(null, _userFileKey);
        this.addValueTo(tag);
        return tag;
    }

protected:
    abstract void setImpl(Tag tag);
    abstract void revertToDefault();

    // To be called from the base class's createTag().
    // The child class should add their values to the tag, but keep the
    // tag's name as-is.
    abstract void addValueTo(Tag) const;
}



class UserOptionFilename : AbstractUserOption {
private:
    Filename _defaultValue;
    MutFilename _value;

public:
    this(string aKey, Lang aShort, Filename aValue)
    {
        super(aKey, aShort);
        _defaultValue = aValue;
        _value        = aValue;
    }

    nothrow @nogc @safe {
        Filename defaultValue() const { return _defaultValue; }
        Filename value()        const { return _value; }
        Filename opAssign(Filename aValue)
        {
            _value = aValue;
            return _value;
        }
    }

protected:
    override void setImpl(Tag tag)
    {
        _value = MutFilename(new VfsFilename(tag.getValue!string));
    }

    override void addValueTo(Tag tag) const
    {
        tag.add(Value(_value.rootless));
    }

    override void revertToDefault() { _value = _defaultValue; }
}



class UserOption(T) : AbstractUserOption
    if (is (T == int) || is (T == bool) || is (T == string) || is (T == KeySet)
) {
private:
    immutable T _defaultValue;
    T _value;

public:
    this(string aKey, Lang aShort, T aValue)
    {
        super(aKey, aShort);
        _defaultValue = aValue;
        _value        = aValue;
    }

    nothrow @nogc @safe {
        T defaultValue() const { return _defaultValue; }
        T value()        const { return _value; }
        T opAssign(const(T) aValue) { return _value = aValue; }
    }

    static if (is (T == KeySet)) {
        const nothrow @safe @nogc:
        bool wasTapped() { return _value.wasTapped; }
        bool isHeld() { return _value.isHeld; }
        bool wasReleased() { return _value.wasReleased; }
        bool wasTappedOrRepeated() { return _value.wasTappedOrRepeated; }
    }

protected:
    override void setImpl(Tag tag)
    {
        static if (is (T == KeySet)) {
            _value = KeySet();
            foreach (value; tag.values.filter!(v => v.convertsTo!int)) {
                const Key k = old2024IntToKey(value.get!int);
                _value = KeySet(_value, KeySet(k));
            }
            foreach (attr; tag.attributes) {
                const Key k = attributeToKey(attr);
                _value = KeySet(_value, KeySet(k));
            }
        }
        else {
            /*
             * Set _value to the first (and, with hope, only) tag. If the
             * tag's value doesn't exist or type-mismatches, _value = _value.
             */
            _value = tag.getValue!T(_value);
        }
    }

    override void addValueTo(Tag tag) const
    {
        static if (is (T == int) || is (T == bool) || is (T == string)) {
            tag.add(Value(value));
        }
        else static if (is (T == KeySet)) {
            foreach (Key keyToExport; _value[]) {
                tag.add2025(keyToExport);
                tag.maybeAdd2024BackCompat(keyToExport);
            }
        }
        else
            static assert (false);
    }

    override void revertToDefault() { _value = _defaultValue; }
}

private:

// Keywords for import/export of options.
enum kwMButton = "mouseButton";
enum kwWheel = "mouseWheel";
enum kwWhUp = "up";
enum kwWhDown = "down";

// Remove this in 2028, and remove all usages here then.
enum old2024AllegroKeyMax = 227;

/*
 * In 2028, replace calls to old2024IntToKey with calls to Key.byA5KeyId.
 */
Key old2024IntToKey(in int from2024) pure nothrow @safe @nogc
{
    return from2024 == old2024AllegroKeyMax ? Key.mmb
        : from2024 == old2024AllegroKeyMax + 1 ? Key.rmb
        : from2024 == old2024AllegroKeyMax + 2 ? Key.wheelUp
        : from2024 == old2024AllegroKeyMax + 3 ? Key.wheelDown
        : Key.byA5KeyId(from2024);
    // KeySet is responsible for discarding invalid Keys that we produce here.
}

Key attributeToKey(Attribute attr)
{
    if (attr.name == kwMButton && attr.value.convertsTo!int) {
        immutable k = Key.byMouseButtonId(attr.value.get!int);
        // Don't allow LMB, it's not mappable in the options menu either.
        return k != Key.lmb ? k : Key.init;
    }
    if (attr.name == kwWheel && attr.value.convertsTo!string) {
        return attr.value.get!string == kwWhUp ? Key.wheelUp : Key.wheelDown;
    }
    return Key.init;
}

void add2025(ref Tag target, in Key keyToExport)
{
    final switch (keyToExport.type) {
    case Key.Type.keyboardKey:
        target.add(Value(keyToExport.keyboardKey));
        return;
    case Key.Type.mouseButton:
        target.add(new Attribute(kwMButton, Value(keyToExport.mouseButton)));
        return;
    case Key.Type.mouseWheelDirection:
        target.add(new Attribute(kwWheel,
            Value(keyToExport == Key.wheelUp ? kwWhUp : kwWhDown)));
        return;
    }
}

void maybeAdd2024BackCompat(ref Tag target, in Key keyToExport)
{
    int backCompat
        = keyToExport == Key.mmb ? old2024AllegroKeyMax
        : keyToExport == Key.rmb ? old2024AllegroKeyMax + 1
        : keyToExport == Key.wheelUp ? old2024AllegroKeyMax + 2
        : keyToExport == Key.wheelDown ? old2024AllegroKeyMax + 3
        : 0;
    if (backCompat == 0) {
        return;
    }
    target.add(Value(backCompat));
}

unittest
{
    UserOption!int a = new UserOption!int("myUnittestKey", Lang.commonOk, 4);
    a = 5;
    assert (a.createTag().name == "myUnittestKey");
    assert (a.createTag().values.front == 5);
}

unittest {
    UserOption!KeySet mykey = new UserOption!KeySet("myHotkeyKey",
        Lang.optionKeyMenuOkay, KeySet(Key.byA5KeyId(45)));
    assert (mykey.createTag().name == "myHotkeyKey");
    assert (mykey.createTag().values.front == 45);
    {
        Tag root = parseSource("myHotkeyKey 2 1 4 3 2 2 2\n");
        mykey.set(root.tags.front);
        assert (mykey.createTag().values.equal([1, 2, 3, 4]));
    }
    mykey = KeySet();
    assert (mykey.createTag().values.empty);
    mykey.set(new Tag("", "myHotkeyKey"));
    assert (mykey.createTag().values.empty);
}

unittest {
    UserOption!KeySet ourOpt = new UserOption!KeySet("myMouseButtonOption",
        Lang.optionKeyMenuOkay, KeySet(Key.byMouseButtonId(7)));
    assert (ourOpt.createTag().values.empty);
    assert (ourOpt.createTag().attributes.length == 1);
    {
        auto attr = ourOpt.createTag().attributes.front;
        assert (attr.name == "mouseButton");
        assert (attr.value == 7);
    }
    {
        Tag root = parseSource(
            "myMouseButtonOption mouseButton=10 mouseButton=9\n");
        ourOpt.set(root.tags.front);
    }
    assert (ourOpt.value == KeySet(
        KeySet(Key.byMouseButtonId(9)), KeySet(Key.byMouseButtonId(10))));
}

unittest {
    UserOption!KeySet ourOpt = new UserOption!KeySet("myMouseButtonOption",
        Lang.optionKeyMenuOkay, KeySet(Key.rmb));
    assert (ourOpt.createTag().values.length == 1,
        "This is the 2024 fallback: We export MMB, RMB, wheel up/down as"
        ~ " keyboard integers that Lix versions from 2024 can understand."
        ~ " In 2028, require .length == 0 here.");
    auto attrs = ourOpt.createTag().attributes;
    assert (attrs.length == 1);
    assert (attrs[0].name == kwMButton);
    assert (attrs[0].value.get!int == 2);
}

unittest {
    UserOption!KeySet ourOpt = new UserOption!KeySet("myMouseWheelOption",
        Lang.optionKeyMenuOkay, KeySet(Key.wheelDown));
    assert (ourOpt.createTag().values.length == 1,
        "This is the 2024 fallback: We export MMB, RMB, wheel up/down as"
        ~ " keyboard integers that Lix versions from 2024 can understand."
        ~ " In 2028, require .length == 0 here.");
    auto attrs = ourOpt.createTag().attributes;
    assert (attrs.length == 1);
    assert (attrs[0].name == kwWheel);
    assert (attrs[0].value.get!string == kwWhDown);
}
