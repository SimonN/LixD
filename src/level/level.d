module level.level;

import file.date;
import file.filename;
import file.language;
import game.lookup;
import graphic.color;
import graphic.torbit;
import level.levelio;
import level.levdraw;
import level.tile;
import lix.enums;

enum LevelStatus {
    GOOD,
    BAD_HATCH,          // level doens't contain >= 1 hatch
    BAD_GOAL,           // level doesn't contain >= 1 goal
    BAD_IMAGE,          // can't load all necessary tile images from disk
    BAD_FILE_NOT_FOUND, // can't load the level, level file not found
    BAD_EMPTY           // file exists, but no tiles
}

enum FileFormat {
    NOTHING,
    LIX,
    BINARY,
    LEMMINI
}

// Pos is a single instance of a Tile in the level. A Tile can thus appear
// many times in a level, differently rotated.
struct Pos {
    const(Tile) ob;
    int  x;
    int  y;
    bool mirr; // mirror vertically
    int  rot;  // rotate tile? 0 = normal, 1, 2, 3 = turned counter-clockwise
    bool dark; // Terrain loeschen anstatt neues malen
    bool noow; // Nicht ueberzeichnen?
}

struct Skill {
    Ac  ac;
    int nr;
}


class Level {

public:

    static immutable int min_xl = 160;
    static immutable int min_yl = 160;
    static immutable int max_xl = 3200;
    static immutable int max_yl = 2000;
    static immutable int spawnint_min =  1;
    static immutable int spawnint_max = 96;

    Date   built;
    string author;
    string name_german;
    string name_english;

    string[] hints_german;
    string[] hints_english;

    int  size_x;
    int  size_y;
    bool torus_x;
    bool torus_y;

    bool start_manual; // if not set, ignore start_x and start_y.
    int  start_x;      // start_manual is set in the level file by providing
    int  start_y;      // at least either start_x or start_y in the file.
    int  bg_red;
    int  bg_green;
    int  bg_blue;

    int  seconds;
    int  initial;
    int  required;
    int  spawnint_slow;
    int  spawnint_fast;

    bool nuke_delayed; // true == nuke button triggers overtime if any
    Ac   nuke_skill;   // NOTHING == use most appropriate exploder

    bool count_neutrals_only;
    bool transfer_skills;

    Skill[]             skills;
    Pos[][TileType.MAX] pos; // one array Pos[] for each TileType,
                             // indexed by integers, not by TileType enum vals
    this();
    this(in Filename);
    ~this() { }

    bool opCmp(in Level) const;

    LevelStatus get_status() const { return status;                     }
    bool        get_good()   const { return status == LevelStatus.GOOD; }
    string      get_name()   const;

    inout(string[]) get_hints() inout;

    void draw_terrain_to(Torbit tb, Lookup lo = null) const
    {
        impl_draw_terrain_to(this, tb, lo);
    }
    Torbit create_preview(in int xl, in int yl, AlCol col) const
    {
        return impl_create_preview(this, xl, yl, col);
    }

    // void load_from_stream(std::istream&); DTODO: implement this?
    void save_to_file(in Filename fn) const { impl_save_to_file(this, fn); }
    void export_image(in Filename fn) const { impl_export_image(this, fn); }

package:

    LevelStatus status;



public:

this()
{
    built  = Date.now();
    status = LevelStatus.BAD_EMPTY;

    size_x        = 640; // this comes from the old default res 640 x 480
    size_y        = 400; // old panel y height was 80, so size_y = 480 - 80;
    initial       = 30;
    required      = 20;
    spawnint_slow = 32;
    spawnint_fast =  4;
}



this(in Filename fn)
{
    this();
    level.levelio.load_from_file(this, fn);
}



string get_name() const {
    // DTODOLANG
    // if (Lang.get_current() == Language.GERMAN)
    //      return name_german  == null ? name_english : name_german;
    return name_english == null ? name_german  : name_english;
}



inout(string[]) get_hints() inout {
    // DTODOLANG
    // if (Lang.get_current() == Language.GERMAN)
    //      return hints_german  == null ? hints_english : hints_german;
    return hints_english == null ? hints_german  : hints_english;
}



bool opCmp(in Level rhs) const
{
    if (this.author        != rhs.author
     || this.name_german   != rhs.name_german
     || this.name_english  != rhs.name_english
     || this.hints_german  != rhs.hints_german
     || this.hints_english != rhs.hints_english

     || this.size_x        != rhs.size_x
     || this.size_y        != rhs.size_y
     || this.torus_x       != rhs.torus_x
     || this.torus_y       != rhs.torus_y
     || this.start_manual  != rhs.start_manual
     || ( this.start_x     != rhs.start_x && rhs.start_manual)
     || ( this.start_y     != rhs.start_y && rhs.start_manual)
     || this.bg_red        != rhs.bg_red
     || this.bg_green      != rhs.bg_green
     || this.bg_blue       != rhs.bg_blue

     || this.seconds       != rhs.seconds
     || this.initial       != rhs.initial
     || this.required      != rhs.required
     || this.spawnint_slow != rhs.spawnint_slow
     || this.spawnint_fast != rhs.spawnint_fast

     || this.nuke_delayed  != rhs.nuke_delayed
     || this.nuke_skill    != rhs.nuke_skill

     || this.count_neutrals_only != rhs.count_neutrals_only
     || this.transfer_skills     != rhs.transfer_skills) return false;

    // compare all tiles in one go
    if (this.pos != rhs.pos) return false;

    // Compare skillsets. Here, some skillsets might have empty skills at
    // the end, which we want to ignore. Since (this) is const, expand/shrink
    // a temporary array of skills to compare it with rhs.
    const(Skill)[] temp = this.skills;
    while (temp.length < rhs.skills.length) temp ~= Skill();
    while (temp.length > rhs.skills.length) {
        if (temp[$-1].ac == Ac.NOTHING) temp = temp[0 .. $-1];
        else return false;
    }
    return temp == rhs.skills;
}

}
// end class Level
