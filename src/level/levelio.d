module level.levelio;

/* Input/output of the normal Lix level format. This format uses file.io.
 * Lix can also read levels from Lemmings 1 or Lemmini, those input functions
 * are in separate files of this package.
 */

import std.stdio;
import std.algorithm;

static import glo = basics.globals;

import basics.help; // positive_mod
import file.date;
import file.filename;
import file.io;
import file.log;
import file.search; // test if file exists
import level.level;
import level.tile;
import level.tilelib;
import lix.enums;

private FileFormat get_file_format(in Filename);

package void load_from_file(Level level, in Filename fn)
{
    level.status = LevelStatus.GOOD;

    final switch (get_file_format(fn)) {
    case FileFormat.NOTHING:
        level.status = LevelStatus.BAD_FILE_NOT_FOUND;
        break;
    case FileFormat.LIX:
        IoLine[] lines;
        if (fill_vector_from_file(lines, fn)) {
            load_from_vector(level, lines);
        }
        else level.status = LevelStatus.BAD_FILE_NOT_FOUND;
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



private FileFormat get_file_format(in Filename fn)
{
    if (! file_exists(fn)) return FileFormat.NOTHING;
    else return FileFormat.LIX;

    // DTODO: Implement the remaining function from C++/A4 Lix that opens
    // a file in binary mode. Implement L1 loader functions.
}



// ############################################################################
// ################################################ Loading the Lix file format
// ############################################################################



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



private void load_from_vector(Level level, in IoLine[] lines)
{
    with (level)
{
    foreach (line; lines) with (line) switch (type) {
    // set a string
    case '$':
        if      (text1 == glo.level_built       ) built = new Date(text2);

        else if (text1 == glo.level_author      ) author       = text2;
        else if (text1 == glo.level_name_german ) name_german  = text2;
        else if (text1 == glo.level_name_english) name_english = text2;

        else if (text1 == glo.level_hint_german ) hint(hints_german,  text2);
        else if (text1 == glo.level_hint_english) hint(hints_english, text2);
        else if (text1 == glo.level_tuto_german ) tuto(hints_german,  text2);
        else if (text1 == glo.level_tuto_english) tuto(hints_english, text2);
        break;

    // set an integer
    case '#':
        if      (text1 == glo.level_start_x ) {
            start_manual = true;
            start_x      = nr1;
        }
        else if (text1 == glo.level_start_y ) {
            start_manual = true;
            start_y      = nr1;
        }
        else if (text1 == glo.level_size_x       ) size_x        = nr1;
        else if (text1 == glo.level_size_y       ) size_y        = nr1;
        else if (text1 == glo.level_torus_x      ) torus_x       = nr1 > 0;
        else if (text1 == glo.level_torus_y      ) torus_y       = nr1 > 0;
        else if (text1 == glo.level_bg_red       ) bg_red        = nr1;
        else if (text1 == glo.level_bg_green     ) bg_green      = nr1;
        else if (text1 == glo.level_bg_blue      ) bg_blue       = nr1;
        else if (text1 == glo.level_seconds      ) seconds       = nr1;
        else if (text1 == glo.level_initial      ) initial       = nr1;
        else if (text1 == glo.level_required     ) required      = nr1;
        else if (text1 == glo.level_spawnint_slow) spawnint_slow = nr1;
        else if (text1 == glo.level_spawnint_fast) spawnint_fast = nr1;

        else if (text1 == glo.level_count_neutrals_only)
                                             count_neutrals_only = nr1 > 0;
        else if (text1 == glo.level_transfer_skills)
                                             transfer_skills     = nr1 > 0;

        // legacy support
        else if (text1 == glo.level_initial_legacy) initial      = nr1;
        else if (text1 == glo.level_rate) {
            spawnint_slow = 4 + (99 - nr1) / 2;
        }

        // If nothing matched yet, look up the skill name.
        // We can't add skills if we've reached the globally allowed maximum.
        // If we've read in only rubbish, we don't add the skill.
        else if (skills.length < glo.skill_max) {
            Skill sk = Skill();
            sk.ac = lix.enums.string_to_ac(text1);
            if (sk.ac != Ac.MAX) {
                sk.nr = nr1;
                skills ~= sk;
            }
        }
        break;

    // new tile for the level
    case ':':
        add_object_from_ascii_line(level, text1, nr1, nr2, text2);
        break;

    default:
        break;
    }

    // LEGACY SUPPORT: Very old levels have sorted backwards the terrain.
    // Also, in general: Exclude the zero Date. Saved original .LVLs have a
    // time of 0. In early 2011, the maximal number of skills was raised.
    // Prior to that, infinity was 100, and finite skill counts had to be
    // <= 99. Afterwards, infinity was -1, and the maximum skill count was 999.
    auto zero_date = new Date("");
    if (built != zero_date && built < new Date("2009-08-23 00:00:00")) {
        // DTODOCOMPILERUPDATE
        // pos[TileType.TERRAIN].reverse();
    }
    if (built != zero_date && built < new Date("2011-01-08 00:00:00")) {
        foreach (sk; skills) {
            if (sk.nr == 100) sk.nr = lix.enums.skill_infinity;
        }
    }
}
// end with

}
// end function load_from_vector



void add_object_from_ascii_line(
    Level     level,
    in string text1,
    in int    nr1,
    in int    nr2,
    in string text2
) {
    const(Tile) ob = get_tile(text1);
    if (ob && ob.cb) {
        Pos newpos = Pos(ob);
        newpos.x  = nr1;
        newpos.y  = nr2;
        if (ob.type == TileType.TERRAIN)
         foreach (char c; text2) switch (c) {
            case 'f': newpos.mirr = ! newpos.mirr;         break;
            case 'r': newpos.rot  =  (newpos.rot + 1) % 4; break;
            case 'd': newpos.dark = ! newpos.dark;         break;
            case 'n': newpos.noow = ! newpos.noow;         break;
            default: break;
        }
        else if (ob.type == TileType.HATCH)
         foreach (char c; text2) switch (c) {
            case 'r': newpos.rot  = !newpos.rot; break;
            default: break;
        }
        level.pos[ob.type] ~= newpos;
    }
    // image doesn't exist
    // record a missing image in the logfile
    else {
        level.status = LevelStatus.BAD_IMAGE;
        Log.logf("Missing image `%s'", text1);
    }
}



void load_level_finalize(Level level)
{
    with (level) {
        // set some standards, in case we've read in rubbish values
        if (size_x   < min_xl)             size_x   = Level.min_xl;
        if (size_y   < min_yl)             size_y   = Level.min_yl;
        if (size_x   > max_xl)             size_x   = Level.max_xl;
        if (size_y   > max_yl)             size_y   = Level.max_yl;
        if (initial  < 1)                  initial  = 1;
        if (initial  > 999)                initial  = 999;
        if (required > initial)            required = initial;
        if (spawnint_fast < spawnint_min)  spawnint_fast = Level.spawnint_min;
        if (spawnint_slow > spawnint_max)  spawnint_slow = Level.spawnint_max;
        if (spawnint_fast > spawnint_slow) spawnint_fast = spawnint_slow;

        if (bg_red   < 0) bg_red   = 0; if (bg_red   > 255) bg_red   = 255;
        if (bg_green < 0) bg_green = 0; if (bg_green > 255) bg_green = 255;
        if (bg_blue  < 0) bg_blue  = 0; if (bg_blue  > 255) bg_blue  = 255;

        if (torus_x) start_x = positive_mod(start_x, size_x);
        if (torus_y) start_y = positive_mod(start_y, size_y);

        // Set level error. The error for file not found, or the error for
        // missing tile images, have been set already.
        if (status == LevelStatus.GOOD) {
            int count = 0;
            foreach (poslist; pos) count += poslist.length;
            if      (count == 0)                status = LevelStatus.BAD_EMPTY;
            else if (pos[TileType.HATCH]==null) status = LevelStatus.BAD_HATCH;
            else if (pos[TileType.GOAL ]==null) status = LevelStatus.BAD_GOAL;
        }
    }
    // end with
}



// ############################################################################
// ###################################### Saving a level in the Lix file format
// ############################################################################



package void impl_save_to_file(const(Level) level, in Filename fn)
{
    try {
        std.stdio.File file = File(fn.get_rootful(), "w");
        save_to_file(level, file);
        file.close();
    }
    catch (Exception e) {
        Log.log(e.msg);
    }
}



private void save_to_file(const(Level) l, std.stdio.File file)
{
    assert (l);

    file.writeln(IoLine.Dollar(glo.level_built,        l.built       ));
    file.writeln(IoLine.Dollar(glo.level_author,       l.author      ));
    file.writeln(IoLine.Dollar(glo.level_name_german,  l.name_german ));
    file.writeln(IoLine.Dollar(glo.level_name_english, l.name_english));
    file.writeln();

    // write hint
    void wrhi(in string[] hints, in string str_tuto, in string str_hint)
    {
        // index 0 is the tutorial hint
        foreach (int i, string str; hints)
        if (i == 0) {
            if (str != null) file.writeln(IoLine.Dollar(str_tuto, str));
        }
        else file.writeln(IoLine.Dollar(str_hint, str));
    }


    wrhi(l.hints_german,  glo.level_tuto_german,  glo.level_hint_german );
    wrhi(l.hints_english, glo.level_tuto_english, glo.level_hint_english);
    if (l.hints_german != null || l.hints_english != null) {
        file.writeln();
    }

    file.writeln(IoLine.Hash(glo.level_size_x,  l.size_x ));
    file.writeln(IoLine.Hash(glo.level_size_y,  l.size_y ));
    if (l.torus_x || l.torus_y) {
        file.writeln(IoLine.Hash(glo.level_torus_x, l.torus_x));
        file.writeln(IoLine.Hash(glo.level_torus_y, l.torus_y));
    }
    if (l.start_manual) {
        file.writeln(IoLine.Hash(glo.level_start_x, l.start_x));
        file.writeln(IoLine.Hash(glo.level_start_y, l.start_y));
    }
    if (l.bg_red != 0 || l.bg_green != 0 || l.bg_blue != 0) {
        file.writeln(IoLine.Hash(glo.level_bg_red,   l.bg_red  ));
        file.writeln(IoLine.Hash(glo.level_bg_green, l.bg_green));
        file.writeln(IoLine.Hash(glo.level_bg_blue,  l.bg_blue ));
    }
    file.writeln();

    file.writeln(IoLine.Hash(glo.level_seconds,       l.seconds ));
    file.writeln(IoLine.Hash(glo.level_initial,       l.initial ));
    file.writeln(IoLine.Hash(glo.level_required,      l.required));
    file.writeln(IoLine.Hash(glo.level_spawnint_slow, l.spawnint_slow));
    file.writeln(IoLine.Hash(glo.level_spawnint_fast, l.spawnint_fast));
//  file.writeln(IoLine.Hash(glo.level_count_neutrals_only, l.count_neutrals_only));
//  file.writeln(IoLine.Hash(glo.level_transfer_skills,     l.transfer_skills));

    // print only as many skill lines as needed, don't print the many NOTHING
    // at the end
    const(Skill)[] skills = l.skills;
    while (skills != null && skills[$-1].ac == Ac.NOTHING) {
        skills = skills[0 .. $-1];
    }
    if (skills != null)  file.writeln();
    foreach (sk; skills) file.writeln(IoLine.Hash(ac_to_string(sk.ac), sk.nr));

    // this local function outputs all tiles of a given type
    void save_one_tile_vector(in Pos[] vec)
    {
        if (vec != null) {
            file.writeln();
        }
        foreach (tile; vec) {
            if (tile.ob is null) continue;
            string str = get_filename(tile.ob);
            if (str == null) continue;

            string modifiers;
            if (tile.mirr) modifiers ~= 'f';
            foreach (r; 0 .. tile.rot) modifiers ~= 'r';
            if (tile.dark) modifiers ~= 'd';
            if (tile.noow) modifiers ~= 'n';
            file.writeln(IoLine.Colon(str, tile.x, tile.y, modifiers));
        }
    }

    // print all special objects, then print all terrain.
    foreach (ref const(Pos[]) vec; l.pos) {
        if (vec is l.pos[TileType.TERRAIN]) continue;
        save_one_tile_vector(vec);
    }
    save_one_tile_vector(l.pos[TileType.TERRAIN]);

}
