module net.structs;

/* The client and server exchange messages via enet. These messages are
 * manually serialized and deserialized structs, different structs for
 * different messages.
 *
 * Manual memory management: When a struct returns an ENetPacket*, then
 * it has asked enet to allocate the packet. When you send or broadcast
 * that packet, enet will deallocate it for you.
 *
 * Structs that read or write from bare buffers don't allocate.
 */

import core.stdc.string;
import std.algorithm;
import std.bitmanip;
import std.conv;
import std.exception;
import std.range;
import std.string;

import derelict.enet.enet;

import net.enetglob;
import net.packetid;
import net.phyu;
import net.style;
import net.versioning;

// make function interfaces more typesafe
struct PlNr {
    enum int len = 1;
    enum int maxExclusive = 255;
    ubyte n;
    alias n this;
}

struct Room {
    enum int len = 1;
    enum int maxExclusive = 255;
    ubyte n;
    alias n this;
}

struct PacketHeader {
    enum len = 2;
    ubyte packetID;
    PlNr plNr;

    void serializeTo(ref ubyte[len] buf) const nothrow @nogc
    {
        buf[0] = packetID;
        buf[1] = plNr;
    }

    this(ref const(ubyte[len]) buf) nothrow @nogc
    {
        packetID = buf[0];
        plNr = PlNr(buf[1]);
    }

    ENetPacket* createPacket() const nothrow @nogc
    {
        auto ret = .createPacket(len);
        serializeTo(ret.data[0 .. len]);
        return ret;
    }

    this(const(ENetPacket*) p)
    {
        enforce(p.dataLength >= len);
        this(p.data[0 .. len]);
    }
}

struct SomeoneDisconnectedPacket {
    PacketHeader header;
    alias header this;

    this(const(ENetPacket*) p) { header = PacketHeader(p); }
}

struct Profile {
private:
    enum ubytes = 3;
    Style _style = Style.red;
    static assert (goodForMultiplayer(Profile.init._style));

public:
    enum int len = ubytes + netPlayerNameMaxLen + 1; // null-terminated string
    enum Feeling : ubyte { thinking = 0, ready = 2, observing = 4 }
    // 0, 2, 4: These numbers specify frames in menu_chk.I.

    Room room;
    Feeling feeling;
    string name;

    @property Style style() const nothrow
    {
        assert (goodForMultiplayer(_style));
        return _style;
    }

    @property void style(in Style st) nothrow
    {
        _style = goodForMultiplayer(st) ? st : Style.red;
    }

    static bool goodForMultiplayer(in Style st) nothrow
    {
        return st >= Style.red && st < Style.max;
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
                                                 netPlayerNameMaxLen);
        buf[ubytes + netPlayerNameMaxLen] = '\0';
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
        if (buf[ubytes + netPlayerNameMaxLen] == '\0')
            name = fromStringz(cast (char*) (buf.ptr + ubytes)).idup;
    }
}

// Give this function a range with all profiles from the same room
bool mayRoomDeclareReady(R)(R range)
    if (isForwardRange!R && is (ElementType!R : const (Profile)))
{
    // all must be in same room that isn't the lobby
    if (range.any!(pro => pro.room != range.front.room || pro.room == 0))
        return false;
    return range.walkLength >= 2
        && range.any!(pro => pro.feeling != Profile.Feeling.observing);
}

struct HelloPacket {
    enum len = header.len + fromVersion.len + profile.len;
    PacketHeader header;
    Version fromVersion;
    Profile profile;

    ENetPacket* createPacket() const nothrow
    in { assert (header.packetID == PacketCtoS.hello); }
    out (ret) { assert (ret.data[0] == PacketCtoS.hello); }
    body {
        auto ret = .createPacket(len);
        header.serializeTo(ret.data[0 .. header.len]);
        fromVersion.serializeTo(ret.data[header.len
                                      .. header.len + fromVersion.len]);
        profile.serializeTo(ret.data[len - profile.len .. len]);
        return ret;
    }

