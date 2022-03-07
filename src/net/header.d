module net.header;

/*
 * Binary Message Headers:
 * How packet ID and PlNr (and maybe Room) aggregate  into a binary message
 * packet header (PacketHeader2016 or PacketHeader2022)
 * that will be the first several bytes of the many-byte binary messages.
 *
 * +--------------------------------+
 * | Packet Header, always 16 bytes |  The header always exists.
 * +--------------------------------+
 * |     Optional: Packet Neck.     |  The neck may or may not exist.
 * |     The packet header tells    |  But it either always exists for the same
 * |   where the neck ends: At the  |  packet type, or it never exists for it.
 * |    start of array entry #0.    |
 * +--------------------------------+
 * |   Optional: Array entry #0     |  It's legal to send 2022 headers that
 * | Header tells start and length. |  have zero array elements, with or
 * +--------------------------------+  without a neck.
 * |   Optional: Array entry #1     |
 * |                                |  Number of array elements is not constant
 * +--------------------------------+  even within packets of the same type.
 * |   Optional: Array entry #2     |
 * :                                :
 * .                                .
 */

import std.bitmanip;
import std.exception;

import net.enetglob;
import net.plnr;

struct PacketHeader2022 {
    enum int len = 16;
    ubyte packetId;
    Room subjectsRoom; // Room where the subject is, see next field.
    PlNr subject; // Somebody else. Or the recipient if the array holds plnrs.
    /*
     * See comment at top of file for layout; here it is again:
     * A packet has a header (length fixed across all packets),
     * optionally, a neck (length fixed per packet type),
     * optionally, array (length per entry fixed per type, num entries vary).
     *
     * (numFields) is >= 0. It's legal to send an empty array.
     * arr[0] starts at (offsetField0) from the start of the packet.
     * That (offsetField0) must be >= (PacketHeader2022.len)
     * and is usually ==; the packet is invalid if it is <.
     *
     * If (numFields) >= 1, then:
     * For receipient to correctly index arr[1], arr[2], ..., he shall use
     * (bytesPerField). I.e.:
     *
     *      For 0 <= i < numFields,
     *      arr[i] starts at   (packet + offsetField0) +   i   * bytesPerField,
     *      arr[i] ends before (packet + offsetField0) + (i+1) * bytesPerField.
     *      You can use this.offsetOfField(i).
     *
     * The recipient shall _not_ rely on the part of the packet that
     * starts at packet (offsetField0) and goes to the packet length in bytes,
     * dividing it by numFields, even though both of these possibilities
     * should match. Recipients may consider packets invalid if those don't
     * match.
     *
     * Recipients must always assume that the sender made bytesPerField
     * larger than the recipient needs, and thus the packet also becomes
     * larger by (the excess per field times numFields). Recipients shall
     * index according to bytesPerField and ignore any excess bytes at
     * end of each field. This is to make the packet format future-proof
     * when newer versions need longer structs.
     *
     * Recipients may reject packets with smaller bytesPerField than they need.
     */
    short offsetField0 = len; // Offset in bytes from start of packet header
    short numFields;
    short bytesPerField;

    int offsetOfField(in int index) const pure nothrow @safe @nogc
    in {
        assert (index >= 0);
        assert (index <= numFields);
    }
    do {
        return offsetField0 + index * bytesPerField;
    }

    void serializeTo(ref ubyte[len] buf) const pure nothrow @nogc
    {
        buf[0] = packetId;
        buf[1] = 0; // Reserved for a future sub-packetID. Unused as of 2022.
        buf[2 .. 4] = subjectsRoom.nativeToBigEndian!short;
        buf[4 .. 6] = subject.nativeToBigEndian!short;
        buf[6 .. 8] = offsetField0.nativeToBigEndian!short;
        buf[8 .. 10] = numFields.nativeToBigEndian!short;
        buf[10 .. 12] = bytesPerField.nativeToBigEndian!short;
        buf[12 .. 16] = 0; // Reserved for a future int, possibly per-packetID.
    }

