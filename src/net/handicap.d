module net.handicap;

import std.bitmanip;

/*
 * Handicap: We're defining this as int (4 bytes), not as ubyte, to have room
 * for expansion in the serialized representation.
 *
 * Definitions:
 * Interpret (the handicap number & 0xFF) as a percentage value, i.e.,
 * 100 means 100 %. Handicaps over 100 % should not be used, to keep the
 * representation clean from bleeding into the high 3 bytes.
 * As of 2022, those high 3 bytes are unused.
 *
 * Handicap in multiplayer means:
 * scale() the handicapped player's initial lix count.
 * For each skill, scale() the number in the handicapped player's skillbar.
 */
struct Handicap {
    enum int len = 4;
    int n = 100;
    alias n this;

    this(ref const (ubyte[len]) source) pure nothrow @safe @nogc
    {
        n = source.bigEndianToNative!int;
    }

    void serializeTo(ref ubyte[len] buf) const pure nothrow @safe @nogc
    {
        buf[0 .. len] = n.nativeToBigEndian!int;
    }

    int scale(int input) const pure nothrow @safe @nogc
    {
        return (input * (n & 0xFF) + 99) / 100;
    }
}
