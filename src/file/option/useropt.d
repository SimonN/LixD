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
import hardware.keyset;

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
        bool keyTapped() { return _value.keyTapped; }
        bool keyHeld() { return _value.keyHeld; }
        bool keyReleased() { return _value.keyReleased; }
        bool keyTappedAllowingRepeats()
        {
            return _value.keyTappedAllowingRepeats;
        }
    }

protected:
    override void setImpl(Tag tag)
    {
        static if (is (T == KeySet)) {
            _value = KeySet();
            import std.variant;
            foreach (value; tag.values.filter!(v => v.convertsTo!int))
                _value = KeySet(_value, KeySet(value.get!int));
        }
        else {
            // If the tag's value type-mismatches, set _value to _value.
            _value = tag.getValue!T(_value);
        }
    }

    override void addValueTo(Tag tag) const
    {
        static if (is (T == int) || is (T == bool) || is (T == string)) {
            tag.add(Value(value));
        }
        else static if (is (T == KeySet))
            foreach (int scancode; _value.keysAsInts)
                tag.add(Value(scancode));
        else
            static assert (false);
    }

    override void revertToDefault() { _value = _defaultValue; }
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
        Lang.optionKeyMenuOkay, KeySet(45));
    assert (mykey.createTag().name == "myHotkeyKey");
    assert (mykey.createTag().values.front == 45);
    {
        Tag root = parseSource("myHotkeyKey 2 1 4 3 2 2 2\n");
        mykey.set(root.tags.front);
        import std.algorithm;
        assert (mykey.createTag().values.equal([1, 2, 3, 4]));
    }
    mykey = KeySet();
    assert (mykey.createTag().values.empty);
    mykey.set(new Tag("", "myHotkeyKey"));
    assert (mykey.createTag().values.empty);
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
