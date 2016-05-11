module level.levelio;

/* Input/output of the normal Lix level format. This format uses file.io.
 * Lix can also read levels from Lemmings 1 or Lemmini, those input functions
 * are in separate files of this package.
 */

import std.algorithm;
import std.stdio;
import std.string;

static import glo = basics.globals;

import basics.rect;
import file.date;
import file.filename;
import file.io;
import file.log;
import file.search; // test if file exists
import level.addtile;
import level.level;
import lix.enums;
import tile.gadtile;

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
        break;

    // set an integer
    case '#':
        if      (text1 == glo.levelSizeX) level.resize(nr1, topology.yl);
        else if (text1 == glo.levelSizeY) level.resize(topology.xl, nr1);
        else if (text1 == glo.levelTorusX) topology.setTorusXY(nr1 > 0, topology.torusY);
        else if (text1 == glo.levelTorusY) topology.setTorusXY(topology.torusX, nr1 > 0);
        else if (text1 == glo.levelBackgroundRed  ) bgRed     = nr1;
        else if (text1 == glo.levelBackgroundGreen) bgGreen   = nr1;
        else if (text1 == glo.levelBackgroundBlue ) bgBlue    = nr1;
        else if (text1 == glo.levelSeconds      ) seconds     = nr1;
        else if (text1 == glo.levelInitial      ) initial     = nr1;
        else if (text1 == glo.levelRequired     ) required    = nr1;
        else if (text1 == glo.levelSpawnint     ) spawnint    = nr1;
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

        // legacy support
        else if (text1 == glo.levelInitialLegacy) initial = nr1;
        else if (text1 == glo.levelRateLegacy) spawnint = 4 + (99 - nr1) / 2;

        // If nothing matched yet, look up the skill name.
        // We can't add skills if we've reached the globally allowed maximum.
        // If we've read in only rubbish, we don't add the skill.
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
        add_object_from_ascii_line(level, text1, Point(nr1, nr2), text2);
        break;

    default:
        break;
    }

    // LEGACY SUPPORT: Very old levels have sorted backwards the terrain.
    // Also, in general: Exclude the zero Date. Saved original .LVLs have a
    // time of 0. In early 2011, the maximal number of skills was raised.
    // Prior to that, infinity was 100, and finite skill counts had to be
    // <= 99. Afterwards, infinity was -1, and the maximum skill count was 999.
    MutableDate zero_date = new Date("0");
    if (built != zero_date && built < new Date("2009-08-23 00:00:00")) {
        // DTODOCOMPILERUPDATE
        // pos[GadType.TERRAIN].reverse();
    }
    if (built != zero_date && built < new Date("2011-01-08 00:00:00"))
        foreach (Ac ac, ref int nr; skills.byKeyValue)
            if (nr == 100)
                nr = lix.enums.skillInfinity;
}}



private void load_level_finalize(Level level)
{
    with (level) {
        intendedNumberOfPlayers = clamp(intendedNumberOfPlayers, 1,
                                        glo.teamsPerLevelMax);
        level.resize(topology.xl, topology.yl);
        initial  = clamp(initial,  1, 999);
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

        // Set level error. The error for file not found, or the error for
        // missing tile images, have been set already.
        if (_status == LevelStatus.GOOD) {
            int count = 0;
            foreach (poslist; pos)
                count += poslist.length;
            foreach (Ac ac, const int nr; skills)
                count += nr;
            if (count == 0)
                _status = LevelStatus.BAD_EMPTY;
            else if (pos[GadType.HATCH] == null)
                _status = LevelStatus.BAD_HATCH;
            else if (pos[GadType.GOAL ] == null)
                _status = LevelStatus.BAD_GOAL;
        }
    }
    // end with
}



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
    file.writeln(IoLine.Hash(glo.levelSeconds,  l.seconds ));
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

    void saveOneTileVector(T)(in T[] vec)
    {
        if (vec != null)
            file.writeln();
        foreach (ref const(T) pos; vec)
            if (auto ioLine = pos.toIoLine())
                if (ioLine.text1 != null)
                    file.writeln(ioLine);
    }
    l.pos.each!(posvec => saveOneTileVector(posvec));
    saveOneTileVector(l.terrain);
}
