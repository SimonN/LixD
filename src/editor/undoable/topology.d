module editor.undoable.topology;

import basics.topology;
import editor.undoable.base;
import graphic.color;
import level.level;
import level.oil;

/*
 * This isn't concerned with tile moves.
 * If you change the topology by cutting the level from the left, you want
 * all tiles to move leftwards, but TopologyChange isn't concerned with tile
 * moves. Tiles must be moved elsehow, likely in a CompoundUndoable with
 * TopologyChange and some TileMoves.
 */
class TopologyChange : Undoable {
private:
    immutable(typeof(this).State) _before;
    immutable(typeof(this).State) _after;

public:
    struct State {
        immutable(Topology) topology;
        Alcol bgColor;
    }

    this(State aBefore, State aAfter)
    {
        _before = aBefore;
        _after = aAfter;
    }

    final override void apply(Level l) const
    {
        assertConsistency(l, _before);
        doApply(l, _after);
    }

    final override void undo(Level l) const
    {
        assertConsistency(l, _after);
        doApply(l, _before);
    }

    immutable(OilSet) selectionAfterApply() const pure nothrow @safe @nogc
    {
        return emptyOilSet;
    }

    immutable(OilSet) selectionAfterUndo() const pure nothrow @safe @nogc
    {
        return emptyOilSet;
    }

private:
    void doApply(Level l, in State toWhat) const
    {
        with (toWhat.topology) {
            l.topology.resize(xl, yl);
            l.topology.setTorusXY(torusX, torusY);
        }
        l.bgColor = toWhat.bgColor;
    }

    version (assert) {
        import std.format;
        static string printTopology(in Topology top)
        {
            return format!"Toplogy(xl=%d, yl=%d, tx=%d, ty=%d)"(
                top.xl, top.yl, top.torusX, top.torusY);
        }

        static string printColor(in Alcol col)
        {
            ubyte r, g, b;
            al_unmap_rgb(col, &r, &g, &b);
            return format!"Color(r=%d, g=%d, b=%d)"(r, g, b);
        }

        static void assertConsistency(in Level l, in State old)
        {
            assert (l.topology.matches(old.topology),
                "Wrong topology for apply/undo,"
                ~ " level has " ~ printTopology(l.topology)
                ~ ", expected is " ~ printTopology(old.topology));
            assert (l.bgColor == old.bgColor,
                "Wrong bg color before apply/undo,"
                ~ " level has " ~ printColor(l.bgColor)
                ~ ", expected is " ~ printColor(old.bgColor));
        }
    }
    else {
        static void assertConsistency(in Level, in State) { }
    }
}

/*
 * Like TileMove, but will hard-ignore the wrapping.
 * The normal tile-moving Undoable wraps, this is necessary because we want
 * to easily group moving multiple tiles, only some of which are dragged past
 * a torus seam. The coordinate-fixing must ignore the wrap; it will carry raw
 * coordinates.
 */
class CoordinateFix : Undoable {
private:
    immutable(Oil) _toMove;
    immutable Point _source; // wrapped according to the earlier topology
    immutable Point _destination; // wrapped according to the later topology

public:
    /*
     * Requirement that we can't assert here, but you must follow:
     * The first Oil's _source and _destination must be nicely wrapped
     * according to the level's topology; _source according to the earlier
     * topology, _destination according to the later topology.
     */
    this(immutable(Oil) aOil, in Point aSource, in Point aDestination)
    in {
        assert (aOil !is null, "CoordinateFix must involve exactly 1 tile");
    }
    body {
        _toMove = aOil;
        _source = aSource;
        _destination = aDestination;
    }

    final override void apply(Level l) const
    {
        assert (_toMove.occ(l).loc == _source, "CoordFix _source mismatch");
        _toMove.occ(l).loc = _destination;
    }

    final override void undo(Level l) const
    {
        assert (_toMove.occ(l).loc == _destination, "CoordFix _dest mismatch");
        _toMove.occ(l).loc = _source;
    }

    immutable(OilSet) selectionAfterApply() const pure nothrow @safe @nogc
    {
        return emptyOilSet;
    }

    immutable(OilSet) selectionAfterUndo() const pure nothrow @safe @nogc
    {
        return emptyOilSet;
    }
}
