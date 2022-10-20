module net.profile;

/*
 * Profile contains all mostly-constant information about a networking player.
 * The server keeps profiles.
 * The player sometimes asks the server to use a new profile for that player.
 */


import std.bitmanip;
import std.conv;
import std.exception;
import std.encoding;
import std.string;

import net.handicap;
import net.plnr;
import net.style;
import net.versioning;

alias Profile = Profile2022;

struct Profile2022 {
private:
    mixin NameAsFixStr!48;

public:
    enum int len = 24 + Handicap.len + _name.len;

    enum Feeling : ubyte {
        thinking = 0, // Frame 0 in menu_chk.I
        ready = 2, // Frame 2
        observing = 4 // Frame 4
    }
    Style style;
    Feeling feeling;
    Version clientVersion;
    Handicap handicap;

    void setNotReady() @nogc
    {
        if (feeling == Feeling.ready)
            feeling = Feeling.thinking;
    }

    // If a player changes his profile from this to rhs, should we require
    // everybody in the room to mark themselves as not-ready?
    bool wouldForceAllNotReadyOnReplace(
        in typeof(this) rhs) const pure nothrow @safe @nogc
    {
        return style != rhs.style
            || name != rhs.name
            || handicap != rhs.handicap
            || (feeling == Feeling.observing)
                != (rhs.feeling == Feeling.observing);
    }

    Profile2016 to2016with(Room aRoom) const pure nothrow @safe @nogc
    {
        Profile2016 ret;
        ret.room = aRoom;
        ret.feeling = feeling;
        ret.style = this.style;
        ret.name = name;
        return ret;
    }

    void serializeTo(ref ubyte[len] buf) const pure nothrow @nogc
    {
        clientVersion.serializeTo(buf[0 .. 0+12]);
        buf[12] = style;
        buf[13] = feeling;
        buf[14 .. 24] = 0; // 10 placeholder bytes for future fields
        handicap.serializeTo(buf[24 .. 40]);
        _name.serializeTo(buf[40 .. 40 + _name.len]);
    }

    /*
     * Profile2022 may be of different length in different Lix versions.
     * We decode only the part that is known to both the sender and the
     * receiver. But we enforce the minimal (since 2022) length that all
     * senders and all receivers must support.
     */
    this(in ubyte[] buf) pure
    {
        enum minLenIn2022 = 20 + Handicap.len + _name.len;
        assert (len >= minLenIn2022);
        enforce (buf.length >= minLenIn2022);
        clientVersion = Version(buf[0 .. 0+12]);
        try {
            style = buf[12].to!Style;
            feeling = buf[13].to!Feeling;
        }
        catch (Exception) {
        }
        handicap = Handicap(buf[24 .. 40]);
        _name = typeof(_name)(buf[40 .. 40 + _name.len]);
        // If struct grows in future, check buf.length before each field.
    }
}

struct RoomListEntry2022 {
    Room room;
    int numInhabitants;
    Profile2022 owner;

    enum int len = 8 + owner.len;

    this(in ubyte[] buf) pure {
        enforce (buf.length >= len);
        room = Room(0xFF & buf[0 .. 2].bigEndianToNative!short);
        numInhabitants = buf[2 .. 4].bigEndianToNative!short;
        // buf[4 .. 8] unused, they're always 0.
        owner = Profile2022(buf[8 .. buf.length]);
    }

    void serializeTo(ref ubyte[len] buf) const pure nothrow @nogc
    {
        buf[0 .. 2] = nativeToBigEndian!short(room);
        buf[2 .. 4] = nativeToBigEndian!short(numInhabitants & 0x7FFF);
        buf[4 .. 8] = 0; // Unused, reserved.
        owner.serializeTo(buf[8 .. len]);
    }
}

struct Profile2016 {
private:
    mixin NameAsFixStr!31; // Yes, not 32. It's 30 good bytes + 1 nullbyte.

public:
    alias Feeling = Profile2022.Feeling;
    enum int len = 3 + _name.len;

    Room room;
    Style style;
    Feeling feeling;

    void setNotReady() @nogc
    {
        if (feeling == Feeling.ready)
            feeling = Feeling.thinking;
    }

