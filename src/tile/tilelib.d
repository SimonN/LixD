module tile.tilelib;

/* This was class ObjLib in C++/A4 Lix.
 * In D/A5 Lix, it's not a class anymore, but module-level functions.
 */

import std.algorithm;
import std.conv; // ulong -> int for string lengths
import std.typecons; // Rebindable!(const Filename)

import optional;

static import glo = basics.globals;

import basics.help; // clear_array
import file.filename;
import file.io;
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

// For most tiles, their name is the filename without "images/", without
// extension, but with pre-extension in case the filename has one
// This doesn't resolve groups because tilelib doesn't know about group
// names, it merely knows about group keys, see getGroup().
Optional!(const(AbstractTile)) resolveTileName(in string name)
{
    if (const(AbstractTile)* ptr = name in terrain) {
        return some(*ptr);
    }
    else if (const(AbstractTile)* ptr = name in gadgets) {
        return some(*ptr);
    }
    else if (name in _loggedMissingImages) {
        return no!(const(AbstractTile));
    }
    loadTileFromDisk(name);
    return resolveTileName(name);
}

Optional!(const(AbstractTile)) resolveTileName(Filename fn)
{
    if (! fn || fn.rootlessNoExt.length < glo.dirImages.rootlessNoExt.length)
        return no!(const(AbstractTile));
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
out {
    const tile = (strNoExt in gadgets);
    assert (tile && *tile);
}
body {
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
    // Some tiles have gadget definition files:
    // Same name, minus extension, plus ".txt".
    Filename defs = new VfsFilename(fn.rootlessNoExt
        ~ glo.filenameExtTileDefinitions);
    const(IoLine)[] defVec;
    // Missing file shall be no error, but merely result in empty defVec.
    // We want to log only on bad UTF-8 etc. in an existing file.
    if (defs.fileExists) {
        try {
            defVec = fillVectorFromFile(defs);
        }
        catch (Exception e) {
            logf("Error reading gadget definitions `%s':", defs.rootless);
            logf("    -> %s", e.msg);
            logf("    -> Falling back to default gadget properties.");
            return;
        }
    }
    gadgets[strNoExt] = GadgetTile.takeOverCutbit(
        strNoExt, cb, type, subtype, defVec);
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
