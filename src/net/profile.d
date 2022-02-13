module net.profile;

import core.stdc.string;
import std.conv;
import std.string;

import net.handicap;
import net.plnr;
import net.style;
import net.versioning;

/*
 * Profile contains all mostly-constant information about a networking player.
 * The server keeps profiles.
 * The player sometimes asks the server to use a new profile for that player.
 */

alias Profile = Profile2016;

template isProfile(T) {
    enum bool isProfile = is(T == Profile2016) || is (T == Profile2022);
}

struct Profile2022 {
    mixin StyleSetter;

public:
    enum Feeling : ubyte {
        thinking = 0, // Frame 0 in menu_chk.I
        ready = 2, // Frame 2
        observing = 4 // Frame 4
    }
    Feeling feeling; // serializes to 1 byte
    string name; // serializes to 63+1 bytes; serialized[63] is always \0
    Version clientVersion; // serializes to 3 ints = 12 bytes
    Handicap handicap;
    /*
     * Room is not part of the profile.
     * Server tracks players' rooms in a struct { Profile, Room }.
     * Clients automatically only interact with others in their own room.
     * Clients already send room changes with a special packet ID number;
     * they don't send an updated profile as a room change.
     */

    Profile2016 toProfile2016withRoom(Room aRoom)
    {
        Profile2016 ret;
        ret.room = aRoom;
        ret.feeling = feeling;
        ret.style = this.style;
        ret.name = name;
        return ret;
    }
}

struct Profile2016 {
private:
    enum ubytes = 3;
    mixin StyleSetter;

public:
    static assert (isProfile!(typeof(this)));
    alias Feeling = Profile2022.Feeling;
    enum int len = ubytes + nameMaxLenIncludingNullbyte;
    enum nameMaxLenExcludingNullbyte = 30;
    enum nameMaxLenIncludingNullbyte = nameMaxLenExcludingNullbyte + 1;

    Room room;
    Feeling feeling;
    string name;

    @property Style style() const nothrow @nogc pure
    {
        assert (goodForMultiplayer(_style));
        return _style;
    }

    @property void style(in Style st) nothrow
    {
        _style = goodForMultiplayer(st) ? st : Style.red;
    }

    void setNotReady() @nogc
    {
        if (feeling == Feeling.ready)
            feeling = Feeling.thinking;
    }

    // If a player changes his profile from this to rhs, should we require
    // everybody in the room to mark themselves as not-ready?
    bool wouldForceAllNotReadyOnReplace(in typeof(this) rhs)
    {
        return this.style != rhs.style
            || this.room != rhs.room
            || this.name != rhs.name
            ||    (this.feeling == Feeling.observing)
                != (rhs.feeling == Feeling.observing);
    }

    void serializeTo(ref ubyte[len] buf) const nothrow
    {
        buf[0] = room;
        buf[1] = style;
        buf[2] = feeling;
        strncpy(cast (char*) (buf.ptr + ubytes), name.toStringz,
                                                 nameMaxLenExcludingNullbyte);
        buf[ubytes + nameMaxLenExcludingNullbyte] = '\0';
    }

    this(ref const(ubyte[len]) buf) nothrow
    {
        room = Room(buf[0]);
        try {
            style = buf[1].to!Style;
            feeling = buf[2].to!Feeling;
        }
        catch (Exception)
            { }
        if (buf[ubytes + nameMaxLenExcludingNullbyte] == '\0')
            name = fromStringz(cast (const char*) (buf.ptr + ubytes)).idup;
    }
}

private mixin template StyleSetter() {
    private Style _style = Style.red;

    public Style style() const pure nothrow @safe @nogc
    {
        assert (goodForMultiplayer(_style));
        return _style;
    }

    public void style(in Style st) pure nothrow @safe @nogc
    {
        _style = goodForMultiplayer(st) ? st : Style.red;
    }

    public static bool goodForMultiplayer(in Style st) pure nothrow @safe @nogc
    {
        return st >= Style.red && st < Style.max;
    }

    static assert (goodForMultiplayer(typeof(this).init._style));
};
