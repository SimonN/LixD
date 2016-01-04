module file.search;

// Finding files and browsing directories. No virtual file system is
// implemented here.

import std.file;
import std.string;

import file.filename;

bool fileExists(const Filename fn)
{
    string noslash = fn.rootful;
    if (noslash != null && noslash[$-1] == '/')
        return false;
    return std.file.exists(noslash) &&  ! std.file.isDir (noslash);
}

// dirExists(a/b/) checks if b exists.
// dirExists(a/b/c) checks if b exists, no matter whether the file c is inside.
bool dirExists(const Filename fn)
{
    string noslash = fn.dirRootful;
    while (noslash != null && noslash[$-1] == '/') noslash = noslash[0 .. $-1];
    return std.file.exists(noslash)
     &&    std.file.isDir (noslash);
}

// Whenever what == "", every possible file is retrieved because
// hasCorrectEnding("") will always be true; see that function for details.
Filename[] findRegularFilesNoRecursion(
    const Filename fnWhere,
    const string   what = "",
) {
    Filename[] ret;
    // shallow = don't recurse through subdirs, true = follow symlinks
    foreach (string s; std.file.dirEntries(fnWhere.rootful,
                                           SpanMode.shallow, true))
        if (! std.file.isDir(s) && s.hasCorrectEnding(what))
            ret ~= new Filename(s.tr("\\", "/"));
    return ret;
}

Filename[] findDirsNoRecursion(
    const Filename fnWhere
) {
    Filename[] ret;
    foreach (string s; std.file.dirEntries(fnWhere.rootful,
                                           SpanMode.shallow, true))
        if (std.file.isDir(s))
            // convention: dirs have a trailing slash, and dirEntries
            // doesn't add one at the end
            ret ~= new Filename(s.tr("\\", "/") ~ "/");
    return ret;
}

Filename[] findRegularFilesRecursively(
    const Filename fnWhere,
    const string   what = "",
) {
    Filename[] ret;
    // breadth-first search through the entire given tree
    foreach (string s; std.file.dirEntries(fnWhere.rootful,
                                           SpanMode.breadth, true))
        if (! std.file.isDir(s) && s.hasCorrectEnding(what))
            ret ~= new Filename(s.tr("\\", "/"));
    return ret;
}

private pure bool hasCorrectEnding(const string fn, const string ending)
{
    return fn.length >= ending.length
     &&    fn[($ - ending.length) .. $] == ending;
}
