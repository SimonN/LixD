module lix.enums;

import std.algorithm;
import std.array;
import std.conv;
import std.uni;

enum int exOffset = 16; // offset of the effective coordinate of the lix
enum int eyOffset = 26; // sprite from the top left corner

enum int skillInfinity  = -1;
enum int skillNumberMax = 999;

enum int builderBrickXl  = 12;
enum int platformLongXl  = 8; // first brick
enum int platformShortXl = 6; // all bricks laid down while kneeling
enum int brickYl         = 2;

enum UpdateOrder {
    peaceful, // Least priority -- cannot affect other lix. Updated last.
    adder,    // Worker that adds terrain. Adders may add in fresh holes.
    remover,  // Worker that removes terrain.
    blocker,  // Affects lixes directly other than by flinging -- blocker.
    flinger,  // Affects lixes directly by flinging. Updated first.
}

nothrow bool isPloder(in Ac ac) pure
{
    return ac == Ac.imploder || ac == Ac.exploder;
}

nothrow Ac stringToAc(in string str)
{
    try {
        string lower = str.toLower;
        return lower == "exploder"  ? Ac.imploder
            :  lower == "exploder2" ? Ac.exploder : lower.to!Ac;
    }
    catch (Exception)
        return Ac.max;
}

string acToString(in Ac ac)
{
    return ac == Ac.exploder ? "EXPLODER2"
        :  ac == Ac.imploder ? "EXPLODER" : ac.to!string.toUpper;
}

auto acToNiceCase(in Ac ac)
{
    string s = ac.to!string;
    if (s[$-1] == '2') // shrugger2
        s = s[0 .. $-1];
    return s.asCapitalized;
}

nothrow Style stringToStyle(in string str)
{
    try
        return str.toLower.to!Style;
    catch (Exception)
        return Style.garden;
}

string styleToString(in Style sty)
{
    return sty.to!string.asCapitalized.to!string;
}

unittest {
    assert (acToString(Ac.faller) == "FALLER");
    assert (stringToAc("builDER") == Ac.builder);
    assert (stringToAc("expLoder") == Ac.imploder);
    assert (stringToAc("eXploDer2") == Ac.exploder);
    assert (acToString(Ac.imploder) == "EXPLODER");
    assert (acToString(Ac.exploder) == "EXPLODER2");
    assert (styleToString(Style.yellow) == "Yellow");
    assert (stringToStyle("ORAnge") == Style.orange);
    assert (stringToStyle("Not in there") == Style.garden);
    assert (acToNiceCase(Ac.faller).equal("Faller"));
    assert (acToNiceCase(Ac.shrugger2).equal("Shrugger"));
    assert (acToNiceCase(Ac.imploder).equal("Imploder"));
}

enum Ac : ubyte {
    nothing,
    faller,
    tumbler,
    stunner,
    lander,
    splatter,
    burner,
    drowner,
    exiter,
    walker,
    runner,

    climber,
    ascender,
    floater,
    imploder,
    exploder,
    blocker,
    builder,
    shrugger,
    platformer,
    shrugger2,
    basher,
    miner,
    digger,

    jumper,
    batter,
    cuber,

    max
}

enum Style : ubyte {
    garden,
    highlight,
    neutral,
    red,
    orange,
    yellow,
    green,
    blue,
    purple,
    grey,
    black,
    max
}
