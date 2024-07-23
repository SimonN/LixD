module net.permu;

import std.algorithm;
import std.exception;
import std.random;
import std.string;

import net.structs;
import net.packetid;
import net.plnr;

struct Permu {
private:
    /*
     * Representation: The 4-team permutation 1 0 2 3 is represented as
     *
     *      1 0 2 3 0 0 0 0 0 0 ... 0,
     *
     * where the position of the earliest 0 from the left tells us the seat
     * of player 0. The second-earliest 0 from the left tells us the end
     * of the internal representation; only more zeros are allowed to follow
     * that second 0.
     *
     * The unique 1-team permutation, thus, is all zeros.
     */
    PlNr[16] _p;

public:
    this(const(PlNr[]) copyFromArray) pure nothrow @safe @nogc
    {
        static assert (_p.length > 0);
        immutable copyUntil = min(copyFromArray.length, _p.length);
        _p[0 .. copyUntil] = copyFromArray[0 .. copyUntil];
    }

    // Parse string that is separated by any non-digit characters
    this(in string src) pure nothrow @safe @nogc
    {
        size_t i = 0; // Index into p[] to the next number to fill
        bool previousCharWasDigit = false;
        foreach (char c; src) {
            if (c >= '0' && c <= '9') {
                _p[i].n *= 10;
                _p[i].n += c - '0';
                previousCharWasDigit = true;
            }
            else if (previousCharWasDigit) {
                ++i;
                if (i >= _p.length) {
                    return;
                }
                previousCharWasDigit = false;
            }
        }
    }

    int len() const pure nothrow @safe @nogc
    {
        /*
         * Returns the number of PlNrs before the second zero.
         * See comment for the declaration of _p for why that is correct.
         * If no second zero appears (or not even a first zero),
         * then it returns _p.length, which is the maximum len possible.
         */
        return 0x7FFF_FFFF
            & (_p.length - _p[].find(0).andDropIt.find(0).length);
    }

    PlNr opIndex(in int id) const pure nothrow @safe @nogc
    {
        return (id >= 0 && id < len)
            ? _p[id]
            : PlNr(id & 0xFF); // Outside of the range, pad with the identity.
    }

    bool opEquals(const typeof(this) rhs) const pure nothrow @safe @nogc
    {
        return _p[] == rhs._p[];
    }

    string toString() const pure @safe
    {
        enum msg = "Even the most trivial representation 0 0 ... 0"
            ~ " isn't the empty pemutation. Thus, we'll assume ret.len >= 1.";
        assert (len >= 1, msg);
        string ret;
        foreach (index, value; _p[0 .. len]) {
            ret ~= "%d ".format(value);
        }
        assert (ret.length >= 1, msg);
        return ret[0 .. $-1]; // Without the last space.
    }
};

const(PlNr)[] andDropIt(const(PlNr)[] input) pure nothrow @safe @nogc
{
    return input.length > 0 ? input[1 .. $] : [];
}

pure @safe unittest {
    const permu = Permu("1 0 2 3");
    assert (permu.len == 4);
    assert (permu[1] == PlNr(0));
    assert (permu[2] == PlNr(2));

    assert (permu == Permu(permu.toString),
        "String 1 0 2 3 mismatches " ~ permu.toString);
}

pure @safe unittest {
    const permu = Permu("this is 2 much 4 me");
    assert (permu.len == 3, "Will be encoded as 2 4 0, then 0 0 0 ... 0");
    assert (permu[0] == PlNr(2));
    assert (permu[1] == PlNr(4));
    assert (permu == Permu(permu.toString),
        "String 2 4 0 mismatches " ~ permu.toString);
}

pure @safe unittest {
    immutable longSrc = "99 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17";
    const permu = Permu(longSrc);
    assert (permu.len == 16);
    assert (permu[7] == PlNr(7));
    assert (permu[19] == PlNr(19));
    assert (permu.toString != longSrc,
        "This permu is too long to serialize all information from the input");
    assert (permu == Permu(permu.toString),
        "Even though it was too long, serialize-deserialize should be no-op");
}

/*
 * Length of the network-sent permutation is determined from packet length.
 *
 * Unlike the Permu type, this struct is part of the networking protocol.
 */
struct StartGameWithPermuPacket {
    PacketHeader2016 header;
    PlNr[] arr;

    int len() const pure nothrow @safe @nogc
    {
        return header.len + (arr.length & 0xFF);
    }

    this(int permuSize)
    {
        header.packetID = PacketStoC.gameStartsWithPermu;
        foreach (i; 0 .. permuSize)
            arr ~= PlNr(i & 0xFF);
        arr.randomShuffle;
    }

    void serializeTo(ubyte[] buf) const nothrow @nogc
    {
        assert (buf.length >= len);
        header.serializeTo(buf[0 .. header.len]);
        static assert (PlNr.sizeof == 1, "Assumed in the 2016 permu format");
        foreach (int i; 0 .. 0xFF & arr.length) {
            buf[header.len + i] = arr[i];
        }
    }

    this(in ubyte[] buf)
    {
        enforce(buf.length >= 3);
        enforce(buf.length <= header.len + PlNr.maxExclusive);
        header = PacketHeader2016(buf[0 .. header.len]);
        arr.length = buf.length - header.len;
        foreach (int i; 0 .. 0xFF & arr.length)
            arr[i] = buf[header.len + i];
    }
}
