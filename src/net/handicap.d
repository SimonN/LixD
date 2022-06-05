module net.handicap;

import std.bitmanip;

/*
 * Handicap: We're defining this as a struct of 16 bytes without padding,
 * to have room for expansion in the serialized representation.
 *
 * Handicap in multiplayer means:
 * scale() the handicapped player's initial lix count.
 * For each skill, scale() the number in the handicapped player's skillbar.
 */
struct Handicap {
pure nothrow @safe @nogc:
    /*
     * Your initial number of lix is multiplied with this.
     * If the result is a fraction, round away from zero to make it integer.
     */
    Fraction initialLix;

    /*
     * Each of your initial skills is multiplied with this.
     * If the result is a fraction, round away from zero to make it integer.
     */
    Fraction initialSkills;

    /*
     * You get each skill this extra number of times, even those that are
     * usually 0 in the panel. If the level gives 0 ploders, extraSkills
     * still depends on the ploder property of the level which ploder you get.
     */
    short extraSkills = 0;

    /*
     * Your first lix will spawn later by this number of phyus, and then
     * every lix thereafter will spawn by the usual spawn interval after
     * the previous one.
     */
    short delayInPhyus = 0;

    /*
     * Your score gets multiplied by this.
     * Fractions are not rounded. A score of 7.5 (save 15 lix under a 1/2
     * score handicap) beats a score of 7 but loses to a score of 8.
     */
    Fraction score;

    ubyte[6] uninterpreted;

    enum int len = 16; // Length in bytes when serialized
    static assert(this.sizeof == len, "Should satisfy this for forward compat,"
        ~ " even if not all fields are used by any given version. The server"
        ~ " can then manage all fields without interpreting.");

    this(ref const (ubyte[len]) source) pure nothrow @safe @nogc
    {
        static assert (Fraction.len == 2);
        initialLix = Fraction(source[0 .. 2]);
        initialSkills = Fraction(source[2 .. 4]);
        extraSkills = source[4 .. 6].bigEndianToNative!short;
        delayInPhyus = source[6 .. 8].bigEndianToNative!short;
        score = Fraction(source[8 .. 10]);
        uninterpreted[0 .. $] = source[len - uninterpreted.sizeof .. len];
    }

    void serializeTo(ref ubyte[len] buf) const pure nothrow @safe @nogc
    {
        initialLix.serializeTo(buf[0 .. 2]);
        initialSkills.serializeTo(buf[2 .. 4]);
        buf[4 .. 6] = extraSkills.nativeToBigEndian!short;
        buf[6 .. 8] = delayInPhyus.nativeToBigEndian!short;
        score.serializeTo(buf[8 .. 10]);
        buf[len - uninterpreted.sizeof .. len] = uninterpreted[0 .. $];
    }
}

struct Fraction {
pure nothrow @safe @nogc:
private:
    T _mul = 1;
    T _div = 1;

    alias T = byte;
    enum len = 2 * T.sizeof;

public:
    this(in T numerator, in T denominator)
    {
        _mul = numerator;
        _div = denominator;
        simplify();
    }

    this(ref const (ubyte[len]) source)
    {
        _mul = source[0 .. len/2].bigEndianToNative!T;
        _div = source[len/2 .. len].bigEndianToNative!T;
        simplify();
    }

    void serializeTo(ref ubyte[len] buf) const
    {
        buf[0 .. len/2] = _mul.nativeToBigEndian!T;
        buf[len/2 .. len] = _div.nativeToBigEndian!T;
    }

    T numerator() const { return _mul; }
    T denominator() const { return _div; }

    int scale(int input) const
    {
        if (input < 0 || _div == 0) {
            return input; // E.g., input == -1 means infinite skills.
        }
        immutable int roundAwayFromZero = _div + (_div > 0 ? -1 : 1);
        return (input * _mul + roundAwayFromZero) / _div;
    }

private:
    void simplify()
    {
        if (_div == 0) {
            _div = 1;
        }
        if (_div < 0) {
            _mul *= -1;
            _div *= -1;
        }
        if (_div == 1 || _mul == 1 || _mul == -1) {
            return; // Avoid the factor-cancelling loop for speed.
        }
        enum T[6] firstPrimes = [2, 3, 5, 7, 11, 13];
        static assert (T.max >= firstPrimes[$-2]^^2);
        static assert (T.max <  firstPrimes[$-1]^^2);
        foreach (T prime; firstPrimes[0 .. $-1]) {
            while (_mul % prime == 0 && _div % prime == 0) {
                _mul /= prime;
                _div /= prime;
            }
        }
    }
}

unittest {
    auto f = Fraction(5, 6);
    assert (f.scale(100) == 84);
    assert (f.scale(120) == 100);
}

unittest {
    enum L = Handicap.len;
    ubyte[L] arr = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
    ubyte[L] target = arr[] * 3;
    foreach (size_t i; 0 .. L) {
        assert (arr[i] * 3 == target[i]);
    }
    auto handi = Handicap(arr);
    handi.serializeTo(target);
    foreach (size_t i; 0 .. L) {
        assert (arr[i] == target[i], "Handicap may not contain padding.");
    }
}
