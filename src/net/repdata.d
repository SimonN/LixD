module net.repdata;

/* ReplayData, Permu
 */

import std.bitmanip;
import std.conv;
import std.exception;
import std.random;

import derelict.enet.enet;
import net.packetid;
import net.enetglob;

import net.ac;
public import net.structs : PlNr;

struct Update { int u; alias u this; } // counts how far the game has advanced

enum RepAc : ubyte {
    NOTHING = 0,
    SPAWNINT = 1,
    SKILL_LEGACY_SUPPORT = 2, // only while reading files, never used after
    ASSIGN = 3,
    ASSIGN_LEFT = 4,
    ASSIGN_RIGHT = 5,
    NUKE = 6
}

struct ReplayData {
    private enum len = player.sizeof + action.sizeof + skill.sizeof
                        + update.sizeof + toWhichLix.sizeof + 1; // +1 header
    static assert (len == 12);

    PlNr   player;
    RepAc  action;
    Ac     skill; // only meaningful if isSomeAssignment
    Update update;
    int    toWhichLix;

    @property bool isSomeAssignment() const
    {
        return action == RepAc.ASSIGN
            || action == RepAc.ASSIGN_LEFT
            || action == RepAc.ASSIGN_RIGHT;
    }

    int opCmp(const ref ReplayData rhs) const
    {
        return this.update < rhs.update ? -1
            :  this.update > rhs.update ?  1
            :  this.player < rhs.player ? -1
            :  this.player > rhs.player ?  1 : 0;
        // do not order by action:
        // assign, force, nuke -- all of these are equal, and the sorts must
        // be with these. Keep such records in whatever order they were input.
    }

    ENetPacket* createPacket() const nothrow
    {
        ENetPacket* pck = .createPacket(len);
        assert (pck);
        pck.data[0] = PacketCtoS.myReplayData;
        pck.data[1] = player;
        pck.data[2] = action;
        pck.data[3] = skill;
        pck.data[4 ..  8] = nativeToBigEndian!int(update);
        pck.data[8 .. 12] = nativeToBigEndian!int(toWhichLix);
        return pck;
    }

    this(in ENetPacket* pck)
    {
        assert (pck.data[0] == PacketCtoS.myReplayData
            ||  pck.data[0] == PacketStoC.peerReplayData,
            "don't call ReplayData(p) if p is not replay data");
        enforce(pck.dataLength == len);
        player = PlNr(pck.data[1]);
        update = Update(bigEndianToNative!int(pck.data[4 ..  8]));
        toWhichLix =    bigEndianToNative!int(pck.data[8 .. 12]);

        try               action = pck.data[2].to!RepAc;
        catch (Exception) action = RepAc.NOTHING;
        try               skill  = pck.data[3].to!Ac;
        catch (Exception) skill  = Ac.nothing;
    }

}
