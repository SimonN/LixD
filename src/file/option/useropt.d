module file.option.useropt;

/* This expresses a single global option settable by the user. This option
 * will be saved into the user file, not the all-user global config file.
 *
 * For the collection of all user options, including the methods to save/load
 * them all at once to/from the user file see module file.option instead.
 *
 * For the global config file, see file.option instead.
 *
 * Contract with file.language.Lang:
 * Each short option description (caption in the options menu)
 * is immediately followed in Lang by the long description, for the option bar.
 */

import std.algorithm;
import std.array;
import std.conv;
import std.string;

import file.filename;
import file.io;
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

    final @property Lang lang() const { return _lang; }

    final void set(in IoLine ioLine)
    {
        assert (ioLine.text1 == _userFileKey);
        setImpl(ioLine);
    }

    final IoLine ioLine() const
    {
        auto ioLine  = toIoLineExceptForKey();
        ioLine.text1 = _userFileKey;
        return ioLine;
    }

protected:
    abstract void setImpl(in IoLine ioLine);

    abstract IoLine toIoLineExceptForKey() const
    out (ret) {
        assert (ret);
        assert (ret.text1 == "");
    }
    body { return null; }

    abstract void revertToDefault();
}

// ############################################################################

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
    @property T defaultValue() const nothrow { return _defaultValue;   }
    @property T value()        const nothrow { return _value;          }
    @property T value(T aValue)      nothrow { return _value = aValue; }

    alias value this;

protected:
    override void setImpl(in IoLine ioLine)
    {
        static if (is (T == int))
            _value = ioLine.nr1;
        else static if (is (T == bool))
            _value = ioLine.nr1 > 0;
        else static if (is (T == string))
            _value = ioLine.text2;
        else static if (is (T == KeySet)) {
            _value = parseStringOfIntsIntoKeySet(ioLine.text2);
            // Backwards compatibility: Before Lix 0.6.2, we saved hotkeys
            // in '#' fields instead of '$' fields. Load such an old line.
            if (_value.empty && ioLine.type == '#')
                _value = KeySet(ioLine.nr1);
        }
        else
            static assert (false);
    }

    override IoLine toIoLineExceptForKey() const
    {
        static if (is (T == int))
            return IoLine.Hash(null, _value);
        else static if (is (T == bool))
            return IoLine.Hash(null, _value ? 1 : 0);
        else static if (is (T == string))
            return IoLine.Dollar(null, _value);
        else static if (is (T == KeySet))
            return IoLine.Dollar(null,
                _value.keysAsInts.map!(to!string).join(", "));
        else
            static assert (false);
    }

    override void revertToDefault() { _value = _defaultValue; }
}

unittest
{
    UserOption!int a = new UserOption!int("myUnittestKey", Lang.commonOk, 4);
    a.value = 5;
    assert (a.ioLine().text1 == "myUnittestKey");
    assert (a.ioLine().nr1 == 5);
}

private KeySet parseStringOfIntsIntoKeySet(string s) pure nothrow
{
    KeySet foldInts(KeySet keys, int i) { return KeySet(keys, KeySet(i)); }
    try
        return s.splitter(",")
            .map!(str => str.strip)
            .filter!(str => ! str.empty)
            .map!(str => str.to!int)
            .fold!foldInts(KeySet());
    catch (Exception)
        return KeySet();
}

unittest {
    UserOption!KeySet mykey = new UserOption!KeySet("myHotkeyKey",
        Lang.optionKeyMenuOkay, KeySet(45));
    assert (mykey.ioLine().text1 == "myHotkeyKey");
    assert (mykey.ioLine().text2 == "45");
    mykey.set(IoLine.Dollar("myHotkeyKey", "2, 1, ,, 4, 3"));
    assert (mykey.ioLine().text2 == "1, 2, 3, 4");
    mykey.value = KeySet();
    assert (mykey.ioLine().text2 == "");
    mykey.set(IoLine.Dollar("myHotkeyKey", ""));
    assert (mykey.ioLine().text2 == "");
}

// ############################################################################[

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
    @property Filename defaultValue() const nothrow { return _defaultValue; }
    @property Filename value()        const nothrow { return _value;        }
    @property Filename value(Filename fn) nothrow
    {
        _value = fn;
        return fn;
    }

    alias value this;

protected:
    override void setImpl(in IoLine ioLine)
    {
        _value = MutFilename(new VfsFilename(ioLine.text2));
    }

    override IoLine toIoLineExceptForKey() const
    {
        return IoLine.Dollar(null, _value.rootless);
    }

    override void revertToDefault() { _value = _defaultValue; }
}
