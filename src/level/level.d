module level.level;

import std.algorithm;
import std.format;
import std.range;

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

    string author;
    string nameGerman;
    string nameEnglish;
    int intendedNumberOfPlayers;

    Topology topology;
    Alcol bgColor;

    int overtimeSeconds;
    int initial;
    int required;
    int spawnint;

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
    bool _fileNotFound;
    immutable(string)[] _missingTiles;
    MutableDate _built;

public:
    this()
    {
        built = Date.now();
        intendedNumberOfPlayers = 1;
        topology = new Topology(cppLixOneScreenXl, 400);
        initial = 20;
        required = 20;
        spawnint = 32;
        ploder = Ac.exploder;
        bgColor = color.black;
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

    @property const nothrow @nogc @safe {
        string name() { return nameEnglish == "" ? nameGerman : nameEnglish; }
        immutable(string)[] missingTiles() { return _missingTiles; }
        Date built() { return _built; }

        bool excellent()
        {
            return playable
                // List all possible warnings in here
                && ! warningNoGoals && ! warningTooLarge;
        }

        bool playable()
        {
            // List all possible errors in here
            return ! errorFileNotFound && ! errorNoHatches
                && ! errorMissingTiles; // ! errorEmpty is implicit with hatch
        }

        bool errorFileNotFound() { return _fileNotFound; }
        bool errorNoHatches() { return gadgets[GadType.HATCH].empty; }
        bool errorMissingTiles() { return ! _missingTiles.empty; }
        bool errorEmpty()
        {
            return terrain.empty && gadgets[].all!(list => list.empty);
        }

        bool warningNoGoals() { return gadgets[GadType.GOAL].empty; }
        bool warningTooLarge()
        {
            return topology.xl * topology.yl >= levelPixelsToWarn;
        }
    }

    @property Date built(Date aDate)
    {
        _built = aDate;
        return built;
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
        return new VfsFilename("%s%s.png".format(dirExport.rootless,
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
    do {
        return gadgetID % intendedNumberOfPlayers;
    }

    int howManyDoesTeamGetOutOf(int tribe, int listLen) const
    in {
        assert (tribe >= 0 && tribe < intendedNumberOfPlayers);
        assert (listLen >= 0);
    }
    do {
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
            || this.bgColor != rhs.bgColor
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