    this(const(ENetPacket*) p)
    {
        enforce(p.dataLength == len);
        header = PacketHeader(p.data[0 .. header.len]);
        enforce(header.packetID == PacketCtoS.hello);
        fromVersion = Version(p.data[header.len .. header.len + Version.len]);
        profile = Profile(p.data[len - profile.len .. len]);
    }
}

struct HelloAnswerPacket {
    enum len = header.len + serverVersion.len;
    PacketHeader header;
    Version serverVersion;

    ENetPacket* createPacket() const nothrow
    {
        auto ret = .createPacket(len);
        header.serializeTo(ret.data[0 .. header.len]);
        serverVersion.serializeTo(ret.data[len - serverVersion.len .. len]);
        return ret;
    }

    this(const(ENetPacket*) p)
    {
        enforce(p.dataLength == len);
        header = PacketHeader(p.data[0 .. header.len]);
        serverVersion = Version(p.data[len - serverVersion.len .. len]);
    }
}

struct SomeoneMisfitsPacket {
    enum len = header.len + misfitProfile.len + 2 * Version.len;
    PacketHeader header;
    Profile misfitProfile;
    Version misfitVersion;
    Version serverVersion;

    private enum mid = header.len + misfitProfile.len;

    ENetPacket* createPacket() const nothrow
    {
        auto ret = .createPacket(len);
        header.serializeTo(ret.data[0 .. header.len]);
        misfitProfile.serializeTo(ret.data[header.len .. mid]);
        misfitVersion.serializeTo(ret.data[mid .. mid + misfitVersion.len]);
        serverVersion.serializeTo(ret.data[len - serverVersion.len .. len]);
        return ret;
    }

    this(const(ENetPacket*) p)
    {
        enforce(p.dataLength == len);
        header = PacketHeader(p.data[0 .. header.len]);
        misfitProfile = Profile(p.data[header.len .. mid]);
        misfitVersion = Version(p.data[mid .. mid + misfitVersion.len]);
        serverVersion = Version(p.data[len - serverVersion.len .. len]);
    }
}

struct ProfilePacket {
    enum len = header.len + profile.len;
    PacketHeader header;
    Profile profile;

    ENetPacket* createPacket() const nothrow
    {
        auto ret = .createPacket(len);
        header.serializeTo(ret.data[0 .. header.len]);
        profile.serializeTo(ret.data[len - profile.len .. len]);
        return ret;
    }

    this(const(ENetPacket*) p)
    {
        enforce(p.dataLength == len);
        header = PacketHeader(p.data[0 .. header.len]);
        profile = Profile(p.data[len - profile.len .. len]);
    }
}

alias ProfileListPacket = ListPacket!PlNr;
alias RoomListPacket = ListPacket!Room;

struct ListPacket(Index)
    if (is (Index == PlNr) || is (Index == Room))
{
    PacketHeader header;
    Index[] indices; // structure of arrays, indices[i] belongs to profiles[i]
    Profile[] profiles;

    @property int len() const nothrow
    {
        int numProfiles = profiles.length & 0x7FFF;
        return header.len + (Index.len + Profile.len) * numProfiles;
    }

    private @property int mid() const nothrow
    {
        return header.len + Index.len * (indices.length & 0x7FFF);
    }

    ENetPacket* createPacket() const nothrow
    out (ret) {
        assert (indices.length == 0 || ret.data[header.len] == indices[0]);
    }
    body {
        auto ret = .createPacket(len);
        header.serializeTo(ret.data[0 .. header.len]);

        foreach (i, Index; indices) {
            static assert (Index.len == 1);
            ret.data[header.len + i] = Index;
        }
        assert (indices.length == 0 || ret.data[header.len] == indices[0]);
        foreach (i, profile; profiles) {
            // profile.serializeTo expects the slice length at compile-time.
            // I don't know how to create a fixed-length D array from a pointer
            // and the length, so I do it with this otherwise-unecessary copy.
            ubyte[Profile.len] temp;
            profile.serializeTo(temp);
            ret.data[mid + Profile.len * i
                ..   mid + Profile.len * (i+1)] = temp[];
        }
        return ret;
    }

    this(const(ENetPacket*) p)
    out { assert (indices.length == profiles.length); }
    body {
        enforce((p.dataLength - header.len) % (Profile.len + Index.len) == 0);
        header = PacketHeader(p.data[0 .. header.len]);
        indices.length = (p.dataLength - header.len)
                        / (Profile.len + Index.len);
        foreach (i, ref oneIndex; indices) {
            static assert (oneIndex.len == 1);
            oneIndex = Index(p.data[header.len + i]);
        }
        profiles.length = indices.length;
        foreach (i, ref profile; profiles) {
            ubyte[Profile.len] temp = p.data[mid + Profile.len * i
                                          .. mid + Profile.len * (i+1)];
            profile = Profile(temp);
        }
    }
}

