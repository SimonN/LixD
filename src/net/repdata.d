module net.repdata;

import std.bitmanip;
import std.conv;
import std.exception;

import net.packetid;
import net.ac;
public import net.phyu;
public import net.plnr;

enum RepAc : ubyte {
    NOTHING = 0,
    ASSIGN = 3,
    ASSIGN_LEFT = 4,
    ASSIGN_RIGHT = 5,
    NUKE = 6
}

struct Ply {
    PlNr by; // Who generated this ply. We'll apply to his tribe.
    Phyu when; // We'll happen at the start of this.when, before physics.

    bool isNuke; // Otherwise, it's an assignment.
    Ac skill; // Only meaningful if isAssignment().
    int toWhichLix; // Only meaningful if isAssignment().

    /*
     * lixShouldFace: Let's remember it, even if the assignment is unforced.
     * Reason: Unforced direction will be nice to display in the tweaker.
     *
     * In 0.10, we only send lixShouldFace through the network if forced.
     * It would be nice to always send it when we edit the networking protocol
     * for the next time after 0.10.
     */
    LixShouldFace lixShouldFace; // Only meaningful if isAssignment().
    bool isDirectionallyForced; // Only meaningful if lixShouldFace != unknown.

    enum LixShouldFace : ubyte {
        unknown,
        right,
        left
    }

    package enum len = by.sizeof + RepAc.sizeof + skill.sizeof
                     + when.sizeof + toWhichLix.sizeof;

pure nothrow @safe @nogc:
    bool isAssignment() const { return ! isNuke; }

    RepAc toRepAc() const
    {
        if (isNuke) {
            return RepAc.NUKE;
        }
        if (isDirectionallyForced) {
            return lixShouldFace == LixShouldFace.left ? RepAc.ASSIGN_LEFT
                : lixShouldFace == LixShouldFace.right ? RepAc.ASSIGN_RIGHT
                : RepAc.ASSIGN;
        }
        return RepAc.ASSIGN;
    }

    void fromRepAc(in ubyte action)
    {
        isNuke = (action == RepAc.NUKE);
        lixShouldFace
            = action == RepAc.ASSIGN_LEFT ? LixShouldFace.left
            : action == RepAc.ASSIGN_RIGHT ? LixShouldFace.right
            : lixShouldFace.unknown;
        isDirectionallyForced
            = action == RepAc.ASSIGN_LEFT || action == RepAc.ASSIGN_RIGHT;
    }

    int opCmp(const ref Ply rhs) const
    {
        return this.when < rhs.when ? -1
            :  this.when > rhs.when ?  1
            :  this.by < rhs.by ? -1
            :  this.by > rhs.by ?  1 : 0;
        // do not order by action:
        // assign, force, nuke -- all of these are equal, and the sorts must
        // be with these. Keep such records in whatever order they were input.
    }
}

struct PlyPacket {
    ubyte packetId;
    Ply ply;

    enum len = Ply.len + packetId.sizeof;
    static assert (len == Ply.len + 1);
    static assert (len == 12);

    this(in ubyte aPacketId, in Ply aPly) pure nothrow @safe @nogc
    {
        packetId = aPacketId;
        ply = aPly;
    }

    void serializeTo(ubyte[] buf) const pure nothrow @nogc
    {
        assert (buf.length >= len);
        assert (packetId == PacketCtoS.myPly
            ||  packetId == PacketStoC.peerPly);
        buf[0] = packetId;
        buf[1] = ply.by;
        buf[2] = ply.toRepAc();
        buf[3] = ply.skill;
        buf[4 ..  8] = nativeToBigEndian!int(ply.when);
        buf[8 .. 12] = nativeToBigEndian!int(ply.toWhichLix);
    }

    this(in ubyte[] buf) pure
    {
        enforce(buf.length >= len); // 2016 had == in 2022 let's allow >=
        enforce(buf[0] == PacketCtoS.myPly
            ||  buf[0] == PacketStoC.peerPly);
        ply.by = PlNr(buf[1]);
        ply.when = Phyu(bigEndianToNative!int(buf[4 .. 8]));
        ply.toWhichLix = bigEndianToNative!int(buf[8 .. 12]);
        ply.fromRepAc(buf[2]);
        try               ply.skill = buf[3].to!Ac;
        catch (Exception) ply.skill = Ac.nothing;
    }
}
