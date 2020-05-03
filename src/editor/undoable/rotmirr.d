module editor.undoable.rotmirr;

/*
 * TileRotation: Captures rotation/mirroring/darkening of a single Occurrence.
 * This also remembers how the tile moves.
 *
 * It's still much different from TileMove because two TileMoves can combine
 * to move several Occurrences. TileRotation is always about exactly one Occ.
 */

import std.range;

import basics.rect;
import editor.undoable.base;
import level.level;
import tile.gadtile;
import tile.occur;
import level.oil;

class TileRotation : Undoable {
private:
    immutable(OilSet) _theSingleOil; // contains exactly one Oil
    immutable(Occurrence) _before;
    immutable(Occurrence) _after;

public:
    this(
        Oil aOil,
        immutable(Occurrence) aBefore,
        immutable(Occurrence) aAfter
    ) {
        _theSingleOil = aOil.toOilSet.assumeUnique;
        _before = aBefore;
        _after = aAfter;
    }

    final override void apply(Level l) const
    {
        assertConsistency(oil.occ(l), _before);
        oil.remove(l);
        oil.insert(l, _after.clone);
    }

    final override void undo(Level l) const
    {
        assertConsistency(oil.occ(l), _after);
        oil.remove(l);
        oil.insert(l, _before.clone);
    }

    immutable(OilSet) selectionAfterApply() const pure nothrow @safe @nogc
    {
        return _theSingleOil;
    }

    immutable(OilSet) selectionAfterUndo() const pure nothrow @safe @nogc
    {
        return _theSingleOil;
    }

private:
    immutable(Oil) oil() const pure nothrow @safe @nogc
    {
        return _theSingleOil[].front;
    }

    version (assert) {
        void assertConsistency(in Occurrence a, in Occurrence b) const
        {
            assert (a == b);
        }
    }
    else {
        void assertConsistency(in Occurrence a, in Occurrence b) const { }
    }
}
