module file.filename.vfsfile;

/* A virtual file system, together with VfsFilename that points into this
 * virtual filesystem. Most Filenames in the application are VfsFilenames.
 *
 * When you want to read data from a VfsFilename, vfs scans multiple
 * directories in a fixed order, and returns the first found file.
 *
 * I haven't tested how this works for multiple read-only directories!
 * file.search should be incorporated in this module, that's one problem.
 *
 * When you want to write data to a VfsFilename, vfs gives you a set location,
 * typically the most important directory to read from.
 */

import std.algorithm;
import std.array; // property empty
import std.conv; // to!long for string length
import std.file;
import std.string;
import std.stdio; // File
import std.utf;

import basics.help;
import file.filename.base;
import file.filename.fhs;

public alias VfsFilename = immutable(_VfsFilename);

// You should call this before you make calls to any other public function.
// This will decide whether we're FHS-installed or self-contained.
public void initialize()
{
    rootForWriting = getRootForWriting();
    rootsForReading = getRootsForReading();
}

private class _VfsFilename : IFilename {
private:
    immutable string _rootless;
    immutable string _extension;
    immutable string _rootlessNoExt;
    immutable string _file;
    immutable string _fileNoExts;
    immutable string _dirRootless;
    immutable string _dirInnermost;
    immutable char _preExtension;

public:
    @property nothrow immutable string rootless()       { return _rootless; }
    @property nothrow immutable string extension()      { return _extension; }
    @property nothrow immutable string file()           { return _file; }
    @property nothrow immutable string rootlessNoExt()  { return _rootlessNoExt; }
    @property nothrow immutable string fileNoExtNoPre() { return _fileNoExts; }
    @property nothrow immutable string dirRootless()    { return _dirRootless; }
    @property nothrow immutable string dirInnermost()   { return _dirInnermost; }
    @property nothrow immutable char   preExtension()   { return _preExtension; }

    // Throws Exception if file not found in any of the VFS trees.
    std.stdio.File openForReading(in string mode = "r") immutable
    {
        auto resolved = resolveForReading(this, LookFor.files);
        if (resolved == "")
            // FileException will add "file not found" to the message anyway?
            throw new FileException(format!"VFS file `%s'"(_rootless));
        return std.stdio.File(resolved, mode);
    }

    // I believe this throws if it can't open the file or mkdir -p its dir.
    std.stdio.File openForWriting(in string mode = "w") immutable
    {
        assert (rootForWriting != "", "call VFS initialize before this");
        this.mkdirRecurse();
        return std.stdio.File(rootForWriting ~ rootless, mode);
    }

    // Silently returns null if file not found
    string stringForReading() immutable nothrow
    {
        return resolveForReading(this, LookFor.filesAndDirs);
    }

    // throws on error
    const(void)[] readIntoVoidArray() immutable
    {
        return std.file.read(resolveForReading(this, LookFor.files));
    }

    string stringForWriting() immutable
    {
        assert (rootForWriting != "", "call VFS initialize before this");
        this.mkdirRecurse();
        return rootForWriting ~ rootless;
    }

    // Test if a file exists for reading in one of the trees.
    // VfsFilenames like a/b/ with trailing slash are considered dirs,
    // they won't even get tested by the file-system functions.
    // Maybe too slow because I rely on the internal throwing?
    bool fileExists() immutable nothrow
    {
        if (rootless.length && rootless[$-1] == '/')
            return false;
        return resolveForReading(this, LookFor.files) != "";
    }

    // dirExists(a/b/) checks if b exists.
    // dirExists(a/b/c) checks if b exists, no matter whether file c is inside.
    bool dirExists() immutable nothrow
    {
        return resolveForReading(guaranteedDirOnly, LookFor.dirs) != "";
    }

    // Throws if the dir doesn't exist after the system call.
    void mkdirRecurse() immutable
    {
        assert (rootForWriting != "", "call VFS initialize() first");
        std.file.mkdirRecurse(rootForWriting ~ dirRootless);
        if (! dirExists)
            throw new FileException("cannot mkdirRecurse(" ~ dirRootless ~ ")");
    }

