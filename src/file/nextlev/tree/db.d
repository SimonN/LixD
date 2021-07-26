module file.nextlev.tree.db;

/*
 * TreeRhino, TreeLevelCache:
 * Tree is merely a random word to distinguish from Rhino and LevelCache.
 */

import std.algorithm;

static import basics.globals;

import optional;

import file.filename;
import file.nextlev.interf;
import file.nextlev.tree.dir;

interface TreeRhino : Rhino {
    Optional!TreeRhino parent();

    /*
     * Implements the tree search for the database's rhinoOf.
     * Is only responsible for looking through the current node and children,
     * never calls this on a parent. Returns Optional!Rhino because that's
     * the type that rhinoOf expects, even though we really know it's an
     * Optional!TreeRhino. There is no functorial covariance here, sadly.
     */
    Optional!Rhino rhinoOfWithinThisOrChildren(Filename);

    /*
     * Rhino.nextLevel is the entrance to finding the next level.
     * TreeRhino.nextLevelAfter(x) forwards the request through the tree
     * and passes as x the TreeRhino on which nextLevel was originally called
     * (if it's the first time of forwarding) or the previous forwarder.
     *
     * A chain of calls to firstLeafInside finishes the chain of calls to
     * nextLevelAfter. Calling firstLeafInside means that we already
     * progressed from a level to the next in one of the earlier callers.
     * This is merely to return the leaf inside the newly-chosen directory
     * after stepping to a next dir. If firstInside is called on a leaf,
     * the return is that same leaf.
     */
    Optional!TreeRhino nextLevelAfter(in TreeRhino);
    Optional!TreeRhino firstLeafInside();
}

// Conversion to supertype. Sadly, this isn't implicit.
Optional!Rhino toOptionalRhino(Optional!TreeRhino x)
{
    return x.map!((Rhino y) { return some(y); }).frontOr(no!Rhino);
}

class TreeLevelCache : LevelCache {
private:
    TreeDirRhino _root;

public:
    this()
    {
        this(basics.globals.dirLevelsSingle);
    }

    this(Filename rootForTheCounting)
    {
        _root = new TreeDirRhino(no!TreeRhino, rootForTheCounting);
        _root.recacheThisAndDescendants();
    }

    Optional!Rhino rhinoOf(Filename fn)
    {
        return _root.rhinoOfWithinThisOrChildren(fn);
    }
}
