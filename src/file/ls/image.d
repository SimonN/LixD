module file.ls.image;

import std.array;
import std.algorithm;

import file.filename;
import file.ls.baseord;

abstract class ImageLs : AlphabeticalLs {
private:
    const(string) _allowedPreExts;

public:
    this(string allowedPreExts)
    {
        _allowedPreExts = allowedPreExts;
    }

protected:
    override bool searchCriterion(Filename fn) const
    {
        if (! fn.hasImageExtension)
            return false;
        if (_allowedPreExts.length == 0)
            return true;
        return _allowedPreExts.canFind(fn.preExtension);
    }
}

/*
 * MergeAllDirsLs
 * Show no directories at all, instead show all files from all subdirectories.
 */
class MergeAllDirsLs : ImageLs {
public:
    this(string allowedPreExts) { super(allowedPreExts); }

protected:
    final override MutFilename[] dirsInCurrentDir() const { return []; }
    final override MutFilename[] filesInCurrentDir() const
    {
        return currentDir.findTree();
    }
}

/*
 * TilesetLs
 * Assume that the tree of tiles contains these files.
 *  simon/a/tile1.png
 *  simon/a/tile2.png
 *  simon/b/c/tile3.png
 *  simon/b/d/tile4.png
 *  geoo/a/tile5.png
 *  geoo/a/x/y/z/tile6.png
 * The editor tile browser should present 3 directories:
 *  simon/a
 *  simon/b
 *  geoo/a
 * After selecting one of these dirs in the Tiler, the Tiler will then
 * list all (tiles that are found recursively within that dir) in a flat list.
 */
class TilesetLs : ImageLs {
private:
    Filename _baseDir;

public:
    this(Filename baseDir, string allowedPreExts)
    {
        super(allowedPreExts);
        _baseDir = baseDir.guaranteedDirOnly();
    }

protected:
    final override MutFilename[] dirsInCurrentDir() const
    {
        if (isWithinTileset) {
            return [];
        }
        else {
            // Return the dirs of depth 2 from the base dir.
            // Hack: currentDir is not necessarily _baseDir here.
            // We give Breadcrumb full control over dir switching,
            // including switching to a depth-1-dir, and from such a
            // depth-1-dir, we still list everything depth-2 from _baseDir.
            return _baseDir.findDirs().map!(
                    // Hack: guideline/ should be listed as a depth-1 dir.
                    // Thus, list depth-1 dirs without subdirectories
                    dir => dir.findDirs().empty ? [dir] : dir.findDirs()
                ).joiner.filter!(
                    // Hack: Terrain browser should not list steel dirs.
                    // We assume here that we'll only ever be used on terrain.
                    // It happens that all steel dirs are called "steel/",
                    // an unwritten convention, thus...
                    dir => dir.dirInnermost != "steel/"
                ).array;
        }
    }

    final override MutFilename[] filesInCurrentDir() const
    {
        return isWithinTileset ? currentDir.findTree() : [];
    }

protected:
    override void sortDirs(MutFilename[] arr) const
    {
        arr.sort!((a, b) => a.dirInnermost < b.dirInnermost);
    }

private:
    /*
     * We can either be in a tileset already, then we'll list all its tiles,
     * or we can be in an outer dir, then we'll list directories and no tiles.
     */
    bool isWithinTileset() const
    {
        return currentDir.rootless.length > _baseDir.rootless.length;
    }
}
