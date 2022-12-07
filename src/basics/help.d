module basics.help;

import std.array;
import std.algorithm;
import std.conv;
import std.exception;
import std.math;
import std.string;
import std.uni;
import std.utf;

pure int even(in int x) { return x - (x & 1); }

unittest {
    assert (even( 5) ==  4);
    assert (even(-5) == -6);
    assert (even(-6) == -6);
}

// mod function that always returns values in 0 .. modulo
int positiveMod(in int nr, in int modulo) pure nothrow @safe @nogc
{
    if (modulo <= 0) return 0;
    immutable int normalMod = nr % modulo;
    if (normalMod >= 0) return normalMod;
    else                return normalMod + modulo;
}

unittest {
    assert (          (-5 % 3) == -2);
    assert (positiveMod(-5, 3) ==  1);
    assert (positiveMod( 5, 3) ==  2);
}

pure int roundTo(in int nr, in int grid)
{
    assert (grid >= 1);
    if (grid == 1)
        return nr;
    return nr + grid/2 - positiveMod(nr + grid/2, grid);
}

unittest {
    assert ([-12, -11, -10, -9, -8, -7, -6, -5].all!(i => i.roundTo(8) == -8));
    assert ([-4, -3, -2, -1, 0, 1, 2, 3]       .all!(i => i.roundTo(8) ==  0));
    assert ([4, 5, 6, 7, 8, 9, 10, 11]         .all!(i => i.roundTo(8) ==  8));
}

pure int roundUpTo(in int nr, in int grid)
{
    assert (grid >= 1);
    if (grid == 1)
        return nr;
    return nr + positiveMod(-nr, grid);
}

unittest {
    assert ([-5, -4, -3].all!(i => i.roundUpTo(3) == -3));
    assert ([-2, -1,  0].all!(i => i.roundUpTo(3) ==  0));
    assert ([ 1,  2,  3].all!(i => i.roundUpTo(3) ==  3));
}

// Phobos has rounding, but tiebreaks only either to the even integer,
// or away from zero. I want to tiebreak to the larger integer.
int roundInt(F)(in F f) pure nothrow @safe @nogc
    if (is (F : float))
{
    return cast (int) (f + 0.5f).floor.rndtol;
}

int ceilInt(F)(in F f) pure nothrow @safe @nogc
    if (is (F : float))
{
    return cast (int) f.ceil.rndtol;
}

int floorInt(F)(in F f) pure nothrow @safe @nogc
    if (is (F : float))
{
    return cast (int) f.floor.rndtol;
}

unittest {
    assert (roundInt(-1.3f) == -1);
    assert (roundInt(-1.5f) == -1);
    assert (roundInt(-1.5001f) == -2);
    assert (roundInt(-1.7f) == -2);
}

/*
 * Removing the last or first UTF character of a narrow string.
 * backspace() returns a substring of the passed string.
 */
enum CutAt {
    end,
    beginning,
}

static string backspace(in string str, in CutAt near) pure nothrow @safe
{
    if (str.length == 0) {
        return null;
    }
    final switch (near) {
    case CutAt.end:
        try {
            return str[0 .. $ - std.utf.strideBack(str, str.length)];
        }
        catch (Exception) {
            return str[0 .. $ - 1];
        }
    case CutAt.beginning:
        try {
            return str[std.utf.stride(str, 0) .. $];
        }
        catch (Exception) {
            return str[1 .. $];
        }
    }
}

unittest {
    assert (backspace("", CutAt.end) == "");
    assert (backspace("", CutAt.beginning) == "");
    assert (backspace("hello", CutAt.end) == "hell");
    assert (backspace("hello", CutAt.beginning) == "ello");
}

// Remove dchars that don't satisfy pred, return newly allocated string.
// If the entire input satisfies pred, return old string instead of allocating.
pure string pruneString(in string input, bool function(dchar) pure pred)
{
    version (assert)
        std.utf.validate(input);
    return input.all!pred ? input : input.filter!pred.to!string;
}

pure string escapeStringForFilename(in string s)
{
    return pruneString(s, c => ! c.isControl && ! "\"*/:<>?\\|".canFind(c));
}

unittest {
    assert (escapeStringForFilename("hallo") == "hallo");
    assert (escapeStringForFilename("no\u0000null") == "nonull");
    assert (escapeStringForFilename("don't/use/dirs") == "don'tusedirs");
    assert (escapeStringForFilename("Ä ö Ü ß") == "Ä ö Ü ß");
    assert (escapeStringForFilename(":D ^_^ :-|") == "D ^_^ -");
    assert (escapeStringForFilename(".,123") == ".,123");
    assert (escapeStringForFilename("リッくス") == "リッくス");
}

pure nothrow int
len(T)(in T[] arr)
{
    // Arrays with more than 2^^31 entries are bugs. Let's not call to!int, but
    // chop off the big bits of the size_t (= uint or ulong). It's the same
    // effect, but doesn't check if it has to throw.
    return arr.length & 0x7F_FF_FF_FF;
}

@property T[]
clone(T)(in const(T)[] arr)
    if (is (T == class) || is (T == struct))
{
    static if (is (T == struct) && is (const(T) : T))
        return arr.dup;
    else {
        T[] ret;
        ret.length = arr.length;
        for (int i = 0; i < arr.length; ++i)
            ret[i] = arr[i].clone();
        return ret;
    }
}