    this(ref const(ubyte[len]) buf) pure nothrow @nogc
    {
        packetId = buf[0];
        // buf[1] is reserved, see serializeTo.
        subjectsRoom = Room(0xFF & bigEndianToNative!short(buf[2 .. 4]));
        subject = PlNr(0xFF & bigEndianToNative!short(buf[4 .. 6]));
        offsetField0 = bigEndianToNative!short(buf[6 .. 8]);
        numFields = bigEndianToNative!short(buf[8 .. 10]);
        bytesPerField = bigEndianToNative!short(buf[10 .. 12]);
        // buf[12 .. 16] is reserved, see serializeTo.
    }
}

template isSerializable(ElementType) {
    enum bool isSerializable = is(ElementType == struct)
        && is(typeof(ElementType.len) : int)
        && is(typeof(ElementType.serializeTo));
}

alias NeckPacket(NeckType) = NeckWithArrayPacket!(NeckType, void);
alias ArrayPacket(ElementType) = NeckWithArrayPacket!(void, ElementType);

struct NeckWithArrayPacket(
    NeckType,
    ArrayElemType,
)
if ((isSerializable!NeckType || is(NeckType == void))
    && (isSerializable!ArrayElemType || is(ArrayElemType == void))) {
public:
    ubyte packetId;
    Room subjectsRoom;
    PlNr subject;
    static if (hasNeck) { NeckType neck; }
    static if (hasArr) { ArrayElemType[] arr; }

    int len() const pure nothrow @safe @nogc
    {
        int ret = PacketHeader2022.len;
        static if (hasNeck) {
            ret += neck.len;
        }
        static if (hasArr) {
            ret += (arr.length & 0x7FFF) * ArrayElemType.len;
        }
        return ret;
    }

    const(PacketHeader2022) header() const pure nothrow @safe @nogc
    {
        PacketHeader2022 ret;
        ret.packetId = packetId;
        ret.subject = subject;
        ret.subjectsRoom = subjectsRoom;
        ret.offsetField0 = delegate short() {
            static if (hasNeck) { return (ret.len + NeckType.len) & 0x7FFF; }
            else               { return ret.len & 0x7FFF; }
        }();
        ret.numFields = delegate short() {
            static if (hasArr) { return arr.length & 0x7FFF; }
            else               { return 0; }
        }();
        ret.bytesPerField = delegate short() {
            static if (hasArr) { return ArrayElemType.len & 0x7FFF; }
            else               { return 0; }
        }();
        return ret;
    }

    void setHeader(in ubyte paId, in Room ofSubject, in PlNr subj)
    {
        packetId = paId;
        subject = subj;
        subjectsRoom = ofSubject;
    }

    this(in ubyte[] buf) pure
    {
        enforce(buf.length >= PacketHeader2022.len);
        auto hea = PacketHeader2022(buf[0 .. PacketHeader2022.len]);
        packetId = hea.packetId;
        subject = hea.subject;
        subjectsRoom = hea.subjectsRoom;
        static if (hasNeck) {
            enforce(buf.length >= hea.len + NeckType.len);
            enforce(hea.offsetOfField(0) >= buf.length);
            neck = NeckType(buf[hea.len .. hea.offsetOfField(0)]);
        }
        static if (hasArr) {
            arr = [];
            for (int i = 0; i < hea.numFields
                && hea.offsetOfField(i+1) <= buf.length; ++i
            ) {
                arr ~= ArrayElemType(
                    buf[hea.offsetOfField(i) .. hea.offsetOfField(i+1)]);
            }
        }
    }

    void serializeTo(ubyte[] buf) const pure nothrow @nogc
    in {
        assert(buf.length >= len);
    }
    do {
        const hea = header();
        hea.serializeTo(buf[0 .. hea.len]);
        static if (hasNeck) {
            ubyte[NeckType.len] temp;
            neck.serializeTo(temp);
            buf[hea.len .. hea.offsetOfField(0)] = temp;
        }
        static if (hasArr) {
            for (int i = 0; i < arr.length; ++i) {
                ubyte[ArrayElemType.len] temp;
                arr[i].serializeTo(temp);
                buf[hea.offsetOfField(i) .. hea.offsetOfField(i+1)] = temp;
            }
        }
    }

private:
    enum bool hasNeck = !is(NeckType == void);
    enum bool hasArr = !is(ArrayElemType == void);
}
