module file.search;

import std.file;

import file.filename;

// Finding files and browsing directories. No virtual file system is
// implemented here.

// find_files() finds only regular files, no dirs, and has no recursion.
// find_dirs()  finds only dirs, and has no recursion.
// find_tree()  finds only regular files, no dirs, recursing through subdirs.
// Whenever what == "", every possible file is retrieved because
// has_correct_ending("") will always be true; see that function for details.
const(Filename)[] find_files(const Filename fn_where, const string what = "");
const(Filename)[] find_dirs (const Filename fn_where);
const(Filename)[] find_tree (const Filename fn_where, const string what = "");

bool file_exists(const Filename); // test if exists as regular file, not a dir
bool dir_exists(const Filename);  // test if exists as dir



private pure bool has_correct_ending(const string fn, const string ending)
{
    return fn.length >= ending.length
     &&    fn[($ - ending.length) .. $] == ending;
}



const(Filename)[] find_files(
    const Filename fn_where,
    const string   what = "",
) {
    const(Filename)[] ret;
    // shallow = don't recurse through subdirs, true = follow symlinks
    foreach (string s; std.file.dirEntries(fn_where.get_rootful(),
                                           SpanMode.shallow, true)) {
        if (! std.file.isDir(s) && s.has_correct_ending(what)) {
            ret ~= new Filename(s);
        }
    }
    return ret;
}



const(Filename)[] find_dirs(
    const Filename fn_where
) {
    const(Filename)[] ret;
    foreach (string s; std.file.dirEntries(fn_where.get_rootful(),
                                           SpanMode.shallow, true)) {
        if (std.file.isDir(s)) {
            // convention: dirs have a trailing slash, and dirEntries
            // doesn't add one at the end
            ret ~= new Filename(s ~ "/");
        }
    }
    return ret;
}



const(Filename)[] find_tree(
    const Filename fn_where,
    const string   what = "",
) {
    const(Filename)[] ret;
    // breadth-first search through the entire given tree
    foreach (string s; std.file.dirEntries(fn_where.get_rootful(),
                                           SpanMode.breadth, true)) {
        if (! std.file.isDir(s) && s.has_correct_ending(what)) {
            ret ~= new Filename(s);
        }
    }
    return ret;
}



bool file_exists(const Filename fn)
{
    string noslash = fn.get_rootful();
    if (noslash != null && noslash[$-1] == '/') return false;
    return std.file.exists(noslash)
     &&  ! std.file.isDir (noslash);
}



bool dir_exists(const Filename fn)
{
    string noslash = fn.get_rootful();
    while (noslash != null && noslash[$-1] == '/') noslash = noslash[0 .. $-1];
    return std.file.exists(noslash)
     &&    std.file.isDir (noslash);
}