    // If a player changes his profile from this to rhs, should we require
    // everybody in the room to mark themselves as not-ready?
    bool wouldForceAllNotReadyOnReplace(
        in typeof(this) rhs) const pure nothrow @safe @nogc
    {
        return this.style != rhs.style
            || this.room != rhs.room
            || this.name != rhs.name
            ||    (this.feeling == Feeling.observing)
                != (rhs.feeling == Feeling.observing);
    }

    Profile2022 to2022with(in Version ver) const pure nothrow @safe @nogc
    {
        Profile2022 ret;
        ret.clientVersion = ver;
        ret.feeling = feeling;
        ret.style = style;
        ret.name = name;
        return ret;
    }

    void serializeTo(ref ubyte[len] buf) const pure nothrow @nogc
    {
        buf[0] = room;
        buf[1] = style;
        buf[2] = feeling;
        _name.serializeTo(buf[3 .. 3 + _name.len]);
    }

    this(ref const(ubyte[len]) buf) pure
    {
        room = Room(buf[0]);
        try {
            style = buf[1].to!Style;
            feeling = buf[2].to!Feeling;
        }
        catch (Exception)
            { }
        _name = typeof(_name)(buf[3 .. 3 + _name.len]);
    }
}

private mixin template NameAsFixStr(int lenInclNull) {
    private FixStr!lenInclNull _name;

    public void name(in string source) pure nothrow @safe @nogc {
        _name = source;
    }
    public string name() const pure nothrow @safe @nogc {
        return _name.dString;
    }
}

/*
 * UTF-8 string with fixed length in bytes, including nullbyte.
 * len() returns the length in bytes of the serialized string,
 * which is always the max length including the null terminator.
 *
 * For the length of the D string, call FixStr.dString.length.
 *
 * In the serialization, the last byte at [len - 1] is always '\0'.
 * If the string is shorter than max length, there will be more nullbytes
 * before the guaranteed nullbyte at [len - 1].
 */
struct FixStr(int lenInclNull) if (lenInclNull > 0) {
private:
    string _dStr;

public:
    enum int len = lenInclNull;

    this(in string source) pure nothrow @safe { this.opAssign(source); }
    this(ref const(ubyte[len]) buf) pure
    {
        enforce(buf[len - 1] == '\0');
        _dStr = fromStringz(cast (const char*) (buf.ptr)).idup;
    }

    string dString() const pure nothrow @safe @nogc { return _dStr; }

    void opAssign(in string source) pure nothrow @safe @nogc
    {
        _dStr = source;
        trim();
    }

    void serializeTo(ref ubyte[len] buf) const pure nothrow @safe @nogc
    {
        assert (_dStr.length < len, "We must write at least 1 null byte.");
        foreach (size_t i, char c; _dStr) {
            buf[i] = c;
        }
        buf[_dStr.length .. len] = '\0';
    }

    string toString() const pure nothrow @safe @nogc
    {
        return _dStr;
    }

private:
    void trim() pure nothrow @safe @nogc
    {
        if (_dStr.length >= len) {
            _dStr = _dStr[0 .. len - 1];
        }
        while (! _dStr.isValid) {
            _dStr = _dStr[0 .. $-1];
        }
    }
}

unittest {
    import std.range;
    void repeatingTheseFourBytesOfUtf8Becomes(in string input, in int goalLen)
    {
        string ae = input.repeat(20).join;
        assert (ae.isValid);
        assert (ae.length == 80);

        auto fix = FixStr!64(ae);
        assert (fix.dString.isValid);
        assert (fix.dString.length == goalLen);
    }
    repeatingTheseFourBytesOfUtf8Becomes("abcd", 63);
    repeatingTheseFourBytesOfUtf8Becomes("èß", 62);
    repeatingTheseFourBytesOfUtf8Becomes("🌛", 60);
}

unittest {
    Profile2016 prof;
    prof.name = "Hello";
    prof.feeling = Profile2016.Feeling.observing;
    prof.style = Style.yellow;

    ubyte[Profile2016.len] buf;
    prof.serializeTo(buf);
    auto back = Profile2016(buf);
    assert (back.style == Style.yellow);
    assert (back.name == "Hello");
}