    // Throws on error.
    // You can only delete files in the writing tree. The GUI will probably
    // offer you to delete many files, even if they are in read-only trees,
    // and this function will then have no effect. Design hole, I have to
    // find a good solution.
    void deleteFile() immutable
    {
        assert (rootForWriting != "", "call VFS initialize() first");
        immutable realFile = rootForWriting ~ rootless;
        if (std.file.exists(realFile))
            std.file.remove(realFile);
    }

    this(in string s) immutable nothrow
    {
        try
            s.validate();
        catch (Exception)
            return; // We are nothrow. Probably bad design

        assert (s.length < int.max);
        _rootless = pruneRoots(s);

        // Determine the extension by finding the last '.'
        int lastDot = _rootless.len - 1;
        int extensionLength = 0;
        while (lastDot >= 0 && _rootless[lastDot] != '.') {
            // Dots that precede the final slash don't count as an extension
            // separator, because they're in directory names.
            if (_rootless[lastDot] == '/') {
                lastDot = -1;
                extensionLength = 0;
            }
            else {
                --lastDot;
                ++extensionLength;
            }
        }
        // Now, (lastDot == -1) holds iff there is no dot in the filename.
        // Don't mistake a pre-extension (1 uppercase letter) for an extension.
        if (lastDot >= 0 && (extensionLength >= 2
            || (extensionLength >= 1 &&
                ! (_rootless[lastDot + 1] >= 'A'
                && _rootless[lastDot + 1] <= 'Z')
            ))) {
            _extension     = _rootless[lastDot .. $];
            _rootlessNoExt = _rootless[0 .. lastDot];
        }
        else {
            // extension stays empty
            _rootlessNoExt = _rootless;
        }
        // Determine the pre-extension or leave it at '\0'.
        if (lastDot >= 2 && _rootless[lastDot - 2] == '.'
            && (_rootless[lastDot - 1] >= 'A'
            &&  _rootless[lastDot - 1] <= 'Z')
        ) {
            _preExtension = _rootless[lastDot - 1];
        }
        else
            _preExtension = 0;

        // Determine the file.
        int lastSlash = _rootless.len - 1;
        while (lastSlash >= 0 && _rootless[lastSlash] != '/')
            --lastSlash;
        if (lastSlash >= 0) {
            _file        = _rootless[lastSlash + 1 .. $];
            _dirRootless = _rootless[0 .. lastSlash + 1];
        }
        else {
            _file = _rootless;
            _dirRootless = "";
        }
        // _fileNoExts is _file chopped off at the dot before the pre-ext.
        // If there is no pre-ext, it's _file chopped off at dot before ext.
        int fp = _file.len - _extension.len - (_preExtension == 0 ? 0 : 2);
        _fileNoExts = fp > 0 ? _file[0 .. fp] : _file;

        // find the innermost dir, based on the now-set dirRootless.
        // sls = "second-last slash"
        int sls = _dirRootless.len - 1;
        // don't treat the final slash as the second-to-last slash
        if (sls >= 0 && _dirRootless[sls] == '/')
            --sls;
        while (sls >= 0 && _dirRootless[sls] != '/')
            --sls;
        // sls can be -1, or somewhere in the file. Start behind this.
        // Contain the trailing slash of the directory.
        _dirInnermost = _dirRootless[sls + 1 .. $];
    }

    override bool
    opEquals(Object rhs_obj) const
    {
        auto rhs = cast (const typeof(this)) rhs_obj;
        return rhs && this._rootless == rhs._rootless;
    }

    // This function exists only to please the runtime during AA lookup.
    // I got runtime crashes due to missing opCmp, but no compiler errors. :-/
    override int opCmp(Object rhs)
    {
        auto r = cast (immutable(typeof(this))) rhs;
        auto l = cast (immutable(typeof(this))) this;
        return r.fnLessThan(l) - l.fnLessThan(r);
    }

