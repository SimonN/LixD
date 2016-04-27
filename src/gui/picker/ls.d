module gui.picker.ls;

import std.algorithm;
import std.array;
import std.conv;
import std.range;

import basics.globals;
import basics.help;
import file.filename;
import file.io;
import file.search;

class Ls {
private:
    MutFilename _currentDir;
    Filename[] _dirs;
    Filename[] _files;

public:
    final @property          dirs()       const { return _dirs; }
    final @property          files()      const { return _files; }
    final @property Filename currentDir() const { return _currentDir; }

    final @property Filename currentDir(Filename newDir)
    {
        assert (newDir.file == "");
        if (newDir == currentDir)
            return currentDir;
        _currentDir = newDir;
        if (! currentDir)
            return currentDir;
        auto tempD = findDirsNoRecursion(currentDir);
        auto tempF = findRegularFilesNoRecursion(currentDir)
            .filter!(f => searchCriterion(f)).array;
        beforeSortingForCurrentDir();
        sortDirs (tempD);
        sortFiles(tempF);

        Filename deMut(in MutFilename a) { return a; }
        _dirs  = tempD.map!deMut.array;
        _files = tempF.map!deMut.array;
        return currentDir;
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
        id =  id < 0        ? bothLen - 1
            : id >= bothLen ? 0
            : id;
        return (id < dirs.len) ? dirs[id] : files[id - dirs.len];
    }

protected:
    bool searchCriterion(Filename) const { return true; }
    void beforeSortingForCurrentDir() { }
    void sortDirs (MutFilename[]) const { }
    void sortFiles(MutFilename[]) const { }
}

class AlphabeticalLs : Ls {
protected:
    final override void beforeSortingForCurrentDir() { }
    final override void sortDirs (MutFilename[] arr) const { arr.sort(); }
    final override void sortFiles(MutFilename[] arr) const { arr.sort(); }
}

class OrderFileLs : Ls {
private:
    string[] _order;

protected:
    override bool searchCriterion(Filename fn) const
    {
        return fn.preExtension != basics.globals.preExtHiddenFile;
    }

    final override void beforeSortingForCurrentDir()
    {
        try _order = fillVectorFromFileRaw(new Filename(
            currentDir.dirRootful ~ basics.globals.fileLevelDirOrder));
        catch (Exception e) {
            // do nothing, missing ordering file is not an error at all
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
            .map!(entry => new Filename(currentDir.dirRootful ~ entry))
            .map!(fn => MutFilename(fn))
            .each!pullFromUnsorted;
        unsortedRemainder.sort();
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
    ls._currentDir = new Filename("./mydir/");
    ls._order = ["order1", "moreorder2/", "evenmore3"];
    auto mydirs = [
        new Filename("./mydir/b/"),
        new Filename("./mydir/moreorder2/"),
        new Filename("./mydir/c/"),
        new Filename("./mydir/order1/"),
        new Filename("./mydir/a/")
        ].map!(fn => MutFilename(fn)).array;
    ls.sortDirs(mydirs);
    assert (mydirs == [
        new Filename("./mydir/order1/"),
        new Filename("./mydir/moreorder2/"),
        new Filename("./mydir/a/"),
        new Filename("./mydir/b/"),
        new Filename("./mydir/c/")
        ].map!(fn => MutFilename(fn)).array);
}
