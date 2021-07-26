module file.nextlev.tree.leaf;

/*
 * TreeRhino, TreeLevelCache:
 * Tree is merely a random word to distinguish from Rhino and LevelCache.
 */

import std.algorithm;

import optional;

import file.filename;
import file.log;
import file.trophy;
import file.nextlev.interf;
import file.nextlev.tree.db;
import file.trophy;
import level.metadata;

class TreeLeafRhino : Rhino, TreeRhino {
private:
    Filename _fn;
    TreeRhino _parent;
    TrophyKey _trophyKey;
    bool _solved;
    bool _solvedAndKeyAreProperlyCached = false;

package:
    this(TreeRhino aParent, Filename fn)
    {
        _parent = aParent;
        _fn = fn;
    }

public:
    int numCompletedAfterRecaching()
    {
        ensureThatThisIsProperlyCached();
        return _solved;
    }

    TrophyKey trophyKey()
    {
        ensureThatThisIsProperlyCached();
        return _trophyKey;
    }

    const pure nothrow @safe @nogc {
        Filename filename() { return _fn; }
        int weight() { return 1; }
    }

    Optional!TreeRhino parent()
    {
        return some(_parent);
    }

    Optional!Rhino rhinoOfWithinThisOrChildren(Filename argFn)
    {
        return _fn == argFn ? some!Rhino(this) : no!Rhino;
    }

    void recacheThisAndAncestors()
    {
        _solvedAndKeyAreProperlyCached = false;
        _parent.recacheThisAndAncestors();
    }

    void recacheThisAndDescendants()
    {
        _solvedAndKeyAreProperlyCached = false;
    }

    Optional!Trophy trophy()
    {
        return file.trophy.getTrophy(trophyKey());
    }

    Optional!Rhino nextLevel()
    {
        return _parent.nextLevelAfter(this).toOptionalRhino;
    }

    Optional!TreeRhino nextLevelAfter(in TreeRhino afterThis)
    {
        return _parent.nextLevelAfter(this);
    }

    Optional!TreeRhino firstLeafInside()
    {
        return some!TreeRhino(this);
    }

private:
    void ensureThatThisIsProperlyCached()
    {
        if (_solvedAndKeyAreProperlyCached) {
            return;
        }
        try {
            const lm = new LevelMetaData(_fn);
            _trophyKey = TrophyKey(_fn.fileNoExtNoPre,
                lm.nameEnglish, lm.author);
            _solvedAndKeyAreProperlyCached = true;

            _solved = trophy().map!(
                tro => tro.built == lm.built && tro.lixSaved >= lm.required)
                .frontOr(false);
        }
        catch (Exception e) {
            logf("recacheOnlyThis(_fn = %s):", _fn.rootless);
            logf("    -> %s", e.msg);
            log( "    -> Asking parent to recache. That should remove us.");
            _parent.recacheThisAndAncestors();
        }
    }
}

