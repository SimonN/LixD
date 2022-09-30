module editor.undoable.move;

import std.algorithm;
import std.range;

import basics.rect;
import basics.topology;
import editor.undoable.base;
import level.level;
import tile.gadtile;
import tile.occur;
import level.oil;

class TileMove : Undoable {
private:
    immutable(OilSet) _toMove; // guaranteed to have at least one element
    immutable Point _source; // of first Oil in _toMove, already wrapped
    immutable Point _destination; // of first Oil in _toMove, already wrapped

public:
    /*
     * Requirement that we can't assert here, but you must follow:
     * The first Oil's _source and _destination must be nicely wrapped
     * according to the level's topology.
     */
    this(immutable(OilSet) aSet, in Point aSource, in Point aDestination)
    in {
        assert (! aSet[].empty, "Moves must involve at least one tile");
    }
    do {
        _toMove = aSet;
        _source = aSource;
        _destination = aDestination;
    }

    final override void apply(Level l) const
    {
        version (assert) {
            import std.conv : text;
            assert (_toMove[].front.occ(l).loc == _source, text(
                "Apply: Expected [0].loc == source of ", _source,
                " to then move it to destination ", _destination,
                ", but found [0].loc == ", _toMove[].front.occ(l).loc,
                ". The first element must match without Topology.wrap!"));
        }
        foreach (oil; _toMove) {
            oil.occ(l).loc
                = l.topology.wrap(oil.occ(l).loc + _destination - _source);
        }
    }

    final override void undo(Level l) const
    {
        version (assert) {
            import std.conv : text;
            assert (_toMove[].front.occ(l).loc == _destination, text(
                "Undo: Expecetd occ.loc == destination of ", _destination,
                " to then move it to source ", _source,
                ", but found occ.loc == ", _toMove[].front.occ(l).loc,
                ". The first element must match without Topology.wrap!"));
        }
        foreach (oil; _toMove) {
            oil.occ(l).loc
                = l.topology.wrap(oil.occ(l).loc + _source - _destination);
        }
    }

    immutable(OilSet) selectionAfterApply() const pure nothrow @safe @nogc
    {
        return _toMove;
    }

    immutable(OilSet) selectionAfterUndo() const pure nothrow @safe @nogc
    {
        return _toMove;
    }

    /*
     * Does not modify (this), instead GC-allocates a new TileMove that is the
     * result of the addition of (this) with (other).
     */
    TileMove add(in Topology top, TileMove other)
    in {
        assert (mayAdd(top, other), "Bad addition of two TileMoves");
    }
    do {
        if (mayAddAsParallelMoveOfMoreTiles(top, other)) {
            return addAsParallelMoveOfMoreTiles(top, other);
        }
        else {
            return addAsExtraDistanceOfSameTiles(top, other);
        }
    }

    bool mayAdd(in Topology top, in TileMove other) const
    {
        return mayAddAsParallelMoveOfMoreTiles(top, other)
            || mayAddAsExtraDistanceOfSameTiles(top, other);
    }

private:
    bool mayAddAsParallelMoveOfMoreTiles(
        in Topology top, in TileMove other) const
    {
        return top.wrap(_destination - _source)
            == top.wrap(other._destination - other._source)
            && ! other._toMove[].canFind!"a == b"(_toMove[].front);
    }

    bool mayAddAsExtraDistanceOfSameTiles(
        in Topology top, in TileMove other) const
    {
        /*
         * Wrapping could be omitted here because _source and _destination
         * are required to be wrapped, and we don't subtract or otherwise
         * compute anything here before wrapping.
         */
        return _toMove == other._toMove
            && top.wrap(_destination) == top.wrap(other._source);
    }

    TileMove addAsParallelMoveOfMoreTiles(in Topology top, TileMove other)
    in {
        assert (mayAddAsParallelMoveOfMoreTiles(top, other));
    }
    do {
        auto merged = _toMove[].chain(other._toMove[]).toOilSet.assumeUnique;
        /*
         * The smallest Oil in this's OilSet, which is associated with
         * _source and _destination, will not necessarily be the
         * smallest Oil in the merged OilSet. Adapt to the newest smallest.
         */
        if (_toMove[].front.appearsBefore(other._toMove[].front)) {
            assert (merged[].front == _toMove[].front,
                "Weird ordering, this shouldn't happen");
            return new TileMove(merged, _source, _destination);
        }
        else {
            assert (merged[].front == other._toMove[].front,
                "Weird ordering, shouldn't happen either");
            return new TileMove(merged, other._source, other._destination);
        }
    }

    TileMove addAsExtraDistanceOfSameTiles(
        in Topology top, in TileMove other)
    in {
        assert (mayAddAsExtraDistanceOfSameTiles(top, other));
    }
    do {
        return new TileMove(_toMove, _source, other._destination);
    }
}
