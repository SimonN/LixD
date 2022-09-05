module physics.handimrg;

import std.algorithm;
import std.range;

import net.handicap;
import net.profile;
import net.plnr;
import net.style;

struct MergedHandicap {
    Handicap merged;
    alias merged this;

    this(R)(R inputs) pure nothrow @safe @nogc if (isInputRange!R
        && is(ElementType!R : const(Handicap))
        && !is(ElementType!R : const(MergedHandicap))
    ) {
        if (inputs.empty) {
            assert (merged == Handicap.init);
            return;
        }
        if (inputs.save.walkLength == 1) {
            merged = inputs.front;
            return;
        }
        initialLix = inputs.save.map!(h => h.initialLix).arithmeticMean;
        initialSkills = inputs.save.map!(h => h.initialSkills).arithmeticMean;
        extraSkills = inputs.save.map!(h => h.extraSkills).arithmeticMean;
        delayInPhyus = inputs.save.map!(h => h.delayInPhyus).arithmeticMean;
        score = inputs.save.map!(h => h.score).arithmeticMean;
        static assert (__traits(allMembers, Handicap).length == 9,
            "Are all Handicap fields merged correctly into MergedHandicap?");
    }
}

MergedHandicap[Style] mergeHandicaps(in Profile[PlNr] unmerged) pure nothrow @safe
{
    MergedHandicap[Style] ret;
    foreach (styleToAdd; unmerged.byValue.map!(prof => prof.style)) {
        if (styleToAdd in ret) {
            continue;
        }
        ret[styleToAdd] = MergedHandicap(unmerged.byValue
            .filter!(prof => prof.style == styleToAdd)
            .map!(prof => prof.handicap));
    }
    return ret;
}

///////////////////////////////////////////////////////////////////////////////
private: //////////////////////////////////////////////////////////////////////

short arithmeticMean(R)(R xs) pure nothrow @safe @nogc
    if (isInputRange!R && is(ElementType!R : const(short)))
{
    if (xs.empty) {
        return 0;
    }
    return (xs.save.sum() / xs.save.walkLength) & 0x7FFF;
}

unittest {
    short[4] xs = [1, 2, 3, 0];
    assert (xs[].arithmeticMean == 1, "(1+2+3+0) / 4 == 1 using int math");
}

Fraction arithmeticMean(R)(R fractions) pure nothrow @safe @nogc
    if (isInputRange!R && is(ElementType!R : const(Fraction)))
{
    if (fractions.empty) {
        return Fraction(0, 1); // Arithmetic mean is the empty sum: 0.
    }
    long den = productOfDenominators(fractions.save);
    long num = 0;
    foreach (fr; fractions.save) {
        num += fr.numerator * (den / fr.denominator);
    }
    removeCommonPrimesInPlace(num, den);

    // Arithmetic mean is the sum divided by the number of summed elements.
    den *= fractions.save.walkLength;
    removeCommonPrimesInPlace(num, den);

    // Round to fit into Fraction
    static assert (is (byte == typeof(fractions.front.numerator())));
    static assert (is (byte == typeof(fractions.front.denominator())));
    while (num < byte.min || num > byte.max || den > byte.max) {
        num /= 2;
        den /= 2;
    }
    return Fraction(num.toByteNogc, den.toByteNogc);
}

long productOfDenominators(R)(R fractions) pure nothrow @safe @nogc
    if (isInputRange!R && is(ElementType!R : const(Fraction)))
{
    long ret = 1;
    foreach (fr; fractions.save) {
        ret *= fr.denominator;
    }
    return ret;
}

byte toByteNogc(in long x) pure nothrow @safe @nogc
{
    return x > 0 ? (x & 0x7F) : -((-x) & 0x7F);
}

unittest {
    Fraction[] frs = [ Fraction(1, 2), Fraction(3, 4), Fraction(5, 6) ];
    assert (productOfDenominators(frs) == 2*4*6);
    assert (arithmeticMean(frs) == Fraction(25, 36),
        "Arithmetic mean should be (1/2 + 3/4 + 5/6) / 3 == 25/36");
}

// Does it guard against byte overflow?
unittest {
    auto frs = iota(100, 108).map!(i =>
        // A fraction like 102/103, slightly below 1/1:
        Fraction(i & 0x7F, (i + 1) & 0x7F));
    immutable mean = arithmeticMean(frs);
    assert (mean.numerator > 0);
    assert (mean.numerator < mean.denominator); // Less than 1.
    assert (4 * mean.numerator > 3 * mean.denominator); // Bigger than 3/4.
}
