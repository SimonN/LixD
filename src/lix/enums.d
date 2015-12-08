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
        return str.toUpper.to!Ac;
    catch (Exception)
        return Ac.MAX;
}

string acToString(in Ac ac)
{
    return ac.to!string.asUpperCase.to!string;
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
    assert (acToString(Ac.FALLER) == "FALLER");
    assert (stringToAc("builDER") == Ac.BUILDER);
    assert (styleToString(Style.yellow) == "Yellow");
    assert (stringToStyle("ORAnge") == Style.orange);
    assert (stringToStyle("Not in there") == Style.garden);
}

enum Ac : ubyte {
    NOTHING,
    FALLER,
    TUMBLER,
    STUNNER,
    LANDER,
    SPLATTER,
    BURNER,
    DROWNER,
    EXITER,
    WALKER,
    RUNNER,

    CLIMBER,
    ASCENDER,
    FLOATER,
    EXPLODER,
    EXPLODER2,
    BLOCKER,
    BUILDER,
    SHRUGGER,
    PLATFORMER,
    SHRUGGER2,
    BASHER,
    MINER,
    DIGGER,

    JUMPER,
    BATTER,
    CUBER,

    MAX
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
