module level.level;

import enumap;

public import net.ac;
public import level.levelio;

import basics.topology;
import file.date;
import file.filename;
import file.language;
import tile.phymap;
import graphic.color;
import graphic.torbit;
import level.addtile;
import level.levelio;
import level.levdraw;
import tile.occur;
import tile.gadtile;

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

class Level {
public:
    enum minXl = 160;
    enum minYl = 160;
    enum maxXl = 3200;
    enum maxYl = 2000;
    enum spawnintMin =  1;
    enum spawnintMax = 96;
    enum initialMax = 999;

    // DTODO: implement players_intended;
    MutableDate built;
    string author;
    string nameGerman;
    string nameEnglish;
    int intendedNumberOfPlayers;

    string[] hintsGerman;
    string[] hintsEnglish;

    Topology topology;
    int  bgRed;
    int  bgGreen;
    int  bgBlue;

    int  overtimeSeconds;
    int  initial;
    int  required;
    int  spawnint;

    bool useManualScreenStart;
    Point manualScreenStartCenter;

    /* ploder: either Ac.exploder or Ac.imploder.
     * This is never written to the level file. Instead, 0 exploders or 0
     * imploders should always be written to file. If both are missing,
     * this should offer flingploder.
     */
    Ac ploder;

    Enumap!(Ac, int) skills;

    TerOcc[] terrain;
    GadOcc[][GadType.MAX] gadgets; // one array GadOcc[] for each GadType,
                                   // indexed by ints, not by GadType enum vals
package:
    LevelStatus _status;

public:
    this()
    {
        built   = Date.now();
        _status = LevelStatus.BAD_EMPTY;
        intendedNumberOfPlayers = 1;
        topology = new Topology(640, 400); // one screen in C++ Lix
        initial  =  30;
        required =  20;
        spawnint =  32;
        ploder   = Ac.exploder;
    }

    this(in Filename fn)
    {
        this();
        level.levelio.loadFromFile(this, fn);
    }

    this(immutable(void)[] src)
    {
        this();
        level.levelio.loadFromVoidArray(this, src);
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

    @property LevelStatus status() const { return _status; }
    @property bool        good()   const { return _status == LevelStatus.GOOD;}

    @property bool nonempty() const
    {
        return _status != LevelStatus.BAD_FILE_NOT_FOUND
            && _status != LevelStatus.BAD_EMPTY;
    }

    @property Alcol bgColor() const
    {
        return color.makecol(bgRed, bgGreen, bgBlue);
    }

    // Called from the Editor. Adds to the correct array of this level,
    // then returns, in addition, a reference to the added piece.
    Occurrence addTileWithCenterAt(Filename fn, Point p)
    {
        return implCenter(this, fn, p);
    }

    void drawTerrainTo(Torbit tb, Phymap lo = null) const
    {
        implDrawTerrainTo(this, tb, lo);
    }

    Torbit create_preview(in int xl, in int yl, Alcol col) const
    {
        return implCreatePreview(this, xl, yl, col);
    }

    void saveToFile (in Filename fn) const { implSaveToFile (this, fn); }

    // Call this with on a level with the level's filename.
    // package exportImageFilename will mangle that to a PNG in the export dir.
    void exportImage(in Filename fn) const
    {
        implExportImage(this, exportImageFilename(fn));
    }

    override bool
    opEquals(Object rhs_obj) const
    {
        const(Level) rhs = cast (const Level) rhs_obj;
        if (rhs is null) return false;
        if (   this.intendedNumberOfPlayers != rhs.intendedNumberOfPlayers
            || this.author       != rhs.author
            || this.nameGerman   != rhs.nameGerman
            || this.nameEnglish  != rhs.nameEnglish
            || this.hintsGerman  != rhs.hintsGerman
            || this.hintsEnglish != rhs.hintsEnglish
            || ! this.topology.matches(rhs.topology)
            || this.bgRed != rhs.bgRed
            || this.bgGreen != rhs.bgGreen
            || this.bgBlue != rhs.bgBlue
            || this.overtimeSeconds != rhs.overtimeSeconds
            || this.initial != rhs.initial
            || this.required != rhs.required
            || this.spawnint != rhs.spawnint
            || this.ploder != rhs.ploder
        ) {
            return false;
        }
        // We don't care about a difference in the manual screen position if
        // we rely on automatic screen start anyway in both levels.
        if (this.useManualScreenStart != rhs.useManualScreenStart
            || this.useManualScreenStart
            && this.manualScreenStartCenter != rhs.manualScreenStartCenter
        ) {
            return false;
        }
        return this.terrain == rhs.terrain
            && this.gadgets == rhs.gadgets
            && this.skills  == rhs.skills;
    }
}
// end class Level
