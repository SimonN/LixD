module file.nextlev.tree.dir;

/*
 * TreeRhino, TreeLevelCache:
 * Tree is merely a random word to distinguish from Rhino and LevelCache.
 */

import std.algorithm;
import std.conv;
import std.format;
import std.range;

import optional;

import file.filename;
import file.ls;
import file.nextlev.interf;
import file.nextlev.tree.db;
import file.nextlev.tree.leaf;
import file.trophy;

class TreeDirRhino : Rhino, TreeRhino {
private:
    Filename _fn;
    Optional!TreeRhino _parent; // present unless it's the root
    TreeRhino[] _sortedChildren;

package:
    this(Optional!TreeRhino aParent, Filename fn)
    {
        _parent = aParent;
        _fn = fn;
    }

public:
    int numCompletedAfterRecaching()
    {
        return _sortedChildren.map!(r => r.numCompletedAfterRecaching).sum;
    }

    const pure nothrow @safe @nogc {
        Filename filename() { return _fn; }
        int weight() { return _sortedChildren.map!(r => r.weight).sum; }
        TrophyKey trophyKey() { return TrophyKey("", "", ""); }
        Optional!Trophy trophy() { return no!Trophy; }
    }

    Optional!TreeRhino parent()
    {
        return _parent;
    }

    Optional!Rhino rhinoOfWithinThisOrChildren(Filename argFn)
    {
        if (_fn == argFn) {
            return Optional!Rhino(this);
        }
        foreach (child; _sortedChildren) {
            if (argFn.rootless.startsWith(child.filename.rootless)) {
                return child.rhinoOfWithinThisOrChildren(argFn);
            }
        }
        return no!Rhino;
    }

    void recacheThisAndAncestors()
    {
        recacheOnlyThis();
        foreach (p; _parent) {
            p.recacheThisAndAncestors();
        }
    }

    void recacheThisAndDescendants()
    {
        recacheOnlyThis();
        foreach (child; _sortedChildren) {
            child.recacheThisAndDescendants();
        }
    }

    Optional!Rhino nextLevel()
    {
        if (_sortedChildren.length) {
            return _sortedChildren[0].firstLeafInside.toOptionalRhino;
        }
        // Replacing .oc. with empty/front here. See the closed github #452.
        return _parent.empty ? Optional!Rhino()
            : _parent.front.nextLevelAfter(this).toOptionalRhino;
    }

    Optional!TreeRhino nextLevelAfter(in TreeRhino afterThis)
    {
        auto tail = _sortedChildren.find(afterThis);
        if (tail.length >= 2) {
            return tail[1].firstLeafInside;
        }
        // Replacing .oc. with empty/front here. See the closed github #452.
        return _parent.empty ? Optional!TreeRhino()
            : _parent.front.nextLevelAfter(this);
    }

    Optional!TreeRhino firstLeafInside()
    {
        if (_sortedChildren.length) {
            return _sortedChildren[0].firstLeafInside;
        }
        return no!TreeRhino;
    }

private:
    void recacheOnlyThis()
    {
        /*
         * Algorithm: Reuse what we already have, to avoid needless recaching
         * in the children. Still ensure that, at the end of recacheOnlyThis(),
         * _sortedChildren is the same as if we were constructed from scratch.
         *
         * Thus: Keep existing children if they still have their level/dir.
         * In this case, don't recache them; if caller wants such recaching,
         * caller invoked recacheOnlyThis() via recacheThisAndDescendants().
         * When an existing child doesn't have a level/dir anymore, remove
         * the child. Create new children for newly found levels/dirs that
         * aren't yet in the oldChildren.
         */
        TreeRhino[] oldChildren = _sortedChildren;
        _sortedChildren = [];

        auto ls = new OrderFileLs();
        ls.currentDir = _fn;
        foreach (subdir; ls.dirs) {
            _sortedChildren ~= oldChildren.find!(o => o.filename == subdir)
                .frontOr(new TreeDirRhino(Optional!TreeRhino(this), subdir));
        }
        foreach (subfile; ls.files) {
            _sortedChildren ~= oldChildren.find!(o => o.filename == subfile)
                .frontOr(new TreeLeafRhino(this, subfile));
        }
    }

    Exception ourException(Filename argFn)
    {
        return new Exception(
            "Can't find " ~ argFn.rootless ~ " in any children."
            ~ " We are " ~ _fn.rootless
            ~ " with " ~ _sortedChildren.length.to!string ~ " children.");
    }
}
