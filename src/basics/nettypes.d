module basics.nettypes;

/* ReplayData, Permu
 */

import std.bitmanip;
import std.c.string; // memmove
import std.conv;
import std.random;

import derelict.enet.enet;

import basics.help;
import lix.enums; // Ac

// make function interfaces more typesafe
struct PlNr   { ubyte n; alias n this; }
struct Update { int u;   alias u this; }

enum : int {
    NETWORK_PROTOCOL_VERSION = 2,

    NETWORK_TEXT_LENGTH = 300,
    NETWORK_PLAYERS_MAX = 127,
    NETWORK_ROOMS_MAX   = 127,
}

enum : ubyte {
    NETWORK_CHANNEL_MAIN    =  0,
    NETWORK_CHANNEL_REPLAY  =  0,
    NETWORK_CHANNEL_CHAT    =  1,
    NETWORK_CHANNEL_MAX     =  2,

    NETWORK_NOTHING         =  0,
    NETWORK_DISCON_SILENT   =  1,
    NETWORK_WELCOME_DATA    =  2,
    NETWORK_YOU_TOO_OLD     =  3,
    NETWORK_YOU_TOO_NEW     =  4,
    NETWORK_SOMEONE_OLD     =  5,
    NETWORK_SOMEONE_NEW     =  6,
    NETWORK_RECHECK         =  7,

    NETWORK_ASSIGN_NUMBER   = 10,
    NETWORK_ROOM_DATA       = 11,
    NETWORK_ROOM_CHANGE     = 12,
    NETWORK_ROOM_CREATE     = 13,

    NETWORK_PLAYER_DATA     = 20,
    NETWORK_PLAYER_BEFORE   = 21,
    NETWORK_PLAYER_OUT_TO   = 22,
    NETWORK_PLAYER_CLEAR    = 23,

    NETWORK_CHAT_MESSAGE    = 30,
    NETWORK_LEVEL_FILE      = 31,

    NETWORK_GAME_START      = 40,
    NETWORK_GAME_END        = 41,
    NETWORK_REPLAY_DATA     = 42,
    NETWORK_UPDATES         = 43
}

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

    PlNr   player;
    RepAc  action;
    Ac     skill; // only meaningful if isSomeAssignment
    Update update;
    int    toWhichLix; // assign to which lix, or change rate to how much
    alias  toWhatSpawnint = toWhichLix;
    deprecated("use toWhichLix/toWhatSpawnint") alias what = toWhichLix;

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

    ENetPacket* createPacket() const
    {
        ENetPacket* pck = enet_packet_create(null, 12,
                          ENET_PACKET_FLAG_RELIABLE);
        assert (pck);
        pck.data[0] = NETWORK_REPLAY_DATA;
        pck.data[1] = player;
        pck.data[2] = action;
        pck.data[3] = skill;
        pck.data[4 ..  8] = nativeToBigEndian!int(update);
        pck.data[8 .. 12] = nativeToBigEndian!int(toWhichLix);
        return pck;
    }

    nothrow this(in ENetPacket* pck)
    {
        assert (pck.data[0] == NETWORK_REPLAY_DATA,
            "don't call ReplayData(p) if p is not replay data");
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

    @property int size() const { return p.len; }

    PlNr opIndex(int id) const
    {
        if (id >= 0 && id < p.len)
            return p[id];
        else
            // outside of the permuted range, pad with the identity
            return PlNr(id & 0xFF);
    }

    deprecated("cut off, or erase too high values?") void
    shortenTo(int newSize)
    {
        assert (newSize >= 0);
        assert (newSize < p.len);
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
