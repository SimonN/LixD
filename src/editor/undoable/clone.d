module editor.undoable.clone;

/*
 * CopyPaste : Undoable
 * Input: A nonempty OilSet.
 *
 * Clones the Occurrences, moves them according to rules coded here,
 * and inserts them into the level.
 *
 * If you pass an empty OilSet to clone, that's a bug in the caller; we assert.
 *
 * Distant future: If you decide to implement
 * editor.dragger.startRecordingCopyMove, you must handle this outside here.
 * CopyPaste doesn't know about the editor. CopyPaste is, at the moment,
 * smart enough to calculate awsbiamb, but that's only because that's a
 * property of the level, and 16, the biggest grid size, is universal enough
 * a nice-size constant in Lix to hardcode it here.
 */

import std.algorithm;
import std.range;

import editor.undoable.base;
import level.level;
import level.oil;
import tile.occur;
import tile.visitor;

class CopyPaste : Undoable {
private:
    immutable(OilSet) _source;
    immutable(OilSet) _cloned;
    immutable Point _moveEachClonedOccBy;

public:
    this(
        /*
         * Level: Only to create cloned oils, not occs, ahead of time.
         * Hack! Must be mutable because we insert occs, then delete them
         * again, into the edited level (!) merely to create occs that end
         * up completely independent from changes.
         * The honest inserting (for good) will happen much later in apply().
         */
        Level level,
        immutable(OilSet) aToClone,
        in Point idea // Suggestion for how much to move all cloned tiles
    )
    in { assert (aToClone.length > 0, contract); }
    do {
        _source = aToClone;
        _moveEachClonedOccBy
            = awsbimamb(level, idea) ? idea
            : awsbimamb(level, -idea) ? -idea : idea;

        _cloned = makeClonedOilsByCloningThenDeleting(level, _source);
    }

    override void apply(Level l) const
    {
        auto oilsAtEnd = _cloned[]; // _cloned is already populated
        foreach (oil; _source[]) {
            Occurrence clonedOcc = oil.occ(l).clone();
            clonedOcc.loc
                = l.topology.wrap(_moveEachClonedOccBy + clonedOcc.loc);

            // For each oil from _source[], we use one of oilsAtEnd.
            // The two ranges will thus exhaust at the same time.
            oilsAtEnd.front.insert(l, clonedOcc);
            oilsAtEnd.popFront;
        }
    }

    override void undo(Level l) const
    {
        removeFromLevel(l, _cloned);
    }

    immutable(OilSet) selectionAfterApply() const pure nothrow @safe @nogc
    {
        return _cloned;
    }

    immutable(OilSet) selectionAfterUndo() const pure nothrow @safe @nogc
    {
        return _source;
    }

private:
    enum contract = "CopyPaste demands nonempty OilSets";

    static immutable(OilSet) makeClonedOilsByCloningThenDeleting(
        Level l,
        in OilSet source,
    ) {
        OilSet ret = new OilSet;
        foreach (src; source[]) {
            Oil atEnd = Oil.makeAtEndOfList(l, src.occ(l).tile);
            atEnd.insert(l, src.occ(l).clone());
            ret.insert(atEnd);
        }
        removeFromLevel(l, ret);
        return ret.assumeUnique;
    }

    /*
     * awsbiamb, "All would still be inside map after moving by"
     *
     * This may be called while the CopyPaste object is only partially
     * constructed. We assume only an initialized _source, not any other
     * members.
     *
     * What this does:
     * Assuming we moved all _source tiles by (by), would all tiles still be
     * within the map boundaries? We even require that they're inside the map
     * by a considerable safety margin, not merely by a few pixels.
     */
    final bool awsbimamb(in Level level, in Point by) const
    {
        assert (_source.length > 0, contract);

        // Omit safety margin for torus directions since everything is inside.
        immutable int safetyX = level.topology.torusX ? 0 : 16 - 1;
        immutable int safetyY = level.topology.torusY ? 0 : 16 - 1;
        immutable Rect insideMap = Rect(Point(safetyX, safetyY),
            level.topology.xl - 2 * safetyX,
            level.topology.yl - 2 * safetyY);
        assert (insideMap.xl > 0 && insideMap.yl > 0, "safetyMargin too big");
        return _source[].map!(oil => oil.occ(level).selboxOnMap + by)
            .all!(rect => level.topology.rectIntersectsRect(insideMap, rect));
    }

    static removeFromLevel(
        Level l,
        in OilSet oilsToRemove
    ) {
        auto visitor = new class TileVisitor {
            void visit(const(TerrainTile) te)
            {
                popLast(l.terrain);
            }
            void visit(const(GadgetTile) ga)
            {
                popLast(l.gadgets[ga.type]);
            }
            void visit(const(TileGroup) gr)
            {
                popLast(l.terrain);
            }
        };
        foreach (oil; oilsToRemove[].retro) {
            oil.occ(l).tile.accept(visitor);
        }
    }

    static void popLast(Arr)(ref Arr arr) // arr will be modified
    {
        assert (arr.length > 0, "can't pop from empty " ~ Arr.stringof);
        arr = arr[0 .. $-1];
    }
}
