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

// There is no initialize(). Choose a screen mode, then start loading tiles.
// deinitialize() clears all VRAM, allowing you to select a new screen mode.
void deinitialize()
{
    void destroyArray(T)(ref T arr)
    {
        foreach (tile; arr)
            if (tile !is null)
                tile.dispose();
        arr = null;
    }
    destroyArray(terrain);
    destroyArray(gadgets);
    destroyArray(groups);
    _loggedMissingImages = null;
}

// Feeble attempt to avoid dynamic cast :-( Maybe ripe for the visitor pattern.
struct ResolvedTile {
    const(TerrainTile) terrain;
    const(GadgetTile) gadget;
    const(TileGroup) group;

    @property const(AbstractTile) tile() const
    {
        return terrain ? terrain : gadget ? gadget : group;
    }
}

// For most tiles, their name is the filename without "images/", without
// extension, but with pre-extension in case the filename has one
// This doesn't resolve groups because tilelib doesn't know about group
// names, it merely knows about group keys, see getGroup().
ResolvedTile resolveTileName(in string name)
{
    if (auto ptr = name in terrain)
        return ResolvedTile(*ptr, null, null);
    else if (auto ptr = name in gadgets)
        return ResolvedTile(null, *ptr, null);
    else if (name in _loggedMissingImages)
        return ResolvedTile();
    loadTileFromDisk(name);
    return resolveTileName(name);
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

// ############################################################################

private:

TerrainTile[string] terrain;
GadgetTile [string] gadgets;
TileGroup[TileGroupKey] groups;
bool[string] _loggedMissingImages;

void loadTileFromDisk(in string name)
{
    version (tharsisprofiling)
        auto zone = Zone(profiler, "tilelib loadTileFromDisk");
    Filename fn = nameToFoundFileOrNull(name);
    if (! fn) {
        logBadTile!"Tile missing"(name);
        return;
    }
    immutable pe = fn.preExtension;
    if (pe == 0 || pe == glo.preExtSteel)
        loadTerrainFromDisk(name, pe, fn);
    else
        loadGadgetFromDisk(name, pe, fn);
}

Filename nameToFoundFileOrNull(in string name)
{
    version (tharsisprofiling)
        auto zone = Zone(profiler, "tilelib nameToFilename");
    static assert (imageExtensions[0] == ".png", "png should be most common");
    foreach (ext; imageExtensions) {
        auto fn = new VfsFilename(glo.dirImages.dirRootless ~ name ~ ext);
        if (fn.fileExists)
            return fn;
    }
    return null;
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
        logBadTile!"Unknown pre-extension"(strNoExt);
        return;
    }

    Cutbit cb = new Cutbit(fn, Cutbit.Cut.ifGridExists);
    if (! cb.valid) {
        logBadTile!"Canvas too large"(strNoExt);
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

void loadTerrainFromDisk(in string strNoExt, in char pe, in Filename fn)
{
    Cutbit cb = new Cutbit(fn, Cutbit.Cut.no);
    if (! cb.valid) {
        logBadTile!"Canvas too large"(strNoExt);
        return;
    }
    terrain[strNoExt] = TerrainTile
        .takeOverCutbit(strNoExt, cb, pe == glo.preExtSteel);
}

void logBadTile(string reason)(in string name)
{
    if (name in _loggedMissingImages)
        return;
    _loggedMissingImages[name] = true;
    logf("%s: `%s'", reason, name);
}
