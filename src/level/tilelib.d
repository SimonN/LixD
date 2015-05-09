module level.tilelib;

/* This was class ObjLib in C++/A4 Lix.
 * In D/A5 Lix, it's not a class anymore, but module-level functions.
 */

import std.conv; // ulong -> int for string lengths
import std.typecons; // Rebindable!(const Filename)

static import glo = basics.globals;

import basics.help; // clear_array
import graphic.cutbit;
import level.graset;
import level.tile;
import file.filename;
import file.search;

void        initialize();
void        deinitialize();

const(Tile) get_tile(in string); // for most things, incl. parsing level files
const(Tile) get_tile(in Filename); // for bitmap browser
string      get_filename(in Tile);

const(Tile) get_orig_terrain(in int set, in int id) { return null; } // DTODO
const(Tile) get_orig_special(in int set, in int id) { return null; } // DTODO
const(Tile) get_orig_vgaspec(            in int id) { return null; } // DTODO

string      orig_set_to_string(in int) { return null; } // DTODO: impl;
OrigSet     string_to_orig_set(in string) { return OrigSet.DIRT; } // DTODO

// static this(); -- exists, see below

enum OrigSet {
    DIRT, HELL, PASTEL, PILLAR, CRYSTAL,
    BRICK, ROCK, SNOW, BUBBLE, HOLIDAY,
    L1_MAX,
    CLASSIC = L1_MAX, BEACH, CAVELEMS, CIRCUS, EGYPTIAN, HIGHLAND,
    MEDIEVAL, OUTDOOR, POLAR, SHADOW, SPACE, SPORTS,
    L2_MAX,
    MAX = L2_MAX
};



private:

    immutable string vgaspec_string = "Vgaspec";
    string[OrigSet]  orig_set_string;
    string[string]   replace_strings;

    Tile[string] tiles;
    Rebindable!(const Filename)[string] queue;

    GraphicSet[OrigSet.MAX] grasets;
    Tile[] vgaspecs;



public:

void initialize()
{
    static import hardware.display;
    hardware.display.display_startup_message("indexing all files in images/");

    // fill the queue will all files on the disk, but chop off the
    // "images/" prefix before using the path as the tile's name
    immutable string imgdir = glo.dir_bitmap.dir_rootless;
    auto files = file.search.find_tree(glo.dir_bitmap);
    foreach (fn; files) {
        if (! fn.has_image_extension()) continue;

        string rootless = fn.rootless_no_ext;
        if (imgdir.length <= rootless.length
         && rootless[0 .. imgdir.length] == imgdir) {
            rootless = rootless[imgdir.length .. $];
        }
        queue[rootless] = fn;
    }
}



void deinitialize()
{
    destroy_array(tiles);
    destroy_array(grasets);
    destroy_array(vgaspecs);
}



const(Tile) get_tile(in string str)
{
    // This function has a lot of returns along its way. Successfully found
    // objects are always returned directly. If the object isn't found in time,
    // the function may recurse.

    // Return tile from already loaded image file.
    auto tile_ptr = (str in tiles);
    if (tile_ptr) return *tile_ptr;

    // Return object from a graphics set (OrigSet)
    // Format: Dirt-t02 oder Pillar-s63
    // Detect if the end of the string is of this nature

    // DTODOORIG: implement this.

    // Seek object name in the prefetch queue. If it's there, load and return.
    auto to_load_ptr = (str in queue);
    if (to_load_ptr) {
        load_tile_from_disk(str, *to_load_ptr);
        queue.remove(str);
        return get_tile(str);
    }

    // Otherwise use deprecated text replacement.
    // Two of them are to strip "bitmap/" or "images/" from the beginning.
    // Another is to strip "./" from the beginning.
    immutable string replaced_str = replace_filestring(str);
    if (replaced_str != str) {
        return get_tile(replaced_str); // recursive, should be finitely so
    }
    else return null;
}



const(Tile) get_tile(in Filename fn)
{
    // cut away "images/" if that is in front
    // we could eat an extra iteration through get_file(string),
    // but this is negligibly faster. <_<
    immutable string s = fn.rootless_no_ext;
    immutable string b = glo.dir_bitmap.dir_rootless;

    if (b.length <= s.length && s[0 .. b.length] == b) {
         return get_tile(s[b.length .. $]);
    }
    else return get_tile(s);
}



string get_filename(in Tile tile)
{
    // DTODO: this is slow. Maybe use the key as a property of the tile
    // in addition to the key, so it becomes a lookup associative array.
    foreach (key, value; tiles) {
        if (value == tile) return key;
    }

    // If we keep going from here, the search wasn't succesful.
    // Try looking up an L1/L2 piece.
    // If not successful, look up a vgaspec piece.

    // DTODOORIG: not implemented yet

    // Object not found anywhere
    return null;
}



