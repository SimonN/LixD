module net.style;

import std.conv;
import std.uni;

enum Style : ubyte {
    garden, highlight, neutral,
    red, orange, yellow, green, blue, purple, grey, black,
    max
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

bool goodForMultiplayer(in Style st) pure nothrow @safe @nogc
{
    return st >= Style.red && st < Style.max;
}

unittest {
    assert (styleToString(Style.yellow) == "Yellow");
    assert (stringToStyle("ORAnge") == Style.orange);
    assert (stringToStyle("Not in there") == Style.garden);
}
