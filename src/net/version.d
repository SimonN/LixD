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

private immutable _gameVersion = Version(0, 9, 45);
const(Version) gameVersion() { return _gameVersion; }

struct Version {
    int major;
    int minor;
    int patch;

    this(int major, int minor, int patch)
    {
        this.major = major;
        this.minor = minor;
        this.patch = patch;
    }

    // parse version string a la "1.234.56"
    this(in string src)
    {
        src.splitter('.')
            .take(3)
            .map!toIntByParsingOnlyDigits
            .zip(only(&major, &minor, &patch))
            .each!"*a[1] = a[0]";
        // A4/C++ Lix used dates as versioning numbers, and saved the
        // version as one integer, e.g., 2015010100 for 2015-01-01 with patch
        // number 00. These dates fit into the lower 31 bit of a signed int.
        // Versions like that should come before any A5/D version.
        if (major >= 2006000000)
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

    int opCmp(in Version rhs) const
    {
        return major > rhs.major ? 1 : major < rhs.major ? -1
            :  minor > rhs.minor ? 1 : minor < rhs.minor ? -1
            :  patch > rhs.patch ? 1 : patch < rhs.patch ? -1 : 0;
    }

    bool compatibleWith(in Version rhs) const
    {
        return major == rhs.major
            && minor == rhs.minor;
    }

    enum len = 12;
    void serializeTo(ref ubyte[len] buf) const nothrow
    {
        buf[0 .. 4] = nativeToBigEndian!int(major);
        buf[4 .. 8] = nativeToBigEndian!int(minor);
        buf[8 .. 12] = nativeToBigEndian!int(patch);
    }

    this(ref const(ubyte[len]) buf)
    {
        major = bigEndianToNative!int(buf[0 .. 4]);
        minor = bigEndianToNative!int(buf[4 .. 8]);
        patch = bigEndianToNative!int(buf[8 .. 12]);
    }
}

private int toIntByParsingOnlyDigits(in string s) pure nothrow @safe @nogc
{
    int ret = 0;
    foreach (c; s) {
        if (c < '0' || c > '9') {
            continue;
        }
        ret *= 10;
        ret += (c - '0');
    }
    return ret;
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
}
