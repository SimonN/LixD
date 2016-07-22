module level.levelio;

/* Input/output of the normal Lix level format. This format uses file.io.
 * Lix can also read levels from Lemmings 1 or Lemmini, those input functions
 * are in separate files of this package.
 */

import std.array;
import std.algorithm;
import std.conv;
import std.stdio;
import std.string;
import std.typecons;

static import glo = basics.globals;

import basics.help; // len
import basics.rect;
import file.date;
import file.filename;
import file.io;
import file.log;
import file.search; // test if file exists
import hardware.tharsis;
import level.addtile;
import level.level;
import level.noowalgo;
import lix.enums;
import tile.abstile;
import tile.gadtile;
import tile.group;
import tile.occur;

// private FileFormat get_file_format(in Filename);

package void loadFromFile(Level level, in Filename fn)
{
    level._status = LevelStatus.GOOD;

    final switch (get_file_format(fn)) {
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

package FileFormat get_file_format(in Filename fn)
{
    if (! fileExists(fn)) return FileFormat.NOTHING;
    else return FileFormat.LIX;

    // DTODO: Implement the remaining function from C++/A4 Lix that opens
    // a file in binary mode. Implement L1 loader functions.
    // Consider taking not a Filename, but an already opened (ref std.File)!
}

// ############################################################################
// ################################################ Loading the Lix file format
// ############################################################################

private enum cppHalfScreenX = 640 / 2;
private enum cppHalfScreenY = (480 - 80) / 2;

private void tuto(ref string[] into, in string what)
{
    // this always goes into index 0
    if (into == null) into   ~= what;
    else              into[0] = what;
}

private void hint(ref string[] into, in string what)
{
    // empty hints aren't allowed, all hints shall be in consecutive entries
    if (what == null) return;

    // hint 0 is the tutorial hint, this should be empty for most levels.
    if (into == null) into ~= "";
    into ~= what;
}


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
        else if (text1 == glo.levelHintGerman ) hint(hintsGerman,  text2);
        else if (text1 == glo.levelHintEnglish) hint(hintsEnglish, text2);
        else if (text1 == glo.levelTutorialGerman ) tuto(hintsGerman,  text2);
        else if (text1 == glo.levelTutorialEnglish) tuto(hintsEnglish, text2);
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
        else if (text1 == glo.levelBackgroundRed  ) bgRed = nr1;
        else if (text1 == glo.levelBackgroundGreen) bgGreen = nr1;
        else if (text1 == glo.levelBackgroundBlue ) bgBlue = nr1;
        else if (text1 == glo.levelSeconds      ) overtimeSeconds = nr1;
        else if (text1 == glo.levelInitial      ) initial = nr1;
        else if (text1 == glo.levelRequired     ) required = nr1;
        else if (text1 == glo.levelSpawnint     ) spawnint = nr1;
        else if (text1 == glo.levelIntendedNumberOfPlayers)
                                   intendedNumberOfPlayers = nr1;
        else if (text1 == glo.levelStartCornerX) {
            useManualScreenStart = true;
            manualScreenStartCenter.x = nr1 + cppHalfScreenX;
        }
        else if (text1 == glo.levelStartCornerY) {
            useManualScreenStart = true;
            manualScreenStartCenter.y = nr1 + cppHalfScreenY;
        }
        else if (text1 == glo.levelInitialLegacy) initial = nr1;
        else if (text1 == glo.levelRateLegacy) spawnint = 4 + (99 - nr1) / 2;
        else {
            Ac ac = lix.enums.stringToAc(text1);
            if (ac.isPloder)
                ploder = ac;
            if (ac != Ac.max)
                skills[ac] = nr1;
        }
        break;

    // new tile for the level
    case ':':
        const maybeAdded = addFromLine(level,
            // in case of TerOcc: Where to add the tile? All Gadgets -> level.
            groupName == "" ? &level.terrain : &groupElements,
            resolveTileName(groupsRead, text1), Point(nr1, nr2), text2);
        if (maybeAdded is null) {
            level._status = LevelStatus.BAD_IMAGE;
            logf("Missing image `%s'", text1);
        }
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

// ############################################################################
// ###################################### Saving a level in the Lix file format
// ############################################################################

package void implSaveToFile(const(Level) level, in Filename fn)
{
    try {
        std.stdio.File file = File(fn.rootful, "w");
        saveToFile(level, file);
        file.close();
    }
    catch (Exception e) {
        log(e.msg);
    }
}



public void saveToFile(const(Level) l, std.stdio.File file)
{
    assert (l);

    file.writeln(IoLine.Dollar(glo.levelBuilt,       l.built      ));
    file.writeln(IoLine.Dollar(glo.levelAuthor,      l.author     ));
    if (l.nameGerman.length > 0)
        file.writeln(IoLine.Dollar(glo.levelNameGerman,  l.nameGerman ));
    file.writeln(IoLine.Dollar(glo.levelNameEnglish, l.nameEnglish));
    file.writeln();

    // write hint
    void wrhi(in string[] hints, in string str_tuto, in string str_hint)
    {
        // index 0 is the tutorial hint
        foreach (int i, string str; hints) {
            if (i > 0)
                file.writeln(IoLine.Dollar(str_hint, str));
            else if (str != null)
                file.writeln(IoLine.Dollar(str_tuto, str));
        }
    }

    wrhi(l.hintsGerman,  glo.levelTutorialGerman,  glo.levelHintGerman );
    wrhi(l.hintsEnglish, glo.levelTutorialEnglish, glo.levelHintEnglish);
    if (l.hintsGerman != null || l.hintsEnglish != null) {
        file.writeln();
    }

    file.writeln(IoLine.Hash(glo.levelIntendedNumberOfPlayers,
                                    l.intendedNumberOfPlayers));
    file.writeln(IoLine.Hash(glo.levelSizeX, l.topology.xl));
    file.writeln(IoLine.Hash(glo.levelSizeY, l.topology.yl));
    if (l.topology.torusX || l.topology.torusY) {
        file.writeln(IoLine.Hash(glo.levelTorusX, l.topology.torusX));
        file.writeln(IoLine.Hash(glo.levelTorusY, l.topology.torusY));
    }
    if (l.useManualScreenStart) {
        file.writeln(IoLine.Hash(glo.levelStartCornerX,
                            l.manualScreenStartCenter.x - cppHalfScreenX));
        file.writeln(IoLine.Hash(glo.levelStartCornerY,
                            l.manualScreenStartCenter.y - cppHalfScreenY));
    }
    if (l.bgRed != 0 || l.bgGreen != 0 || l.bgBlue != 0) {
        file.writeln(IoLine.Hash(glo.levelBackgroundRed,   l.bgRed  ));
        file.writeln(IoLine.Hash(glo.levelBackgroundGreen, l.bgGreen));
        file.writeln(IoLine.Hash(glo.levelBackgroundBlue,  l.bgBlue ));
    }

    file.writeln();
    if (l.overtimeSeconds != 0)
        file.writeln(IoLine.Hash(glo.levelSeconds, l.overtimeSeconds));
    file.writeln(IoLine.Hash(glo.levelInitial,  l.initial ));
    file.writeln(IoLine.Hash(glo.levelRequired, l.required));
    file.writeln(IoLine.Hash(glo.levelSpawnint, l.spawnint));

    file.writeln();
    foreach (Ac sk, const int nr; l.skills.byKeyValue)
        if (nr != 0)
            file.writeln(IoLine.Hash(acToString(sk), nr));
    // Always write at least ex- or imploder, to determine ploder in panel.
    if (l.skills[Ac.imploder] == 0 && l.skills[Ac.exploder] == 0)
        file.writeln(IoLine.Hash(l.ploder.acToString, 0));

    // I assume that gadgets have no dependencies and generate valid IoLines
    // all by themselves. Write all gadget vectors to file.
    foreach (vec; l.gadgets) {
        if (vec != null)
            file.writeln();
        vec.map!(occ => occ.toIoLine).each!(line => file.writeln(line));
    }

    if (l.terrain != null)
        file.writeln();
    const(TileGroup)[] writtenGroups;
    foreach (ref const(TerOcc) occ; l.terrain) {
        file.writeDependencies(occ.tile, &writtenGroups);
        auto line = groupOrRegularTileLine(occ, writtenGroups);
        assert (line);
        file.writeln(line);
    }
}

// Returns null if we can't resolve the occurrence back to key.
// Returns an IoLine with non-null text1 otherwise.
private IoLine groupOrRegularTileLine(
    in TerOcc occ,
    in const(TileGroup)[] writtenGroups)
out (ret) {
    assert (ret is null || ret.text1 != null);
}
body {
    auto ret = occ.toIoLine();
    if (ret.text1 == null) {
        auto id = writtenGroups.countUntil(occ.tile);
        if (id >= 0)
            ret.text1 = "%s%d".format(glo.levelUseGroup, id);
    }
    return (ret.text1 != null) ? ret : null;
}

private void writeDependencies(
    std.stdio.File file,
    in AbstractTile tile,
    const(TileGroup)[]* written
) {
    if (canFind(*written, tile))
        return;
    // Recursive traversal of the dependencies
    foreach (dep; tile.dependencies)
        if (! canFind(*written, dep))
            file.writeDependencies(dep, written);
    assert (tile.dependencies.all!(dep => canFind(*written, dep)
        || dep.dependencies.empty), "I don't write non-groups (that have "
        "no dependencies) to the list, but everything else should be there.");
    // The workload of this recursive function
    if (! canFind(*written, tile)
        && tile.dependencies.length != 0 // This is a group, can be dependency.
    ) {
        auto group = cast (const(TileGroup)) tile;
        assert (group);
        assert (! group.dependencies.canFind(group));
        scope (exit)
            *written ~= group;
        file.writeln(IoLine.Dollar(glo.levelBeginGroup,
                                   written.length.to!string));
        scope (exit)
            file.writeln(IoLine.Dollar(glo.levelEndGroup, ""));
        foreach (elem; group.key.elements) {
            auto line = groupOrRegularTileLine(elem, *written);
            assert (line,
                "We should only write groups when all elements are either "
                "already-written groups or plain tiles!");
            file.writeln(line);
        }
    }
}
