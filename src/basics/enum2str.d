module basics.enum2str;

/*
 * std.conv.to!string(YourEnum) is expensive at CTFE.
 * Also, it throws and it allocates.
 *
 * To convert a Lang to its ID name at CTFE, we compute the strings once here,
 * which takes less time during compilation than instantiating std.conv.to,
 * and return the precomputed values. It's all pure nothrow @safe @nogc.
 */
string toString(E)(in E value) pure nothrow @safe @nogc
    if (is (E == enum))
{
    return Cache!E.enumToString(value);
}

auto toEnum(E)(in string src) pure nothrow @safe @nogc
    if (is (E == enum))
{
    return Cache!E.stringToEnum(src);
}

auto toEnumOr(E)(in string src, in E fallback) pure nothrow @safe @nogc
    if (is (E == enum))
{
    auto candidate = Cache!E.stringToEnum(src);
    return candidate.success ? candidate.value : fallback;
}

struct ToEnumResult(E)
    if (is (E == enum))
{
    bool success;
    E value;
}

///////////////////////////////////////////////////////////////////////////////
private:

template Cache(E)
    if (is (E == enum))
{
    string enumToString(in E value) pure nothrow @safe @nogc
    {
        return precomputedStrings[value];
    }

    ToEnumResult!E stringToEnum(in string src) pure nothrow @safe @nogc
    {
        for (size_t i = 0; i < E.max + 1; ++i) {
            if (precomputedStrings[i] == src) {
                return ToEnumResult!E(true, cast (E) i);
            }
        }
        return ToEnumResult!E(false, E.init);
    }

private:
    static immutable string[E.max + 1] precomputedStrings = generateStrings();

    string[E.max + 1] generateStrings() pure nothrow @safe @nogc {
        typeof(return) ret;
        static foreach (i; 0 .. E.max + 1) {
            mixin("ret[", i, "] = __traits(allMembers, E)[", i, "];");
        }
        return ret;
    }
}

@safe @nogc unittest {
    enum Fruit { apple, banana };
    assert (Fruit.apple.toString == "apple");
    assert (Fruit.banana.toString == "banana");
    assert ("apple".toEnum!Fruit.success);
    assert ("banana".toEnum!Fruit.success);
    assert (! "plum".toEnum!Fruit.success);
    assert ("apple".toEnumOr(Fruit.banana) == Fruit.apple);
    assert ("banana".toEnumOr(Fruit.apple) == Fruit.banana);
    assert ("plum".toEnumOr(Fruit.banana) == Fruit.banana);
}
