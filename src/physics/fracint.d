module physics.fracint;

import std.format;

import net.handicap;

struct FracInt {
    int raw;
    Fraction frac;

    const pure nothrow @nogc @safe {
        bool isInt()
        {
            return frac.denominator == 1 || raw % frac.denominator == 0;
        }

        T as(T)()
            if (is (T == int) || is (T == double))
        {
            static if (is (T == int)) {
                return frac.scale(raw);
            }
            else return raw * 1.0 * frac.numerator / frac.denominator;
        }

        int opCmp(in int rhs) { return opCmp(FracInt(rhs)); }
        int opCmp(in FracInt rhs)
        {
            immutable a =     raw *     frac.numerator * rhs.frac.denominator;
            immutable b = rhs.raw * rhs.frac.numerator *     frac.denominator;
            return a - b;
        }
    }

    string asText() const pure @safe
    {
        if (isInt) {
            return std.format.format!"%d"(as!int);
        }
        immutable intPart = (raw * frac.numerator) / frac.denominator;
        immutable properNumerator = (raw * frac.numerator) % frac.denominator;
        return std.format.format("%d.%s", intPart,
            subscripts[(properNumerator * 10) / frac.denominator]);
    }
}

private static immutable string[10] subscripts
    = ["₀", "₁", "₂", "₃", "₄", "₅", "₆", "₇", "₈", "₉"];

unittest {
    immutable x = FracInt(3);
    assert (x.frac.numerator == 1);
    assert (x.frac.denominator == 1);
    assert (x > FracInt(4, Fraction(2, 3)), "rhs is 8/3 == 2 + 2/3 < 3 == x");
}

unittest {
    assert (FracInt(4, Fraction(2, 7)).asText == "1.₁");
    assert (FracInt(5, Fraction(2, 7)).asText == "1.₄");
    assert (FracInt(6, Fraction(2, 7)).asText == "1.₇");
    assert (FracInt(7, Fraction(2, 7)).asText == "2");
}
