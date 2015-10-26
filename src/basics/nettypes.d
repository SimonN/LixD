module basics.nettypes;

/* ReplayData, Permu
 */

import std.bitmanip;
import std.c.string : memmove;
import std.conv;
import std.random;

import derelict.enet.enet;

import basics.help;

alias PlNr = ubyte;

enum NETWORK_PROTOCOL_VERSION = 2;

enum NETWORK_TEXT_LENGTH    = 300;
enum NETWORK_PLAYERS_MAX    = 127;
enum NETWORK_ROOMS_MAX      = 127;

enum NETWORK_CHANNEL_MAIN    =  0;
enum NETWORK_CHANNEL_REPLAY  =  0;
enum NETWORK_CHANNEL_CHAT    =  1;
enum NETWORK_CHANNEL_MAX     =  2;

enum NETWORK_NOTHING         =  0;
enum NETWORK_DISCON_SILENT   =  1;
enum NETWORK_WELCOME_DATA    =  2;
enum NETWORK_YOU_TOO_OLD     =  3;
enum NETWORK_YOU_TOO_NEW     =  4;
enum NETWORK_SOMEONE_OLD     =  5;
enum NETWORK_SOMEONE_NEW     =  6;
enum NETWORK_RECHECK         =  7;

enum NETWORK_ASSIGN_NUMBER   = 10;
enum NETWORK_ROOM_DATA       = 11;
enum NETWORK_ROOM_CHANGE     = 12;
enum NETWORK_ROOM_CREATE     = 13;

enum NETWORK_PLAYER_DATA     = 20;
enum NETWORK_PLAYER_BEFORE   = 21;
enum NETWORK_PLAYER_OUT_TO   = 22;
enum NETWORK_PLAYER_CLEAR    = 23;

enum NETWORK_CHAT_MESSAGE    = 30;
enum NETWORK_LEVEL_FILE      = 31;

enum NETWORK_GAME_START      = 40;
enum NETWORK_GAME_END        = 41;
enum NETWORK_REPLAY_DATA     = 42;
enum NETWORK_UPDATES         = 43;



struct ReplayData {

    enum : ubyte {
        NOTHING = 0,
        SPAWNINT = 1,
        SKILL_LEGACY_SUPPORT = 2, // only while reading files, never used after
        ASSIGN = 3,
        ASSIGN_LEFT = 4,
        ASSIGN_RIGHT = 5,
        NUKE = 6
    }

    ubyte player;
    ubyte action;
    ubyte skill; // only != 0 when action == ASSIGN or ASSIGN_LEFT or _RIGHT
    int   update;
    int   toWhichLix; // assign to which lix, or change rate to how much
    alias toWhatSpawnint = toWhichLix;

    this(in byte b = 0)
    {
        action = b;
    }

    @property bool isSomeAssignment() const
    {
        return action == ASSIGN
            || action == ASSIGN_LEFT
            || action == ASSIGN_RIGHT;
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

    ENetPacket* create_packet() const
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

    void read_from(ENetPacket* pck)
    {
        assert (pck.data[0] == NETWORK_REPLAY_DATA);
        player = pck.data[1];
        action = pck.data[2];
        skill  = pck.data[3];
        update     = bigEndianToNative!int(pck.data[4 ..  8]);
        toWhichLix = bigEndianToNative!int(pck.data[8 .. 12]);
    }

}



class Permu {

    private PlNr[] p;

    this(int newSize)
    {
        foreach (i; 0 .. newSize)
            p ~= i & 0xFF;
        p.randomShuffle;
    }

    this(int numBytesToRead, PlNr* address)
    {
        foreach (i; 0 .. numBytesToRead)
            p ~= *(address + i);
    }

    // Read in a string that is separated by any non-digit characters
    this(string src)
    {
        PlNr nextID = 0;
        bool digitHasBeenRead = false;

        foreach (char c; src) {
            if (c >= '0' && c <= '9') {
                nextID *= 10;
                nextID += c - '0';
                digitHasBeenRead = true;
            }
            else if (digitHasBeenRead) {
                p ~= nextID;
                digitHasBeenRead = false;
            }
        }
    }

    @property int size() const { return p.len; }

    PlNr opIndex(int id) const
    {
        if (id >= 0 && id < p.len)
            return p[id];
        else
            // outside of the permuted range, pad with the identity
            return id & 0xFF;
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
