module tile.tilelib;

/* This was class ObjLib in C++/A4 Lix.
 * In D/A5 Lix, it's not a class anymore, but module-level functions.
 */

import std.algorithm;
import std.conv; // ulong -> int for string lengths
import std.typecons; // Rebindable!(const Filename)

static import glo = basics.globals;

import basics.help; // clear_array
import file.filename;
import file.log;
import hardware.tharsis;
import graphic.cutbit;
import tile.abstile;
import tile.gadtile;
import tile.group;
import tile.terrain;

private:
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
        files = glo.dirImages.findTree;
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
    return null;
}

TileGroup get_group(in TileGroupKey key)
{
    if (auto found = key in groups)
        return *found;
    else if (key.elements.any!(occ => ! occ.dark))
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
    GadType type;
    int subtype = 0;
    if      (pe == glo.preExtHatch) { type = GadType.HATCH; }
    else if (pe == glo.preExtGoal)  { type = GadType.GOAL;  }
    else if (pe == glo.preExtTrap)  { type = GadType.TRAP;  }
    else if (pe == glo.preExtWater) { type = GadType.WATER; }
    else if (pe == glo.preExtFire)  { type = GadType.WATER; subtype = 1; }
    else {
        logf("Unrecognized pre-extension `%c': `%s'", pe, fn.rootless);
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
    // That file must have the same name, minus its extension, plus ".txt".
    Filename defs = new VfsFilename(fn.rootlessNoExt
                               ~ glo.filenameExtTileDefinitions);
    // We test for existence here, because trying to load the file
    // will generate a log message for nonexisting file otherwise.
    // It's normal to have no definitions file, so don't log that.
    if (defs.fileExists)
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
    logf("Image has too large proportions: `%s'", fn.rootless);
    log ("    -> See bug report: https://github.com/SimonN/LixD/issues/4");
}
