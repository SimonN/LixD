module net.permu;

import std.bitmanip;
import std.exception;
import std.random;
import std.string;

import derelict.enet.enet;

import net.enetglob;
import net.repdata; // PlNr
import net.packetid;
import net.structs;

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
    PacketHeader header;
    PlNr[] arr;

    int len() const nothrow { return header.len + (arr.length & 0xFF); }

    this(int permuSize)
    {
        header.packetID = PacketStoC.gameStartsWithPermu;
        foreach (i; 0 .. permuSize)
            arr ~= PlNr(i & 0xFF);
        arr.randomShuffle;
    }

    ENetPacket* createPacket() const nothrow
    {
        auto ret = .createPacket(len);
        header.serializeTo(ret.data[0 .. header.len]);
        static assert (PlNr.sizeof == 1);
        foreach (int i; 0 .. 0xFF & arr.length)
            ret.data[header.len + i] = arr[i];
        return ret;
    }

    this(const(ENetPacket*) p)
    {
        enforce(p.dataLength >= 3);
        enforce(p.dataLength < header.len + PlNr.maxExclusive);
        header = PacketHeader(p.data[0 .. header.len]);
        arr.length = p.dataLength - header.len;
        foreach (int i; 0 .. 0xFF & arr.length)
            arr[i] = p.data[header.len + i];
    }
}
