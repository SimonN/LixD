module net.versioning;

/* Lix versioning should be done like semantic versioning.
 *
 * Whenever physics or the networking protocol change, increase minor version.
 * Patches that do not break compatibility should only increase patch version.
 */

import std.algorithm;
import std.bitmanip;
import std.conv;
import std.range;
import std.string;

private immutable _gameVersion = Version(0, 10, 18);
const(Version) gameVersion() { return _gameVersion; }

struct Version {
    int major;
    int minor;
    int patch;

    this(int major, int minor, int patch) pure nothrow @safe @nogc
    {
        this.major = major;
        this.minor = minor;
        this.patch = patch;
    }

    // parse version string a la "1.234.56"
    this(in string src) pure @safe
    {
        int* next = &major;
        foreach (num; src.splitter('.').take(3)) {
            *next = num.toIntPossiblyNegative;
            next = (next == &major ? &minor : &patch);
        }
        // A4/C++ Lix used dates as versioning numbers, and saved the
        // version as one integer, e.g., 2015010100 for 2015-01-01 with patch
        // number 00. These dates fit into the lower 31 bit of a signed int.
        // Versions like that should come before any A5/D version.
        if (major < -2000_00_00_00 || major > 2000_00_00_00)
            major = minor = patch = 0;
    }

    @property toString() const
    {
        return "%d.%d.%d".format(major, minor, patch);
    }

    @property string compatibles() const
    {
        return "%d.%d.*".format(major, minor);
    }

    const pure nothrow @safe @nogc {
        int opCmp(in Version rhs)
        {
            return major > rhs.major ? 1 : major < rhs.major ? -1
                :  minor > rhs.minor ? 1 : minor < rhs.minor ? -1
                :  patch > rhs.patch ? 1 : patch < rhs.patch ? -1 : 0;
        }

        bool compatibleWith(in Version rhs) const pure nothrow @safe @nogc
        {
            return major == rhs.major
                && minor == rhs.minor;
        }

        bool isRelease() { return major >= 0 && minor >= 0 && patch >= 0; }
        bool isExperimental() { return ! isRelease; }
    }

    enum len = 12;
    void serializeTo(ref ubyte[len] buf) const pure nothrow @nogc
    {
        buf[0 .. 4] = nativeToBigEndian!int(major);
        buf[4 .. 8] = nativeToBigEndian!int(minor);
        buf[8 .. 12] = nativeToBigEndian!int(patch);
    }

    this(ref const(ubyte[len]) buf) pure nothrow @nogc
    {
        major = bigEndianToNative!int(buf[0 .. 4]);
        minor = bigEndianToNative!int(buf[4 .. 8]);
        patch = bigEndianToNative!int(buf[8 .. 12]);
    }
}

private int toIntPossiblyNegative(in string s) pure nothrow @safe @nogc
{
    int ret = 0;
    bool minusSeen = false;
    foreach (c; s) {
        if (c == '-') {
            minusSeen = true;
        }
        else if (c >= '0' || c <= '9') {
            ret *= 10;
            ret += (c - '0');
        }
    }
    return minusSeen ? -ret : ret;
}

unittest
{
    auto a = Version(12, 34, 56);
    auto b = Version("12.34.56");
    auto c = Version("12.34.999");
    auto d = Version("12.999.56");
    auto e = Version("2015010100");

    assert (a == b);
    assert (c >  b);
    assert (c.compatibleWith(b) && b.compatibleWith(c));
    assert (c >  Version());
    assert (c <  d);
    assert (! d.compatibleWith(b));
    assert (e == Version());
    assert (! e.compatibleWith(a));

    ubyte[Version.len] buf;
    a.serializeTo(buf);
    assert (Version(buf) == a);
}

unittest {
    assert (Version("123.456") == Version(123, 456, 0), "parsing fewer nums");

    auto neg = Version("-12.--3-4.56");
    assert (neg.major == -12);
    assert (neg.minor == -34);
    assert (neg.patch == 56);
}
