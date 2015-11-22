module lix.enums;

enum int exOffset = 16; // offset of the effective coordinate of the lix
enum int eyOffset = 26; // sprite from the top left corner

enum int skillInfinity = -1;  // for SkillButtons
enum int skill_nr_max  = 999; // for SkillButtons

Ac stringToAc(in string str)
{
    foreach (key; acStrings.byKey()) {
        if (acStrings[key] == str) return key;
    }
    return Ac.MAX;
}

string acToString(in Ac ac)
{
    assert (ac in acStrings);
    return acStrings[ac];
}

Style stringToStyle(in string str)
{
    foreach (key; styleStrings.byKey) {
        if (styleStrings[key] == str) return key;
    }
    return Style.GARDEN;
}

string styleToString(in Style st)
{
    assert (st in styleStrings);
    return styleStrings[st];
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
    GARDEN,
    NEUTRAL,
    RED,
    ORANGE,
    YELLOW,
    GREEN,
    BLUE,
    PURPLE,
    GREY,
    BLACK,
    MAX
}

private immutable string[Ac]    acStrings;
private immutable string[Style] styleStrings;

static this()
{
    acStrings = [
        Ac.NOTHING    : "NOTHING",
        Ac.FALLER     : "FALLER",
        Ac.TUMBLER    : "TUMBLER",
        Ac.STUNNER    : "STUNNER",
        Ac.LANDER     : "LANDER",
        Ac.SPLATTER   : "SPLATTER",
        Ac.BURNER     : "BURNER",
        Ac.DROWNER    : "DROWNER",
        Ac.EXITER     : "EXITER",
        Ac.WALKER     : "WALKER",
        Ac.RUNNER     : "RUNNER",

        Ac.CLIMBER    : "CLIMBER",
        Ac.ASCENDER   : "ASCENDER",
        Ac.FLOATER    : "FLOATER",
        Ac.EXPLODER   : "EXPLODER",
        Ac.EXPLODER2  : "EXPLODER2",
        Ac.BLOCKER    : "BLOCKER",
        Ac.BUILDER    : "BUILDER",
        Ac.SHRUGGER   : "SHRUGGER",
        Ac.PLATFORMER : "PLATFORMER",
        Ac.SHRUGGER2  : "SHRUGGER2",
        Ac.BASHER     : "BASHER",
        Ac.MINER      : "MINER",
        Ac.DIGGER     : "DIGGER",

        Ac.JUMPER     : "JUMPER",
        Ac.BATTER     : "BATTER",
        Ac.CUBER      : "CUBER",
        Ac.MAX        : "MAX"
    ];

    styleStrings = [
        Style.GARDEN  : "Garden",
        Style.NEUTRAL : "Neutral",
        Style.RED     : "Red",
        Style.ORANGE  : "Orange",
        Style.YELLOW  : "Yellow",
        Style.GREEN   : "Green",
        Style.BLUE    : "Blue",
        Style.PURPLE  : "Purple",
        Style.GREY    : "Grey",
        Style.BLACK   : "Black"
    ];
}
