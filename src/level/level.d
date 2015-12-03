module level.level;

public import enumap;

public import level.levelio : saveToFile;

import file.date;
import file.io; // IoLine for Pos; all other I/O is in module level.levelio
import file.filename;
import file.language;
import game.phymap;
import graphic.color;
import graphic.torbit;
import level.levelio;
import level.levdraw;
import level.tile;
import level.tilelib : get_filename;
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

    IoLine toIoLine() const
    {
        string filename = ob ? get_filename(ob) : null;
        string modifiers;
        if (mirr) modifiers ~= 'f';
        foreach (r; 0 .. rot) modifiers ~= 'r';
        if (dark) modifiers ~= 'd';
        if (noow) modifiers ~= 'n';
        return IoLine.Colon(filename, x, y, modifiers);
    }
}



class Level {

public:

    static immutable int minXl = 160;
    static immutable int minYl = 160;
    static immutable int maxXl = 3200;
    static immutable int maxYl = 2000;
    static immutable int spawnintMin =  1;
    static immutable int spawnintMax = 96;

    // DTODO: implement players_intended;

    Date   built;
    string author;
    string nameGerman;
    string nameEnglish;

    string[] hintsGerman;
    string[] hintsEnglish;

    int  sizeX;
    int  sizeY;
    bool torusX;
    bool torusY;

    bool startManual; // if not set, ignore startX and startY.
    int  startX;      // startManual is set in the level file by providing
    int  startY;      // at least either startX or startY in the file.
    int  bgRed;
    int  bgGreen;
    int  bgBlue;

    int  seconds;
    int  initial;
    int  required;
    int  spawnintSlow;
    int  spawnintFast;

    bool nukeDelayed; // true == nuke button triggers overtime if any
    Ac   nukeSkill;   // NOTHING == use most appropriate exploder

    bool countNeutralsOnly;
    bool transferSkills;

    Enumap!(Ac, int) skills;

    Pos[][TileType.MAX] pos; // one array Pos[] for each TileType,
                             // indexed by integers, not by TileType enum vals
/*  this();
 *  this(in Filename);
 *
 *  override bool opEquals(Object) const
 *  @property string      name()   const;
 *  @property string[]    hints()  inout;
 */
    @property LevelStatus status() const { return _status; }
    @property bool        good()   const { return _status == LevelStatus.GOOD;}

    @property bool nonempty() const
    {
        return _status != LevelStatus.BAD_FILE_NOT_FOUND
            && _status != LevelStatus.BAD_EMPTY;
    }

    void drawTerrainTo(Torbit tb, Phymap lo = null) const
    {
        implDrawTerrainTo(this, tb, lo);
    }
    Torbit create_preview(in int xl, in int yl, AlCol col) const
    {
        return implCreatePreview(this, xl, yl, col);
    }

    // void load_from_stream(std::istream&); DTODO: implement this?
    void saveToFile (in Filename fn) const { implSaveToFile (this, fn); }
    void exportImage(in Filename fn) const { implExportImage(this, fn); }

    // to save a level into a replay, call with existing File descriptor:
    // mylevel.saveToFile(std.stdio.File existing_handle)

package:

    LevelStatus _status;



public:

this()
{
    built   = Date.now();
    _status = LevelStatus.BAD_EMPTY;

    sizeX        = 640; // this comes from the old default res 640 x 480
    sizeY        = 400; // old panel y height was 80, so sizeY = 480 - 80;
    initial      =  30;
    required     =  20;
    spawnintSlow =  32;
    spawnintFast =   4;
}



this(in Filename fn)
{
    this();
    level.levelio.loadFromFile(this, fn);
}



@property string
name() const
{
    // DTODOLANG
    // if (Lang.get_current() == Language.GERMAN)
    //      return nameGerman  == null ? nameEnglish : nameGerman;
    return nameEnglish == null ? nameGerman  : nameEnglish;
}



@property inout(string[])
hints() inout
{
    // DTODOLANG
    // if (Lang.get_current() == Language.GERMAN)
    //      return hintsGerman  == null ? hintsEnglish : hintsGerman;
    return hintsEnglish == null ? hintsGerman  : hintsEnglish;
}



override bool
opEquals(Object rhs_obj) const
{
    const(Level) rhs = cast (const Level) rhs_obj;
    if (rhs_obj is null) return false;

    if (   this.author       != rhs.author
        || this.nameGerman   != rhs.nameGerman
        || this.nameEnglish  != rhs.nameEnglish
        || this.hintsGerman  != rhs.hintsGerman
        || this.hintsEnglish != rhs.hintsEnglish

        || this.sizeX        != rhs.sizeX
        || this.sizeY        != rhs.sizeY
        || this.torusX       != rhs.torusX
        || this.torusY       != rhs.torusY
        || this.startManual  != rhs.startManual
        || ( this.startX     != rhs.startX && rhs.startManual)
        || ( this.startY     != rhs.startY && rhs.startManual)
        || this.bgRed        != rhs.bgRed
        || this.bgGreen      != rhs.bgGreen
        || this.bgBlue       != rhs.bgBlue

        || this.seconds      != rhs.seconds
        || this.initial      != rhs.initial
        || this.required     != rhs.required
        || this.spawnintSlow != rhs.spawnintSlow
        || this.spawnintFast != rhs.spawnintFast

        || this.nukeDelayed  != rhs.nukeDelayed
        || this.nukeSkill    != rhs.nukeSkill

        || this.countNeutralsOnly != rhs.countNeutralsOnly
        || this.transferSkills    != rhs.transferSkills
    ) {
        return false;
    }

    // compare all tiles in one go
    if (this.pos    != rhs.pos   ) return false;
    if (this.skills != rhs.skills) return false;

    return true;
}

}
// end class Level
