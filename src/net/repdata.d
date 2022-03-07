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
    SPAWNINT = 1,
    SKILL_LEGACY_SUPPORT = 2, // only while reading files, never used after
    ASSIGN = 3,
    ASSIGN_LEFT = 4,
    ASSIGN_RIGHT = 5,
    NUKE = 6
}

struct Ply {
    package enum len = player.sizeof + action.sizeof + skill.sizeof
                     + update.sizeof + toWhichLix.sizeof;

    PlNr player;
    RepAc action;
    Ac skill; // only meaningful if isSomeAssignment
    Phyu update;
    int toWhichLix;

    @property bool isSomeAssignment() const
    {
        return action == RepAc.ASSIGN
            || action == RepAc.ASSIGN_LEFT
            || action == RepAc.ASSIGN_RIGHT;
    }

    int opCmp(const ref Ply rhs) const
    {
        return this.update < rhs.update ? -1
            :  this.update > rhs.update ?  1
            :  this.player < rhs.player ? -1
            :  this.player > rhs.player ?  1 : 0;
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
        buf[1] = ply.player;
        buf[2] = ply.action;
        buf[3] = ply.skill;
        buf[4 ..  8] = nativeToBigEndian!int(ply.update);
        buf[8 .. 12] = nativeToBigEndian!int(ply.toWhichLix);
    }

    this(in ubyte[] buf) pure
    {
        enforce(buf.length >= len); // 2016 had == in 2022 let's allow >=
        enforce(buf[0] == PacketCtoS.myPly
            ||  buf[0] == PacketStoC.peerPly);
        ply.player = PlNr(buf[1]);
        ply.update = Phyu(bigEndianToNative!int(buf[4 ..  8]));
        ply.toWhichLix = bigEndianToNative!int(buf[8 .. 12]);

        try               ply.action = buf[2].to!RepAc;
        catch (Exception) ply.action = RepAc.NOTHING;
        try               ply.skill  = buf[3].to!Ac;
        catch (Exception) ply.skill  = Ac.nothing;
    }
}
