module net.structs;

/* The client and server exchange messages via enet. These messages are
 * manually serialized and deserialized structs, different structs for
 * different messages.
 *
 * Structs that read or write from bare buffers don't allocate usually,
 * but might still enforce(), which allocates.
 */

import std.algorithm;
import std.bitmanip;
import std.exception;
import std.string;

import net.header;
import net.packetid;
import net.plnr;
import net.profile;
import net.versioning;

struct PacketHeader2016 {
    enum len = 2;
    ubyte packetID;
    PlNr plNr;

    this(ref const(ubyte[len]) buf) nothrow @nogc
    {
        packetID = buf[0];
        plNr = PlNr(buf[1]);
    }

    void serializeTo(ref ubyte[len] buf) const nothrow @nogc
    {
        buf[0] = packetID;
        buf[1] = plNr;
    }
}

struct SomeoneDisconnectedPacket {
    PacketHeader2016 header;
    alias header this;

    this(in ubyte[] buf)
    {
        enforce(buf.length >= PacketHeader2016.len);
        header = PacketHeader2016(buf[0 .. PacketHeader2016.len]);
    }
}

struct HelloPacket {
    enum len = header.len + fromVersion.len + profile.len;
    PacketHeader2016 header;
    Version fromVersion;
    Profile2016 profile;

    void serializeTo(ubyte[] buf) const nothrow @nogc
    in {
        assert (buf.length >= len);
        assert (header.packetID == PacketCtoS.hello);
    }
    do {
        header.serializeTo(buf[0 .. header.len]);
        fromVersion.serializeTo(buf[header.len .. header.len+fromVersion.len]);
        profile.serializeTo(buf[len - profile.len .. len]);
    }

    this(in ubyte[] buf)
    {
        // In <= 0.9.42, we had here: enforce(p.dataLength == len), not >=
        enforce(buf.length >= len);
        header = PacketHeader2016(buf[0 .. header.len]);
        enforce(header.packetID == PacketCtoS.hello);
        fromVersion = Version(buf[header.len .. header.len + Version.len]);
        profile = Profile2016(buf[len - profile.len .. len]);
        /*
         * If the client sent a longer packet, we ignore what comes at
         * >= HelloPacket.len. Future server versions might interpret it.
         */
    }
}

struct HelloAnswerPacket {
    enum len = header.len + serverVersion.len;
    PacketHeader2016 header;
    Version serverVersion;

    void serializeTo(ubyte[] buf) const nothrow @nogc
    in {
        assert (buf.length >= len);
    }
    do {
        header.serializeTo(buf[0 .. header.len]);
        serverVersion.serializeTo(buf[len - serverVersion.len .. len]);
    }

    this(in ubyte[] buf)
    {
        enforce(buf.length == len);
        header = PacketHeader2016(buf[0 .. header.len]);
        serverVersion = Version(buf[len - serverVersion.len .. len]);
    }
}

unittest {
    HelloAnswerPacket a;
    a.serverVersion = Version(1, 23, 456);
    ubyte[HelloAnswerPacket.len] buf;
    a.serializeTo(buf);
    auto b = HelloAnswerPacket(buf);
    assert (b.serverVersion == a.serverVersion);
    assert (b.serverVersion.minor == 23);
}

struct ProfilePacket2016 {
    enum len = header.len + profile.len;
    PacketHeader2016 header;
    Profile2016 profile;

    void serializeTo(ubyte[] buf) const nothrow @nogc
    in {
        assert (buf.length == len);
        /*
         * Not >=. I don't dare touching 2016 logic because I want the assert
         * to fire on inadvertent changes where 2016 clients/servers behave
         * any different than in 2016.
         */
    }
    do {
        header.serializeTo(buf[0 .. header.len]);
        profile.serializeTo(buf[len - profile.len .. len]);
    }

    this(in ubyte[] buf)
    {
        enforce(buf.length == len);
        header = PacketHeader2016(buf[0 .. header.len]);
        profile = Profile2016(buf[len - profile.len .. len]);
    }
}

