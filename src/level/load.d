module level.load;

// Reading Lix levels from files, or from raw bytestreams from the network.

import std.algorithm;
import std.range;

static import glo = basics.globals;

import file.date;
import file.filename;
import file.io;
import level.addtile;
import level.level;
import level.metadata;
import level.noowalgo;
import tile.gadtile;
import tile.group;
import tile.occur;

package void loadFromFile(Level level, in Filename fn)
{
    level._status = LevelStatus.GOOD;

    final switch (LevelMetaData.getFileFormat(fn)) {
    case FileFormat.NOTHING:
        level._status = LevelStatus.BAD_FILE_NOT_FOUND;
        break;
    case FileFormat.LIX:
        try
            load_from_vector(level, fillVectorFromFile(fn));
        catch (Exception e)
            level._status = LevelStatus.BAD_FILE_NOT_FOUND;
        break;
    case FileFormat.BINARY:
        // load an original .LVL file from L1/ONML/...
        // DTODOLEVELFORMAT
        // load_from_binary(level, fn);
        break;
    case FileFormat.LEMMINI:
        // DTODOLEVELFORMAT
        // load_from_lemmini(level, fn);
        break;
    }
    level.load_level_finalize();
}

package void loadFromVoidArray(Level level, immutable(void)[] arr)
{
    level._status = LevelStatus.GOOD;
    level.load_from_vector(fillVectorFromVoidArray(arr));
    level.load_level_finalize();
}



// ############################################################################
// ################################################ Loading the Lix file format
// ############################################################################



private void resize(Level level, in int x, in int y)
{
    level.topology.resize(clamp(x, Level.minXl, Level.maxXl),
                          clamp(y, Level.minYl, Level.maxYl));
}

private void load_from_vector(Level level, in IoLine[] lines) { with (level)
{
    // Groups don't have installation-unique names, unlike plain tiles
    // that have images on disk. The same group may have different names in
    // different levels -- usually a number that nobody cares about. In Lix,
    // groups are distinguished by references to TileGroup, or by
    // struct TileGroupKey. struct TileGroupKey specifies where the elements
    // sit, but does not yet allocate VRAM. We must translate level's group
    // names to TileGroupKey.
    TileGroupKey[string] groupsRead;
    string groupName; // if null, read into normal terrain list
    TerOcc[] groupElements; // if groupName != null, read tiles in here

    foreach (line; lines) with (line) switch (type) {
    // set a string
    case '$':
        if      (text1 == glo.levelBuilt       ) built = new Date(text2);
        else if (text1 == glo.levelAuthor      ) author       = text2;
        else if (text1 == glo.levelNameGerman ) nameGerman  = text2;
        else if (text1 == glo.levelNameEnglish) nameEnglish = text2;
        else if (text1 == glo.levelBeginGroup) {
            groupElements = [];
            groupName = text2;
        }
        else if (text1 == glo.levelEndGroup) {
            groupsRead[groupName] = TileGroupKey(groupElements);
            groupElements = [];
            groupName = "";
        }
        break;

    // set an integer
    case '#':
        if      (text1 == glo.levelSizeX) level.resize(nr1, topology.yl);
        else if (text1 == glo.levelSizeY) level.resize(topology.xl, nr1);
        else if (text1 == glo.levelTorusX) topology.setTorusXY(nr1 > 0, topology.torusY);
        else if (text1 == glo.levelTorusY) topology.setTorusXY(topology.torusX, nr1 > 0);
        else if (text1 == glo.levelBackgroundRed) bgRed = nr1;
        else if (text1 == glo.levelBackgroundGreen) bgGreen = nr1;
        else if (text1 == glo.levelBackgroundBlue) bgBlue = nr1;
        else if (text1 == glo.levelSeconds) overtimeSeconds = nr1;
        else if (text1 == glo.levelInitial) initial = nr1;
        else if (text1 == glo.levelRequired) required = nr1;
        else if (text1 == glo.levelSpawnint) spawnint = nr1;
        else if (text1 == glo.levelRateLegacy) spawnint = 4 + (99 - nr1) / 2;
        else if (text1 == glo.levelIntendedNumberOfPlayers)
                                   intendedNumberOfPlayers = nr1;
        else {
            Ac ac = stringToAc(text1);
            if (ac.isPloder)
                ploder = ac;
            if (ac != Ac.max)
                skills[ac] = nr1;
        }
        break;

    // new tile for the level
    case ':':
        addFromLine(level,
            // in case of TerOcc: Where to add the tile? All Gadgets -> level.
            groupName == "" ? &level.terrain : &groupElements,
            resolveTileName(groupsRead, text1), Point(nr1, nr2), text2);
        break;

    default:
        break;
    }
}}

private void load_level_finalize(Level level) {
    with (level)
{
    intendedNumberOfPlayers = clamp(intendedNumberOfPlayers, 1,
                                    glo.teamsPerLevelMax);
    level.resize(topology.xl, topology.yl);
    initial  = clamp(initial,  1, Level.initialMax);
    required = clamp(required, 1, initial);
    spawnint = clamp(spawnint, Level.spawnintMin, Level.spawnintMax);
    bgRed   = clamp(bgRed,   0, 255);
    bgGreen = clamp(bgGreen, 0, 255);
    bgBlue  = clamp(bgBlue,  0, 255);

    // Only allow one type of im/exploder.
    if (ploder == Ac.exploder)
        skills[Ac.imploder] = 0;
    else
        skills[Ac.exploder] = 0;

    terrain = terrain.noowAlgorithm(topology);

    if (_status == LevelStatus.GOOD) {
        if (terrain.empty && gadgets[].all!(li => li.empty))
            _status = LevelStatus.BAD_EMPTY;
        else if (gadgets[GadType.HATCH].empty)
            _status = LevelStatus.BAD_HATCH;
        else if (gadgets[GadType.GOAL].empty)
            _status = LevelStatus.BAD_GOAL;
    }
}}

unittest {
    Level l = new Level();
    l.load_from_vector([
        IoLine.Dollar(glo.levelBeginGroup, "0"),
        IoLine.Colon("thistiledoesntexist", 0, 0, ""),
        IoLine.Colon("anothermissingtile", 8, 8, ""),
        IoLine.Dollar(glo.levelEndGroup, ""),
        IoLine.Colon(glo.levelUseGroup ~ "0", 100, 100, ""),
    ]);
    // This shall not crash despite empty tile group. TileGroup checks that.
    assert (l.status == LevelStatus.BAD_IMAGE);
}
