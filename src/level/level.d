module level.level;

import std.format;
import enumap;

public import net.ac;
public import level.save;

import basics.globals;
import basics.topology;
import file.date;
import file.filename;
import file.language;
import tile.phymap;
import graphic.color;
import graphic.torbit;
import level.addtile;
import level.levdraw;
import level.load;
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
    enum cppLixOneScreenXl = 640;
    enum spawnintMin =  1;
    enum spawnintMax = 96;
    enum initialMax = 999;

    // DTODO: implement players_intended;
    MutableDate built;
    string author;
    string nameGerman;
    string nameEnglish;
    int intendedNumberOfPlayers;

    Topology topology;
    int  bgRed;
    int  bgGreen;
    int  bgBlue;

    int  overtimeSeconds;
    int  initial;
    int  required;
    int  spawnint;

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
        topology = new Topology(cppLixOneScreenXl, 400);
        initial  =  20;
        required =  20;
        spawnint =  32;
        ploder   = Ac.exploder;
    }

    this(in Filename fn)
    {
        this();
        loadFromFile(this, fn);
    }

    this(immutable(void)[] src)
    {
        this();
        loadFromVoidArray(this, src);
    }

    @property string
    name() const
    {
        // DTODOLANG
        // if (Lang.get_current() == Language.GERMAN)
        //      return nameGerman  == null ? nameEnglish : nameGerman;
        return nameEnglish == null ? nameGerman  : nameEnglish;
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

    // Given a level filename, returns the filename where the level-to-image
    // exporter would write the exported image.
    static Filename exportImageFilename(in Filename levelFilename)
    {
        return new VfsFilename("%s%s.png".format(dirExportImages.rootless,
                                levelFilename.fileNoExtNoPre));
    }

    // You should probably call this like:
    // ourLevel.exportImageTo(exportImageFilename(ourLevelFilename));
    void exportImageTo(in Filename fn) const
    {
        implExportImage(this, fn);
    }

    int teamIDforGadget(int gadgetID) const
    in {
        assert (gadgetID >= 0);
        assert (intendedNumberOfPlayers > 0);
    }
    body {
        return gadgetID % intendedNumberOfPlayers;
    }

    int howManyDoesTeamGetOutOf(int tribe, int listLen) const
    in {
        assert (tribe >= 0 && tribe < intendedNumberOfPlayers);
        assert (listLen >= 0);
    }
    body {
        return (listLen + intendedNumberOfPlayers - 1 - tribe)
            / intendedNumberOfPlayers;
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
            || ! this.topology.matches(rhs.topology)
            || this.bgRed != rhs.bgRed
            || this.bgGreen != rhs.bgGreen
            || this.bgBlue != rhs.bgBlue
            || this.initial != rhs.initial
            || this.required != rhs.required
            || this.spawnint != rhs.spawnint
            || this.ploder != rhs.ploder
        ) {
            return false;
        }
        if (intendedNumberOfPlayers > 1
            && this.overtimeSeconds != rhs.overtimeSeconds
        ) {
            return false;
        }
        return this.terrain == rhs.terrain
            && this.gadgets == rhs.gadgets
            && this.skills  == rhs.skills;
    }
}
// end class Level

unittest {
    Level l = new Level();
    l.intendedNumberOfPlayers = 5;
    assert (l.howManyDoesTeamGetOutOf(0, 15) == 3);
    assert (l.howManyDoesTeamGetOutOf(2, 15) == 3);
    assert (l.howManyDoesTeamGetOutOf(4, 15) == 3);
    assert (l.howManyDoesTeamGetOutOf(2, 13) == 3);
    assert (l.howManyDoesTeamGetOutOf(4, 13) == 2);
    assert (l.howManyDoesTeamGetOutOf(0, 11) == 3);
    assert (l.howManyDoesTeamGetOutOf(1, 11) == 2);
    assert (l.howManyDoesTeamGetOutOf(2, 3) == 1);
    assert (l.howManyDoesTeamGetOutOf(4, 3) == 0);
    assert (l.howManyDoesTeamGetOutOf(3, 0) == 0);
    assert (l.howManyDoesTeamGetOutOf(3, 0) == 0);
}