alias ProfilePacket2022 = NeckPacket!(Profile2022);

// ############################################################### list packets

alias ProfileListPacket2016 = ListPacket2016!PlNr;
alias RoomListPacket2016 = ListPacket2016!Room;

struct ListPacket2016(Index)
    if (is (Index == PlNr) || is (Index == Room))
{
    PacketHeader2016 header;
    Index[] indices; // structure of arrays, indices[i] belongs to profiles[i]
    Profile2016[] profiles;

    @property int len() const nothrow @nogc
    {
        int numProfiles = profiles.length & 0x7FFF;
        return header.len + (Index.len + Profile2016.len) * numProfiles;
    }

    private @property int mid() const nothrow @nogc
    {
        return header.len + Index.len * (indices.length & 0x7FFF);
    }

    void serializeTo(ubyte[] buf) const nothrow @nogc
    in {
        assert (buf.length >= len);
    }
    out {
        assert (indices.length == 0 || buf[header.len] == indices[0]);
    }
    do {
        header.serializeTo(buf[0 .. header.len]);

        foreach (i, anIndex; indices) {
            static assert (Index.len == 1);
            buf[header.len + i] = anIndex;
        }
        assert (indices.length == 0 || buf[header.len] == indices[0]);
        foreach (i, profile; profiles) {
            // profile.serializeTo expects the slice length at compile-time.
            // I don't know how to create a fixed-length D array from a pointer
            // and the length, so I do it with this otherwise-unecessary copy.
            ubyte[Profile2016.len] temp;
            profile.serializeTo(temp);
            buf[mid + Profile2016.len * i .. mid + Profile2016.len * (i+1)]
                = temp[];
        }
    }

    this(in ubyte[] buf)
    out { assert (indices.length == profiles.length); }
    do {
        enforce((buf.length - header.len) % (Profile2016.len + Index.len) == 0);
        header = PacketHeader2016(buf[0 .. header.len]);
        indices.length = (buf.length - header.len)
                       / (Profile2016.len + Index.len);
        foreach (i, ref oneIndex; indices) {
            static assert (oneIndex.len == 1);
            oneIndex = Index(buf[header.len + i]);
        }
        profiles.length = indices.length;
        foreach (i, ref profile; profiles) {
            ubyte[Profile2016.len] temp = buf[mid + Profile2016.len * i
                                           .. mid + Profile2016.len * (i+1)];
            profile = Profile2016(temp);
        }
    }
}

unittest { // 2016
    ProfileListPacket2016 list;
    list.indices = [ PlNr(80), PlNr(81), PlNr(82) ];
    list.profiles = [ Profile2016(), Profile2016(), Profile2016() ];
    list.profiles[1].name = "Hello";

    assert(list.len == 107);
    assert(list.len == 2 + 3 * (1 + 34));
    ubyte[107] buf;
    list.serializeTo(buf);
    assert (buf[list.header.len + 0] == 80);
    assert (buf[list.header.len + 1] == 81);

    auto anotherList = ProfileListPacket2016(buf);
    assert (anotherList.profiles.length == 3);
    assert (anotherList.indices[1] == 81);
    assert (anotherList.profiles[1].name == "Hello");
}

unittest { // 2022
    RoomListEntry2022 createEntry(in Room r, in int i, in string name) {
        RoomListEntry2022 ret;
        ret.room = r;
        ret.numInhabitants = i;
        ret.owner = Profile2022();
        ret.owner.name = name;
        return ret;
    }
    RoomListPacket2022 before;
    before.arr ~= createEntry(Room(3), 33, "Hello");
    before.arr ~= createEntry(Room(5), 55, "World");

    ubyte[2 * (64 + 32) + 16] buf;
    before.serializeTo(buf);
    auto after = RoomListPacket2022(buf);
    assert (after.arr.length == 2);
    assert (after.arr[0].owner.name == "Hello");
    assert (after.arr[1].owner.name == "World");
    assert (after.arr[1].room == Room(5));
    assert (after.arr[1].numInhabitants == 55);
}

