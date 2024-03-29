module file.ls.baseord;

/*
 * Ls looks for dirs/files based on its own criteria.
 * Ls is not concerned with displaying the dirs/files with certain styles
 * of buttons in a Picker. Instead, Tiler does that.
 *
 * This module (baseord) contains the base Ls
 * and the OrderFile Ls
 * because there is a unittest that uses internals of both.
 */

import std.algorithm;
import std.conv;
import std.range;

static import basics.globals;
import basics.help;
import file.filename;
import file.io; // semantics not used, we only read line-by-line
import file.log;

class Ls {
private:
    MutFilename _currentDir;
    Filename[] _dirs;
    Filename[] _files;

public:
    final @property          dirs()       const { return _dirs; }
    final @property          files()      const { return _files; }
    final @property Filename currentDir() const { return _currentDir; }

    /*
     * Switch directory.
     * Throws File Exception if not found.
     * Short-circuits if the directory is the same as the old one,
     * call forceRloadOfCurrentDir manually to subvert that short-circuiting.
     */
    final @property Filename currentDir(Filename newDir)
    in {
        assert (newDir !is null, "Ls.currentDir = null: forbidden");
        assert (newDir.file == "", "Ls.currentDir = regular file: forbidden");
    }
    do {
        if (newDir == currentDir) {
            return currentDir;
        }
        _currentDir = newDir;
        forceReloadOfCurrentDir();
        return currentDir;
    }

    /*
     * Throws File Exception if not found.
     * Typically forceReloadOfCurrentDir is called only from currentDir setter.
     * But Picker will expose a forced reload; that must be able to call us.
     */
    final void forceReloadOfCurrentDir()
    {
        auto tempD = dirsInCurrentDir.filter!(f => visibleCriterion(f)).array;
        auto tempF = filesInCurrentDir.filter!(f => searchCriterion(f)
                                                && visibleCriterion(f)).array;
        beforeSortingForCurrentDir();
        sortDirs (tempD);
        sortFiles(tempF);
        Filename deMut(in MutFilename a) { return a; }
        _dirs  = tempD.map!deMut.array;
        _files = tempF.map!deMut.array;
    }

    // This function treats the dirs and files as if they were in one long
    // list, the dirs coming before the files. This is strange for Ls.
    final Filename moveHighlightBy(Filename old, in int by)
    {
        if (dirs.empty && files.empty)
            return null;
        auto both    = chain(dirs, files);
        auto bothLen = dirs.len + files.len;
        int id = both.countUntil(old).to!int + by;
        if (id < by)
            // No current file. Highlight the first or last entry.
            // We are guaranteed at least one entry in one of the lists.
            id = (by >= 0) ? 0 : bothLen - 1;
        if (id < 0)
            id = (id - by == 0) ? bothLen - 1 : 0;
        else if (id >= bothLen)
            id = (id - by == bothLen - 1) ? 0 : bothLen - 1;
        return (id < dirs.len) ? dirs[id] : files[id - dirs.len];
    }

    final void deleteFile(Filename toDelete)
    {
        assert (toDelete);
        try
            toDelete.deleteFile();
        catch (Exception e)
            log(e.msg);
        // Now refresh the directory listing.
        Filename temp = _currentDir;
        _currentDir = null;
        currentDir = temp;
    }

protected:
    void beforeSortingForCurrentDir() { }
    void sortDirs (MutFilename[]) const { }
    void sortFiles(MutFilename[]) const { }

    MutFilename[] dirsInCurrentDir() const
    {
        return currentDir.findDirs();
    }

    MutFilename[] filesInCurrentDir() const
    {
        return currentDir.findFiles();
    }

    bool searchCriterion(Filename) const { return true; }
    bool visibleCriterion(Filename fn) const
    {
        if (fn.preExtension == basics.globals.preExtHiddenFile)
            return false; // .X.txt
        else if (fn.fileNoExtNoPre.length > 1)
            return fn.fileNoExtNoPre[0] != '.'; // no Unix hidden file
        else
            return fn.dirInnermost.length == 0 || fn.dirInnermost[0] != '.';
    }
}

class AlphabeticalLs : Ls {
protected:
    override void beforeSortingForCurrentDir() { }
    override void sortDirs (MutFilename[] arr) const { arr.sort!fnLessThan; }
    override void sortFiles(MutFilename[] arr) const { arr.sort!fnLessThan; }
}

/*
 * OrderFileLs is for level directories.
 * Level directories may be ordered by a separate file named
 * basics.globals.fileLevelDirOrder that sits in the to-be-ordered dir.
 */
class OrderFileLs : Ls {
private:
    string[] _order;

protected:
    final override void beforeSortingForCurrentDir()
    {
        _order = [];
        try _order = fillVectorFromFileRaw(new VfsFilename(
            currentDir.dirRootless ~ basics.globals.fileLevelDirOrder));
        catch (Exception e) {
            // Don't report. A missing ordering file is not an error at all.
        }
    }

    final override void sortDirs(MutFilename[] unsorted) const
    {
        sortByOrderFile(unsorted, &appendSlash);
    }

    final override void sortFiles(MutFilename[] unsorted) const
    {
        sortByOrderFile(unsorted, (string s) { return s; });
    }

private:
    void sortByOrderFile(
        MutFilename[] unsortedRemainder,
        string function(string) pure stringModifier
    ) const {
        // Sort whatever is encountered in the order file to the beginning.
        // What is pulled out earliest shall go at the very beginning.
        void pullFromUnsorted(MutFilename fn)
        {
            MutFilename[] found = unsortedRemainder.find(MutFilename(fn));
            if (found.length) {
                swap(found[0], unsortedRemainder[0]);
                unsortedRemainder = unsortedRemainder[1 .. $];
            }
        }
        _order
            .map!stringModifier
            .map!(entry => new VfsFilename(currentDir.dirRootless ~ entry))
            .map!(fn => MutFilename(fn))
            .each!pullFromUnsorted;
        unsortedRemainder.sort!fnLessThan;
    }

    static string appendSlash(string entry) pure
    {
        // dirs can be named as "somedir" or "somedir/", both shall work
        return (entry.length && entry[$-1] != '/') ? entry ~ '/' : entry;
    }
}

unittest
{
    auto ls = new OrderFileLs;
    ls._currentDir = new VfsFilename("./mydir/");
    ls._order = ["order1", "moreorder2/", "evenmore3"];
    auto mydirs = [
        new VfsFilename("./mydir/b/"),
        new VfsFilename("./mydir/moreorder2/"),
        new VfsFilename("./mydir/c/"),
        new VfsFilename("./mydir/order1/"),
        new VfsFilename("./mydir/a/")
        ].map!(fn => MutFilename(fn)).array;
    ls.sortDirs(mydirs);
    assert (mydirs[0] == MutFilename(new VfsFilename("./mydir/order1/")));
    assert (mydirs[1] == MutFilename(new VfsFilename("./mydir/moreorder2/")));
    assert (mydirs[2] == MutFilename(new VfsFilename("./mydir/a/")));
}