    @trusted override size_t toHash() const nothrow
    {
        return typeid(_rootless).getHash(&_rootless);
    }

    VfsFilename guaranteedDirOnly() immutable nothrow
    {
        assert (dirRootless.empty || dirRootless[$-1] == '/');
        return file.length == 0 ? this : new VfsFilename(dirRootless);
    }

protected:
    MutFilename[] findImpl(in SpanMode spanMode,
                           in bool wantDirs, in string what) immutable
    {
        assert (! rootsForReading.empty);
        MutFilename[] ret;
        ROOTS: foreach (root; rootsForReading) {
            string oneDir = root ~ dirRootless;
            if (! std.file.exists(oneDir) || ! std.file.isDir(oneDir))
                continue ROOTS;
            // true = follow symlinks
            ret ~= std.file.dirEntries(oneDir, spanMode, true)
                .filter!(f => std.file.isDir(f.name) == wantDirs
                           && f.name.hasEnding(what))
                .map!(s => s.tr("\\", "/") ~ (wantDirs ? "/" : ""))
                .map!(s => MutFilename(new VfsFilename(s)))
                .array;
        }
        if (rootsForReading.length == 1)
            return ret;
        return ret.sort!fnLessThan.uniq.array;
    }
}
// end class

unittest
{
    auto a = new VfsFilename("mydir/anotherdir/many.dots.in.this.one.txt");
    assert (a.extension == ".txt");
    assert (a.preExtension == 0);
    assert (a.file == "many.dots.in.this.one.txt");
    assert (a.fileNoExtNoPre == "many.dots.in.this.one");
    assert (a.dirRootless == "mydir/anotherdir/");

    Filename b = new VfsFilename("mydir/anotherdir/myfile.with.dots.P.txt");
    assert (b.preExtension == 'P');
    assert (b.file == "myfile.with.dots.P.txt");
    assert (b.fileNoExtNoPre == "myfile.with.dots");

    Filename c = new VfsFilename("noslashes");
    assert (c.file == "noslashes");
    assert (c.dirRootless == "");

    Filename d = new VfsFilename("dot.before/last/slash");
    assert (d.extension == "");
    assert (d.rootlessNoExt == "dot.before/last/slash");
    assert (d.file == "slash");
    assert (d.dirRootless == "dot.before/last/");
}

// #################################################################### private

private:

string rootForWriting;
string[] rootsForReading; // Try the roots from from to back.
                                  // The local, writeable root should be first.
                                  // The computer-global root should be last.

enum LookFor { files, dirs, filesAndDirs }

string resolveForReading(VfsFilename fn, in LookFor lookFor) nothrow
{
    assert (rootsForReading.length, "call VFS initialize() before this");
    assert (fn !is null, "Don't pass null VfsFilenames to this.");
    try foreach (root; rootsForReading) {
        immutable realFile = root ~ fn.rootless;
        if (! std.file.exists(realFile))
            continue;
        immutable bool dir = std.file.isDir(realFile);
        if (lookFor == LookFor.filesAndDirs
            || lookFor == LookFor.files && ! dir
            || lookFor == LookFor.dirs && dir)
            return realFile;
    }
    catch (Exception)
        { }
    return null;
}

string pruneRoots(in string tail) nothrow @nogc
{
    foreach (root; rootsForReading)
        if (tail.startsWith(root))
            return pruneRoots(tail[root.length .. $]);
    return tail;
}

unittest {
    import std.conv;
    import basics.globals;
    initialize();
    Filename fn = new VfsFilename(basics.globals.dirDataSound.rootless ~
        "hatch.ogg");
    assert (fn !is null);
    assert (fn.rootless != "");
    assert (fn.fileExists, "unittest relies on sound file `hatch.ogg'");
    Filename fn2 = new VfsFilename(fn.stringForReading);
    assert (fn == fn2);
}
