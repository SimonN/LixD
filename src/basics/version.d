module basics.versioning;

/* Lix versioning should be done like semantic versioning.
 *
 * Whenever physics or the networking protocol change, increase minor version.
 * Patches that do not break compatibility should only increase patch version.
 */

import std.conv;
import std.string;

private immutable _gameVersion     = Version(0, 2, 29);
private bool      _versionIsStable = false;

const(Version) gameVersion()     { return _gameVersion;     }
bool           versionIsStable() { return _versionIsStable; }



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
        int*[] next = [&major, &minor, &patch];
        foreach (c; src) {
            if (next.length == 0) {
                break;
            }
            else if (c >= '0' && c <= '9') {
                *next[0] *= 10;
                *next[0] += (c - '0');
            }
            else if (c == '.') {
                next = next[1 .. $];
            }
        }
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
}
