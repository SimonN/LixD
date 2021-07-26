module file.nextlev.interf;

/*
 * Rhino: A node in the level database. Can be a leaf (level) or can point
 * to more nodes.
 *
 * For a level:
 *      weight = 1
 *      numCompleted = 0 or 1. It's 1 if the level solved, 0 otherwise
 *
 * For a directory:
 *      weight = sum of weights of the directory's contents
 *      numCompleted = sum of numCompleted of its contents
 */

import optional;
import file.filename;
import file.trophy;

interface LevelCache {
    // returns none if file 404 under this's root dir, e.g., "levels/single/"
    Optional!Rhino rhinoOf(Filename);
}

interface Rhino {
    /*
     * int numCompleted():
     * TrophyKey trophyKey();
     * Ideally, these are also const pure nothrow @safe @nogc.
     * But it's a speed hack to only sparsely read the weight even in a
     * cached database. This introduces a lie: The "cached database"
     * is zwar Ls'd with all Nodes created (we have opened all dirs),
     * but the nodes haven't yet opened the level files to read the metadata.
     */
    int numCompletedAfterRecaching();
    TrophyKey trophyKey(); // holds mostly empty strings if Rhino is dir

    const pure nothrow @safe @nogc {
        Filename filename();
        int weight();
    }
    void recacheThisAndAncestors();
    void recacheThisAndDescendants();

    Optional!Trophy trophy(); // returns no!Trophy if the Rhino is for a dir
    Optional!Rhino nextLevel();
}
