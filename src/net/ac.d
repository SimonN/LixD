module net.ac;

/* Activity enum for the lixes.
 * This is in net/, not in lix/, because it has to travel over the network.
 */

import std.algorithm;
import std.array;
import std.conv;
import std.uni;

enum int skillInfinity  = -1;
enum int skillNumberMax = 999;

enum int builderBrickXl  = 12;
enum int platformLongXl  = 8; // first brick
enum int platformShortXl = 6; // all bricks laid down while kneeling
enum int brickYl         = 2;

enum PhyuOrder {
    peaceful, // Least priority -- cannot affect other lix. Phyud last.
    adder,    // Worker that adds terrain. Adders may add in fresh holes.
    remover,  // Worker that removes terrain.
    blocker,  // Affects lixes directly other than by flinging -- blocker.
    flinger,  // Affects lixes directly by flinging. Phyud first.
}

pure:
@safe:

bool isPloder(in Ac ac) nothrow @nogc
{
    return ac == Ac.imploder || ac == Ac.exploder;
}

bool isPermanentAbility(in Ac ac) nothrow @nogc
{
    return ac == Ac.climber || ac == Ac.floater || ac == Ac.runner;
}

bool isLeaving(in Ac ac) nothrow @nogc
{
    return ac == Ac.nothing
        || ac == Ac.splatter
        || ac == Ac.burner
        || ac == Ac.drowner
        || ac == Ac.exiter
        || ac == Ac.cuber;
}

bool appearsInPanel(in Ac ac) nothrow @nogc
{
    return ac == Ac.walker
        || ac == Ac.runner
        || ac == Ac.climber
        || ac == Ac.floater
        || ac == Ac.imploder
        || ac == Ac.exploder
        || ac == Ac.blocker
        || ac == Ac.builder
        || ac == Ac.platformer
        || ac == Ac.basher
        || ac == Ac.miner
        || ac == Ac.digger
        || ac == Ac.jumper
        || ac == Ac.batter
        || ac == Ac.cuber;
}

int acToSkillIconXf(in Ac ac) nothrow @nogc
{
    // We had xf = _ac before instead of xf = _ac - Ac.walker.
    // But the smallest skill in the panel is walker.
    // We can remove empty boxes from the image, saving VRAM & speed.
    return ac - Ac.walker
        - (ac > Ac.ascender) - (ac > Ac.shrugger) - (ac > Ac.shrugger2);
}

Ac stringToAc(in string str) nothrow
{
    try {
        string lower = str.toLower;
        return lower == "exploder"  ? Ac.imploder
            :  lower == "exploder2" ? Ac.exploder : lower.to!Ac;
    }
    catch (Exception)
        return Ac.nothing;
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

unittest {
    assert (acToString(Ac.faller) == "FALLER");
    assert (stringToAc("builDER") == Ac.builder);
    assert (stringToAc("expLoder") == Ac.imploder);
    assert (stringToAc("eXploDer2") == Ac.exploder);
    assert (acToString(Ac.imploder) == "EXPLODER");
    assert (acToString(Ac.exploder) == "EXPLODER2");
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
}
