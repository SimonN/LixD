module lix.enums;

import std.array;
import std.conv;
import std.uni;

enum int exOffset = 16; // offset of the effective coordinate of the lix
enum int eyOffset = 26; // sprite from the top left corner

enum int skillInfinity  = -1;
enum int skillNumberMax = 999;

enum int builderBrickXl    = 12;
enum int platformerBrickXl = 8;
enum int brickYl           = 2;

nothrow Ac stringToAc(in string str)
{
    try
        return str.toLower.to!Ac;
    catch (Exception)
        return Ac.max;
}

string acToString(in Ac ac)
{
    return ac.to!string.toUpper;
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
    assert (styleToString(Style.yellow) == "Yellow");
    assert (stringToStyle("ORAnge") == Style.orange);
    assert (stringToStyle("Not in there") == Style.garden);
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
    exploder,
    exploder2,
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
