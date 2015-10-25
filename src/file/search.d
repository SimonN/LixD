module file.search;

import std.file;
import std.string;

import file.filename;

// Finding files and browsing directories. No virtual file system is
// implemented here.

// findFiles() finds only regular files, no dirs, and has no recursion.
// findDirs()  finds only dirs, and has no recursion.
// findTree()  finds only regular files, no dirs, recursing through subdirs.
// Whenever what == "", every possible file is retrieved because
// hasCorrectEnding("") will always be true; see that function for details.
Filename[] findFiles(const Filename fnWhere, const string what = "");
Filename[] findDirs (const Filename fnWhere);
Filename[] findTree (const Filename fnWhere, const string what = "");

bool fileExists(const Filename); // test if exists as regular file, not a dir
bool dirExists (const Filename); // test if exists as dir



private pure bool hasCorrectEnding(const string fn, const string ending)
{
    return fn.length >= ending.length
     &&    fn[($ - ending.length) .. $] == ending;
}



Filename[] findFiles(
    const Filename fnWhere,
    const string   what = "",
) {
    Filename[] ret;
    // shallow = don't recurse through subdirs, true = follow symlinks
    foreach (string s; std.file.dirEntries(fnWhere.rootful,
                                           SpanMode.shallow, true)) {
        if (! std.file.isDir(s) && s.hasCorrectEnding(what)) {
            ret ~= new Filename(s.tr("\\", "/"));
        }
    }
    return ret;
}



Filename[] findDirs(
    const Filename fnWhere
) {
    Filename[] ret;
    foreach (string s; std.file.dirEntries(fnWhere.rootful,
                                           SpanMode.shallow, true)) {
        if (std.file.isDir(s)) {
            // convention: dirs have a trailing slash, and dirEntries
            // doesn't add one at the end
            ret ~= new Filename(s.tr("\\", "/") ~ "/");
        }
    }
    return ret;
}



Filename[] findTree(
    const Filename fnWhere,
    const string   what = "",
) {
    Filename[] ret;
    // breadth-first search through the entire given tree
    foreach (string s; std.file.dirEntries(fnWhere.rootful,
                                           SpanMode.breadth, true)) {
        if (! std.file.isDir(s) && s.hasCorrectEnding(what)) {
            ret ~= new Filename(s.tr("\\", "/"));
        }
    }
    return ret;
}



bool fileExists(const Filename fn)
{
    string noslash = fn.rootful;
    if (noslash != null && noslash[$-1] == '/') return false;
    return std.file.exists(noslash)
     &&  ! std.file.isDir (noslash);
}



bool dirExists(const Filename fn)
{
    string noslash = fn.rootful;
    while (noslash != null && noslash[$-1] == '/') noslash = noslash[0 .. $-1];
    return std.file.exists(noslash)
     &&    std.file.isDir (noslash);
}
