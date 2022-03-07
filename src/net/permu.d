module net.permu;

import std.exception;
import std.random;
import std.string;

import net.structs;
import net.packetid;
import net.plnr;

class Permu {
private:
    PlNr[] p;

public:
    pure this(const(PlNr[]) copyFromArray) { p = copyFromArray.dup; }
    pure Permu clone() const               { return new Permu(this); }
    pure this(in Permu rhs)                { p = rhs.p.dup; }

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
                nextID = PlNr(0);
                digitHasBeenRead = false;
            }
        }
        if (digitHasBeenRead)
            p ~= nextID;
    }

    unittest {
        Permu permu = new Permu("1 0 2 3");
        assert (permu.len == 4);
        assert (permu[1] == 0);
        assert (permu[2] == 2);
        permu = new Permu("this is 2 much 4 me");
        assert (permu.len == 2);
        assert (permu[1] == 4);
    }

    @property int len() const { return p.length & 0x7FFF_FFFF; }

    PlNr opIndex(int id) const
    {
        if (id >= 0 && id < len)
            return p[id];
        else
            // outside of the permuted range, pad with the identity
            return PlNr(id & 0xFF);
    }

    override bool opEquals(Object rhs_obj) const
    {
        typeof(this) rhs = cast (const(typeof(this))) rhs_obj;
        return rhs !is null && this.p == rhs.p;
    }

    override @property string toString() const
    {
        if (! p.length)
            return "";
        string ret;
        foreach (index, value; p)
            ret ~= "%d ".format(value);
        return ret[0 .. $-1]; // without last space
    }
};

/* Length of the network-sent permutation is determined from packet length
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
