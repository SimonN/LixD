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

// Feeble attempt to avoid dynamic cast :-( Maybe ripe for the visitor pattern.
struct ResolvedTile {
    const(TerrainTile) terrain;
    const(GadgetTile) gadget;
    const(TileGroup) group;
    const(bool) weRemovedThisTileThereforeDontRaiseErrors;

    @property const(AbstractTile) tile() const
    {
        return terrain ? terrain : gadget ? gadget : group;
    }
}

// For most tiles, their name is the filename without "images/", without
// extension, but with pre-extension in case the filename has one
ResolvedTile resolveTileName(in string name)
{
    if (auto ter = get_tile!(TerrainTile, terrain)(name))
        return ResolvedTile(ter, null, null);
    else if (auto gad = get_tile!(GadgetTile, gadgets)(name))
        return ResolvedTile(null, gad, null);
    else if (name == "")
        // If _silentReplacements decides to replace a string with "", then
        // that means that we removed a tile from the project, but don't want
        // the levels to fail that used that tile.
        return ResolvedTile(null, null, null, true);
    else if (auto replaced = name in _silentReplacements)
        // This is recursive, but _silentReplacements's entries are
        // designed such that we recurse at most once here.
        return resolveTileName(*replaced);
    return ResolvedTile();
}

ResolvedTile resolveTileName(Filename fn)
{
    if (! fn || fn.rootlessNoExt.length < glo.dirImages.rootlessNoExt.length)
        return ResolvedTile();
    // We have indexed the tiles without "images/" at the front of filenames
    return resolveTileName(fn.rootlessNoExt[
                           glo.dirImages.rootlessNoExt.length .. $]);
}

// throws TileGroup.InvisibleException if all visible pixels are overlapped
// with dark tiles. This can happen because all tiles are dark, which the
// caller could check easily, but also if all non-dark tiles are covered
// with dark tiles, which only TileGroup's constructor checks.
TileGroup getGroup(in TileGroupKey key)
out (ret) { assert (ret !is null); }
body {
    if (auto found = key in groups)
        return *found;
    return groups[key] = new TileGroup(key);
}

// Called from the level loading function. The level may resolve tile names
// that the tile library cannot resolve, because they're groups that are only
// known to the level during level-load time. Therefore, when the lib can't
// resolve an image, the lib doesn't yet log anything. The level may, later.
void logMissingImage(in string key)
{
    if (key in _loggedMissingImages)
        return;
    _loggedMissingImages[key] = true;
    logf("Missing image: `%s'", key);
}

// ############################################################################

private:

TerrainTile[string] terrain;
GadgetTile [string] gadgets;
TileGroup[TileGroupKey] groups;
Rebindable!(const Filename)[string] queue;
bool[string] _loggedMissingImages;

// In September 2016, 0.6.17, I removed the no-effect decoration. I sed'd the
// levels that ship with the game, they don't feature no-effect decoration
// since. Backwards-compat replacement for levels that I don't maintain:
enum string[string] _silentReplacements = [
    "amanda/forest/lantern.D" : "", // Replace with "" means don't add a tile,
    "amanda/forest/exit_decal.D" : "", // but don't raise an error either.
    "matt/beach/decor/bonfire.D" : "matt/beach/decor/bonfire.F",
    "matt/beach/decor/moon.D" : "matt/beach/decor/moon",
    "matt/beach/decor/sun.D" : "matt/beach/decor/sun",
    "matt/goldmine/GoalTop.D" : "",
    "matt/goldmine/minecart.D" : "matt/goldmine/minecart",
    "matt/goldmine/pickaxe.D" : "matt/goldmine/pickaxe",
    "matt/goldmine/shovel.D" : "matt/goldmine/shovel",
    "simon/rabbit.D" : "",
];

private const(T) get_tile(T : AbstractTile, alias container)(in string str)
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
    bool subtype = false;
    if      (pe == glo.preExtHatch) { type = GadType.HATCH; }
    else if (pe == glo.preExtGoal)  { type = GadType.GOAL;  }
    else if (pe == glo.preExtTrap)  { type = GadType.TRAP;  }
    else if (pe == glo.preExtWater) { type = GadType.WATER; }
    else if (pe == glo.preExtFire)  { type = GadType.WATER; subtype = true; }
    else {
        logf("Unrecognized pre-extension `%c': `%s'", pe, fn.rootless);
        return;
    }

    Cutbit cb = new Cutbit(fn, Cutbit.Cut.ifGridExists);
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
    tile.logAnyErrors(strNoExt);
}

void loadTerrainFromDisk(in string strNoExt, in bool steel, in Filename fn)
{
    Cutbit cb = new Cutbit(fn, Cutbit.Cut.no);
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