unittest {
    import net.enetglob;
    initializeEnet();
    scope (exit)
        deinitializeEnet();

    ProfileListPacket list;
    list.indices = [ PlNr(80), PlNr(81), PlNr(82) ];
    list.profiles = [ Profile(), Profile(), Profile() ];
    list.profiles[1].name = "Hello";

    auto packet = list.createPacket;
    assert (packet.data[list.header.len + 0] == 80);
    assert (packet.data[list.header.len + 1] == 81);

    auto anotherList = ProfileListPacket(packet);
    assert (anotherList.profiles.length == 3);
    assert (anotherList.indices[1] == 81);
    assert (anotherList.profiles[1].name == "Hello");
}

struct RoomChangePacket {
    enum len = header.len + Room.sizeof;
    PacketHeader header;
    Room room;

    ENetPacket* createPacket() const nothrow
    {
        auto ret = .createPacket(len);
        header.serializeTo(ret.data[0 .. header.len]);
        static assert (room.sizeof == 1);
        ret.data[header.len] = room;
        return ret;
    }

    this(const(ENetPacket*) p)
    {
        enforce(p.dataLength == len);
        header = PacketHeader(p.data[0 .. header.len]);
        room = Room(p.data[header.len]);
    }
}

struct ChatPacket {
    PacketHeader header;
    string text;

    // +1 for string null-termination
    static assert (netChatMaxLen <= 0xFFFF);
    int len() const nothrow { return header.len + 1 +
                        max!(int, int)(netChatMaxLen, text.length & 0xFFFF); }

    ENetPacket* createPacket() const nothrow
    {
        auto ret = .createPacket(len);
        header.serializeTo(ret.data[0 .. header.len]);
        strncpy(cast (char*) (ret.data + header.len), text.toStringz,
                                                      netChatMaxLen);
        ret.data[len - 1] = '\0';
        return ret;
    }

    this(const(ENetPacket*) p)
    {
        enforce(p.dataLength >= 3);
        header = PacketHeader(p.data[0 .. header.len]);
        if (p.data[p.dataLength - 1] == '\0')
            text = fromStringz(cast (char*) (p.data + header.len)).idup;
    }
}

struct SuggestPhyuPacket {
    PacketHeader header;
    Phyu update;

    enum len = header.len + update.sizeof;

    ENetPacket* createPacket() const nothrow
    {
        auto ret = .createPacket(len);
        header.serializeTo(ret.data[0 .. header.len]);
        ret.data[header.len .. header.len + update.sizeof]
            = nativeToBigEndian!int(update);
        return ret;
    }

    this(const(ENetPacket*) p)
    {
        enforce(p.dataLength >= len);
        header = PacketHeader(p.data[0 .. header.len]);
        update = Phyu(bigEndianToNative!int(
                    p.data[header.len .. header.len + update.sizeof]));
    }
}