alias RoomListPacket2022 = ArrayPacket!(RoomListEntry2022);

struct PeerInRoomEntry2022 {
    PlNr plnr;
    bool isOwner; // Future idea: Make this a room property, not per-profile.
    Profile2022 profile;

    enum int len = 8 + profile.len;

    this(in ubyte[] buf) pure {
        enforce (buf.length >= len);
        plnr = PlNr(0xFF & buf[0 .. 2].bigEndianToNative!short);
        isOwner = 0 != buf[2 .. 4].bigEndianToNative!short;
        // buf[4 .. 8] unused, they're always 0.
        profile = Profile2022(buf[8 .. buf.length]);
    }

    void serializeTo(ref ubyte[len] buf) const pure nothrow @nogc
    {
        buf[0 .. 2] = nativeToBigEndian!short(plnr);
        buf[2 .. 4] = nativeToBigEndian!short(isOwner);
        buf[4 .. 8] = 0; // Unused, reserved.
        profile.serializeTo(buf[8 .. len]);
    }
}

alias PeersInRoomPacket2022 = ArrayPacket!(PeerInRoomEntry2022);

// ######################################################## end of list packets

struct RoomChangePacket {
    enum len = header.len + Room.sizeof;
    PacketHeader2016 header;
    Room room;

    void serializeTo(ubyte[] buf) const nothrow @nogc
    in {
        assert (buf.length == len);
    }
    do {
        header.serializeTo(buf[0 .. header.len]);
        static assert (room.sizeof == 1);
        buf[header.len] = room;
    }

    this(in ubyte[] buf)
    {
        enforce(buf.length == len);
        header = PacketHeader2016(buf[0 .. header.len]);
        room = Room(buf[header.len]);
    }
}

struct ChatPacket {
    PacketHeader2016 header;
    string text;

    static assert (netChatMaxLen <= 0xFFFF);
    int len() const pure nothrow @safe @nogc
    {
        return header.len
            + (min(netChatMaxLen & 0xFFFF, text.length & 0xFFFF) & 0xFFFF)
            + 1; // Terminating nullbyte
    }

    void serializeTo(ubyte[] buf) const nothrow @nogc
    in {
        assert (buf.length >= len);
    }
    do {
        header.serializeTo(buf[0 .. header.len]);
        buf[header.len .. len] = '\0';
        foreach (int i; 0 .. (len - header.len - 1)) {
            buf[header.len + i] = text[i];
        }
        buf[len - 1] = '\0';
    }

    this(in ubyte[] buf)
    {
        enforce(buf.length >= 3);
        header = PacketHeader2016(buf[0 .. header.len]);
        if (buf[$ - 1] == '\0') {
            text = fromStringz(cast (char*) (buf.ptr + header.len)).idup;
        }
    }
}

unittest {
    ChatPacket chat;
    chat.text = "Hello";
    assert (chat.len == 2 + 5 + 1);

    ubyte[20] buf;
    chat.serializeTo(buf);

    const decoded = ChatPacket(buf);
    assert (decoded.text == chat.text);
    assert (decoded.len == chat.len);
}

struct MillisecondsSinceGameStartPacket {
    PacketHeader2016 header;
    int milliseconds;

    enum len = header.len + milliseconds.sizeof;

    void serializeTo(ubyte[] buf) const nothrow @nogc
    in {
        assert (buf.length >= len);
    }
    do {
        header.serializeTo(buf[0 .. header.len]);
        buf[header.len .. header.len + milliseconds.sizeof]
            = nativeToBigEndian!int(milliseconds);
    }

    this(in ubyte[] buf)
    {
        enforce(buf.length >= len);
        header = PacketHeader2016(buf[0 .. header.len]);
        milliseconds = bigEndianToNative!int(
            buf[header.len .. header.len + milliseconds.sizeof]);
    }
}
