module net.plnr;

/*
 * Initial parts of most server-to-client and client-to-server packets:
 *  - Player numbers (PlNr),
 *  - room numbers (Room),
 *  - their aggregation into a binary message packet header (PacketHeader)
 *      that will be the first several bytes of the many-byte binary messages.
 */

import std.exception;

import derelict.enet.enet;

import net.enetglob;

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
