module net.repdata;

/* ReplayData, Permu
 */

import core.stdc.string; // memmove
import std.bitmanip;
import std.conv;
import std.exception;
import std.random;

import derelict.enet.enet;

import net.ac;

struct PlNr { ubyte n; alias n this; }
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
        ENetPacket* pck = enet_packet_create(null, 12,
                          ENET_PACKET_FLAG_RELIABLE);
        assert (pck);
        // pck.data[0] in next commit
        pck.data[1] = player;
        pck.data[2] = action;
        pck.data[3] = skill;
        pck.data[4 ..  8] = nativeToBigEndian!int(update);
        pck.data[8 .. 12] = nativeToBigEndian!int(toWhichLix);
        return pck;
    }

    this(in ENetPacket* pck)
    {
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



class Permu {

    private PlNr[] p;

    this(int newSize)
    {
        foreach (i; 0 .. newSize)
            p ~= PlNr(i & 0xFF);
        p.randomShuffle;
    }

    this(int numBytesToRead, PlNr* address)
    {
        foreach (i; 0 .. numBytesToRead)
            p ~= *(address + i);
    }

    pure Permu clone() const
    {
        return new Permu(this);
    }

    pure this(in Permu rhs)
    {
        p = rhs.p.dup;
    }

    // Read in a string that is separated by any non-digit characters
    this(string src)
    {
        PlNr nextID = PlNr(0);
        bool digitHasBeenRead = false;

        foreach (char c; src) {
            if (c >= '0' && c <= '9') {
                nextID.n *= 10;
                nextID.n += c - '0';
                digitHasBeenRead = true;
            }
            else if (digitHasBeenRead) {
                p ~= nextID;
                digitHasBeenRead = false;
            }
        }
        if (digitHasBeenRead)
            p ~= nextID;
    }

    unittest {
        Permu permu = new Permu("0 1 2 3");
        assert (permu.size == 4);
        permu = new Permu("this is 2 much 4 me");
        assert (permu.size == 2);
    }

    @property int size() const { return p.length & 0x7FFF_FFFF; }

    PlNr opIndex(int id) const
    {
        if (id >= 0 && id < size)
            return p[id];
        else
            // outside of the permuted range, pad with the identity
            return PlNr(id & 0xFF);
    }

    deprecated("cut off, or erase too high values?") void
    shortenTo(int newSize)
    {
        assert (newSize >= 0);
        assert (newSize < size);
        p = p[0 .. newSize];
    }

    override bool opEquals(Object rhs_obj) const
    {
        typeof(this) rhs = cast (const(typeof(this))) rhs_obj;
        return rhs !is null && this.p == rhs.p;
    }

    override @property string toString() const
    {
        string ret;
        foreach (index, value; p) {
            ret ~= value.to!string;
            if (index < size - 1)
                ret ~= " ";
        }
        return ret;
    }

};
