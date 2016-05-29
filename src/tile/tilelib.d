module tile.tilelib;

/* This was class ObjLib in C++/A4 Lix.
 * In D/A5 Lix, it's not a class anymore, but module-level functions.
 */

import std.conv; // ulong -> int for string lengths
import std.typecons; // Rebindable!(const Filename)

static import glo = basics.globals;

import basics.help; // clear_array
import file.filename;
import file.log;
import file.search;
import hardware.tharsis;
import graphic.cutbit;
import tile.abstile;
import tile.gadtile;
import tile.group;
import tile.terrain;

private:
    string[string] replace_strings;
    TerrainTile[string] terrain;
    GadgetTile [string] gadgets;
    TileGroup[TileGroupKey] groups;
    Rebindable!(const Filename)[string] queue;

public:

void initialize()
{
    version (tharsisprofiling)
        auto zone = Zone(profiler, "tilelib.init");
    immutable string imgdir = glo.dirImages.dirRootless;
    MutFilename[] files;
    {
        version (tharsisprofiling)
            auto zone2 = Zone(profiler, "tilelib.init find recursively");
        files = file.search.findRegularFilesRecursively(glo.dirImages);
    }
    foreach (fn; files) {
        if (! fn.hasImageExtension()) continue;
        string rootless = fn.rootlessNoExt;
        // fill the queue will all files on the disk, but chop off the
        // "images/" prefix before using the path as the tile's name
        if (imgdir.length <= rootless.length
            && rootless[0 .. imgdir.length] == imgdir
        ) {
            rootless = rootless[imgdir.length .. $];
        }
        queue[rootless] = fn;
    }
}

void deinitialize()
{
    destroyArray(terrain);
    destroyArray(gadgets);
}

auto get_gadget (in string s) { return get_tile!(GadgetTile,  gadgets)(s); }
auto get_terrain(in string s) { return get_tile!(TerrainTile, terrain)(s); }

private const(T)
get_tile(T : AbstractTile, alias container)(in string str)
{
    // This function has a lot of returns along its way. Successfully found
    // objects are always returned directly. If the object isn't found in time,
    // the function may recurse.

    // Return tile from already loaded image file.
    auto tile_ptr = (str in container);
    if (tile_ptr) return *tile_ptr;

    // Seek object name in the prefetch queue. If it's there, load and return.
    auto to_load_ptr = (str in queue);
    if (to_load_ptr) {
        load_tile_from_disk(str, *to_load_ptr);
        queue.remove(str);
        return get_tile!(T, container)(str);
    }

    // Otherwise use deprecated text replacement.
    // Two of them are to strip "bitmap/" or "images/" from the beginning.
    // Another is to strip "./" from the beginning.
    immutable string repl = replace_filestring(str);
    if (repl != str) {
        return get_tile!(T, container)(repl); // recursive, should be finite
    }
    else return null;
}

TileGroup get_group(in TileGroupKey key)
{
    if (auto found = key in groups)
        return *found;
    else if (key.elements.length > 0)
        return groups[key] = new TileGroup(key);
    else
        return null;
}

private:

void load_tile_from_disk(in string strNoExt, in Filename fn)
{
    auto pe = fn.preExtension;
    if (pe == 0 || pe == glo.preExtSteel)
        loadTerrainFromDisk(strNoExt, pe == glo.preExtSteel, fn);
    else
        loadGadgetFromDisk(strNoExt, pe, fn);
}

void loadGadgetFromDisk(in string strNoExt, in char pe, in Filename fn)
{
    GadType type = GadType.DECO;
    int subtype = 0;
    if      (pe == glo.preExtHatch) { type = GadType.HATCH; }
    else if (pe == glo.preExtGoal)  { type = GadType.GOAL;  }
    else if (pe == glo.preExtDeco)  { type = GadType.DECO;  }
    else if (pe == glo.preExtTrap)  { type = GadType.TRAP;  }
    else if (pe == glo.preExtWater) { type = GadType.WATER; }
    else if (pe == glo.preExtFire)  { type = GadType.WATER; subtype = 1; }
    else {
        logf("Unrecognized pre-extension `%c': `%s'", pe, fn.rootful);
        return;
    }

    Cutbit cb = new Cutbit(fn, true); // true == cut into frames
    if (! cb.valid) {
        cb.logBecauseInvalid(fn);
        return;
    }
    gadgets[strNoExt] = GadgetTile.takeOverCutbit(strNoExt, cb, type, subtype);
    auto tile = (strNoExt in gadgets);
    assert (tile && *tile);
    // Load overriding definitions from a possibly accompanying text file.
    // That file must have the same name, only its extension must be replaced.
    Filename defs = new Filename(fn.rootlessNoExt
                               ~ glo.filenameExtTileDefinitions);
    // We test for existence here, because trying to load the file
    // will generate a log message for nonexisting file otherwise.
    // It's normal to have no definitions file, so don't log that.
    if (fileExists(defs))
        tile.readDefinitionsFile(defs);
}

void loadTerrainFromDisk(in string strNoExt, in bool steel, in Filename fn)
{
    Cutbit cb = new Cutbit(fn, false); // false == don't cut into frames
    if (! cb.valid) {
        cb.logBecauseInvalid(fn);
        return;
    }
    terrain[strNoExt] = TerrainTile.takeOverCutbit(strNoExt, cb, steel);
}

void logBecauseInvalid(const(Cutbit) cb, in Filename fn)
{
    assert (! cb.valid);
    logf("Image has too large proportions: `%s'", fn.rootful);
    log ("    -> See bug report: https://github.com/SimonN/LixD/issues/4");
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
