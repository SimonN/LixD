module lix.enums;

import basics.matrix;

const int exOffset = 16; // offset of the effective coordinate of the lix
const int eyOffset = 26; // sprite from the top left corner

const int skillInfinity = -1;  // for SkillButtons
const int skill_nr_max   = 999; // for SkillButtons

Matrix!XY countdown;

deprecated("use skillInfinity") const int infinity = -1;

/*  int frame_to_x_frame(int);
 *  int ac_to_y_frame   (int);
 *
 *   Ac     stringToAc   (in string);
 *  Style  stringToStyle(in string);
 *
 *  string acToString   (in Ac);
 *  string styleToString(in Style);
 */

enum Ac {
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

enum Style {
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

private immutable string[Ac]    ac_strings;
private immutable string[Style] style_strings;



static this()
{
    ac_strings = [
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

    style_strings = [
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



Ac stringToAc(in string str) {
    foreach (key; ac_strings.byKey()) {
        if (ac_strings[key] == str) return key;
    }
    return Ac.MAX;
}



string acToString(in Ac ac) {
    assert (ac in ac_strings);
    return ac_strings[ac];
}



Style stringToStyle(in string str) {
    foreach (key; style_strings.byKey) {
        if (style_strings[key] == str) return key;
    }
    return Style.GARDEN;
}



string styleToString(in Style st) {
    assert (st in style_strings);
    return style_strings[st];
}
