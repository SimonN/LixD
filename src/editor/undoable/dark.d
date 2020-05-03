module editor.undoable.dark;

/*
 * ToggleDark: Captures darkening of a single TerOcc.
 *
 * Please filter the OilSet to ensure that only can.darken Occurrences
 * are in it. We will assert for that.
 */

import std.algorithm;

import editor.undoable.base;
import level.level;
import level.oil;
import tile.occur;
import tile.visitor;

class ToggleDark : Undoable {
private:
    immutable(OilSet) _oils; // contains exactly one Oil

public:
    this(
        immutable(OilSet) aOils
    )
    in { assert (! aOils[].empty); }
    body { _oils = aOils; }

    final override void undo(Level l) const { apply(l); }
    final override void apply(Level l) const
    {
        assert (occs(l).all!(occ => occ.can.darken));
        foreach (occ; occs(l)) {
            occ.dark = ! occ.dark;
        }
    }

    immutable(OilSet) selectionAfterApply() const pure nothrow @safe @nogc
    {
        return _oils;
    }

    immutable(OilSet) selectionAfterUndo() const pure nothrow @safe @nogc
    {
        return _oils;
    }

private:
    auto occs(Level l) const
    {
        return _oils[].map!(oil => oil.occ(l));
    }
}