private void
load_tile_from_disk(in string str_no_ext, in Filename fn)
{
    char pe = fn.pre_extension;

    TileType type = TileType.TERRAIN;
    int st = 0; // subtype
    if      (pe == glo.pre_ext_steel)        { type = TileType.TERRAIN; st=1;}
    else if (pe == glo.pre_ext_hatch)        { type = TileType.HATCH;        }
    else if (pe == glo.pre_ext_deco)         { type = TileType.DECO;         }
    else if (pe == glo.pre_ext_goal)         { type = TileType.GOAL;         }
    else if (pe == glo.pre_ext_trap)         { type = TileType.TRAP;         }
    else if (pe == glo.pre_ext_water)        { type = TileType.WATER;        }
    else if (pe == glo.pre_ext_fire)         { type = TileType.WATER;  st=1; }
    else if (pe == glo.pre_ext_oneway_left)  { type = TileType.ONEWAY;       }
    else if (pe == glo.pre_ext_oneway_right) { type = TileType.ONEWAY; st=1; }

    // cut into frames unless it's terrain or steel (subtype of terrain)
    Cutbit cb = new Cutbit(fn, type != TileType.TERRAIN);
    if (! cb.is_valid()) {
        import file.log;
        Log.logf("Error loading from disk: `%s' -> `%s'",
            str_no_ext, fn.rootful);
        Log.log("D/A5 Lix cannot load very large images. See doc/bugs.txt.");
        return;
    }

    // DTODO: check whether levels with rotated objects are rendered
    // exactly like in C++/A4 Lix
    tiles[str_no_ext] = Tile.take_over_cutbit(cb, type, st);

    // Load overriding definitions from a possibly accompanying text file.
    // That file must have the same name, only its extension must be replaced.
    if (type != TileType.TERRAIN) {
        auto tile_ptr = (str_no_ext in tiles);
        if (tile_ptr) {
            Filename defs = new Filename(fn.rootless_no_ext
                                       ~ glo.ext_object_definitions);
            // We test for existence here, because trying to load the file
            // will generate a log message for nonexisting file otherwise.
            // It's normal to have no definitions file, so don't log that.
            if (file_exists(defs)) {
                tile_ptr.read_definitions_file(defs);
            }
        }
    }
}



private string[string] replace_exact;
private string[string] replace_substring;

private string replace_filestring(in string str)
{
    auto exact_ptr = (str in replace_exact);
    if (exact_ptr) return *exact_ptr;

    // If we get to here, no match has been found in the exact replacements
    foreach (repl_old, repl_new; replace_substring) {
        // find the first occurence of the partial replace string
        foreach (int i; 0 .. str.length.to!int - repl_old.length.to!int) {
            if (str[i .. i + repl_old.length] == repl_old) {
                // the returned string can be longer or shorter
                return str[0 .. i] ~ repl_new ~ str[i + repl_old.length .. $];
            }
        }
    }

    // Nothing found in the substring replacements, return the original
    return str;
}



static this()
{
    orig_set_string = [
        OrigSet.DIRT     : "Dirt",
        OrigSet.HELL     : "Hell",
        OrigSet.PASTEL   : "Pastel",
        OrigSet.PILLAR   : "Pillar",
        OrigSet.CRYSTAL  : "Crystal",
        OrigSet.BRICK    : "Brick",
        OrigSet.ROCK     : "Rock",
        OrigSet.SNOW     : "Snow",
        OrigSet.BUBBLE   : "Bubble",
        OrigSet.HOLIDAY  : "Holiday",

        OrigSet.CLASSIC  : "Classic",
        OrigSet.BEACH    : "Beach",
        OrigSet.CAVELEMS : "Cavelems",
        OrigSet.CIRCUS   : "Circus",
        OrigSet.EGYPTIAN : "Egyptian",
        OrigSet.HIGHLAND : "Highland",
        OrigSet.MEDIEVAL : "Medieval",
        OrigSet.OUTDOOR  : "Outdoor",
        OrigSet.POLAR    : "Polar",
        OrigSet.SHADOW   : "Shadow",
        OrigSet.SPACE    : "Space",
        OrigSet.SPORTS   : "Sports",

        OrigSet.MAX      : "Max"
    ];

    replace_exact = [
        "Universal/water.W"  :   "matt/water.W",
        "Universal/10tons.T" :   "matt/10tons.T",
        "./bitmap/Rebuilds/06 - Oriental/hatch.H" : "matt/oriental/Hatch.H",
        "./bitmap/Rebuilds/04 - Sandy Beach/hatch.H" : "matt/beach/Hatch.H",
    ];

    replace_substring = [
        "Universal/" : "matt/steel/",
        "Rebuilds/"  : "matt/",

        "01 - Earth"       : "earth",
        "02 - Gold Mine"   : "goldmine",
        "03 - Carnival"    : "carnival",
        "04 - Sandy Beach" : "beach",
        "05 - Winter"      : "winter",
        "06 - Oriental"    : "oriental",
        "07 - Underworld"  : "underworld",
        "08 - Bricks"      : "bricks",
        "09 - Marble"      : "marble",

        "arnival/Balloons" : "arnival/balloons",

        "/ExplosiveCrate" : "/explosivecrate",
        "/mine cart"      : "/minecart",
        "/plank diag"     :  "/plankdiag",
        "/plankdiag 2"    : "/plankdiag2",
        "/plank support"  :  "/planksupport",
        "/planksupport 2" : "/planksupport2",
        "/planksupport 3" : "/planksupport3",

        "iental/asian "  : "iental/asian",
        "iental/bonsai " : "iental/bonsai",
        "iental/bamboo " : "iental/bamboo_",

        "Daytime Sand"   : "daytime",
        "Nighttime Sand" : "nighttime",
        "Sand Decor"     : "decor",

        // try these last, because they might appear deeper in the dir struct
        // and we don't want to replace them there
        "./bitmap/"  : "",
        "./images/"  : "",
        "bitmap/"    : "",
        "images/"    : "",
    ];
}
