module editor.undoable.zorder;

/*
 * Assume this is a list of Occurrences A-F (e.g., all terrain) with ID 0 drawn
 * in the back and ID 5 drawn in front, after everything else.
 *
 *  0 1 2 3 4 5
 *  A B C D E F
 *
 * A ZOrdering undoable takes one of the Occurrences (say, B), removes it
 * form the list, then re-inserts it elsewhere (say, before ID 4). After
 * application, the list looks like this:
 *
 *  0 1 2 3 4 5
 *  A C D E B F
 *
 * It is a desired side effect that C, D, and E have shifted hinder by one.
 * by one. A ZOrdering can re-insert the element before or after its original
 * position. To z-order B hindmost, it would be taken from its ID 1 and
 * re-inserted at ID 0.
 */

import std.algorithm;
import std.conv;
import std.range;

import basics.help;
import editor.undoable.base;
import editor.undoable.compound;
import level.level;
import level.oil;
import tile.occur;
import tile.visitor;

/*
 * ZOrdering: This is a single change of a single tile.
 * The factory code for these is further down in this module.
 * The editor likely wants to call only those factory functions.
 */
class ZOrdering : Undoable {
private:
    immutable(OilSet) _source; // contains exactly one element
    immutable(OilSet) _destination; // contains exactly one element

public:
    this(
        const(Oil) aSource,
        const(Oil) aDestination
    ) {
        /*
         * In reality, we take the const(Oil) that may well be a mutable oil
         * behind the scenes, and stick it into the OilSet, relying on how
         * Oil is Java-immutable (doesn't offer methods that change its state).
         */
        _source = aSource.toOilSet.assumeUnique;
        _destination = aDestination.toOilSet.assumeUnique;
    }

    bool shouldBeAppliedBefore(in typeof(this) rhs) const pure nothrow @nogc
    {
        /*
         * If we order towards the hind end (beginning of list), the hinder
         * (earlier) Occurrence should move first, to not invalidate _sources.
         * Conversely, for ordering towards the front (end of list), the
         * fronter (later) Occurrence should move first, to not invalidate
         * sources.
         */
        if (destination.appearsBefore(source)) {
            return source.appearsBefore(rhs.source);
        }
        else if (source.appearsBefore(destination)) {
            return rhs.source.appearsBefore(source);
        }
        // rhs is this (important case) or awkward higher-level mistake
        return false;
    }

    final void apply(Level l) const { source.zOrderUntil(l, destination); }
    final void undo(Level l) const { destination.zOrderUntil(l, source); }

    @property const pure nothrow @safe @nogc {
        immutable(OilSet) selectionAfterApply() { return _destination; }
        immutable(OilSet) selectionAfterUndo() { return _source; }
        immutable(Oil) source() { return _source[].front; }
        immutable(Oil) destination() { return _destination[].front; }
    }
}

/*
 * Don't put this on the undo stack by itself. The intention is that
 * this can become a part of a CompoundUndoable with ZOrderings,
 * to not deselect the tiles that don't move, among others that move.
 */
private final class UndoableThatMerelySelectsTiles : Undoable {
private:
    immutable(OilSet) _selection;

public:
    this(immutable(OilSet) sel) { _selection = sel; }

    void apply(Level l) const {}
    void undo(Level l) const {}
    @property const pure nothrow @safe @nogc {
        immutable(OilSet) selectionAfterApply() { return _selection; }
        immutable(OilSet) selectionAfterUndo() { return _selection; }
    }
}

///////////////////////////////////////////////////////////////////////////////
// Factory function to create a compound undoable of ZOrderings ///////////////
///////////////////////////////////////////////////////////////////////////////

enum FgBg { fg, bg }

/*
 * Returns null if the ZOrdering compound would be trivial.
 */
Undoable zOrderingTowardsOrNull(
    Level level, // Must be mutable for the hack, see comments in this func.
    const(OilSet) tiles,
    in FgBg fgbg,
) {
    OilSet doNotReorderAmong = tiles.clone;
    OilSet unmovedOils = new OilSet;

    Undoable[] ret; // Loop will append the nontrivial Z-Orderings
    foreach (oil; choose(fgbg == FgBg.bg, tiles[], tiles[].retro)) {
        auto maker = new ZOrderingMaker(level, doNotReorderAmong, oil, fgbg);
        if (maker.resultOrNull is null) {
            unmovedOils.insertHack(oil);
            continue;
        }
        ret ~= maker.resultOrNull;
        doNotReorderAmong.removeHack(maker.resultOrNull.source);
        doNotReorderAmong.insertHack(maker.resultOrNull.destination);
        /*
         * Apply each ZOrdering before computing the next one.
         * Reason: Other ZOrderings must check for collision with each tile
         * during their tile list iteration.
         *
         * This is a hack: Ideally, we shouldn't change the level outside
         * applications of Undoables by the editor to the undo stack.
         * This is part 1 of the hack in this function.
         */
        maker.resultOrNull.apply(level);
    }
    /*
     * Unapply each ZOrdering, so the compound can be applied to the stack
     * by our caller. This is part 2 of the hack in this function.
     */
    ret.retro.each!(zOrdering => zOrdering.undo(level));

    if (ret.empty) {
        return null;
    }
    if (ret.len == 1 && unmovedOils[].empty) {
        return ret[0];
    }
    if (unmovedOils.length >= 1) {
        ret ~= new UndoableThatMerelySelectsTiles(unmovedOils.assumeUnique);
    }
    return ret.toCompoundUndoable;
}

/*
 * This class is merely a collection of function arguments that are passed
 * between its private methods, to prevent private methods having 7 parameters.
 * This class does all its useful work during construction.
 */
private final class ZOrderingMaker : TileVisitor {
private:
    const(Level) _level; // Needed to intersect two tiles
    const(Oil) _oil; // We move this...
    const FgBg _fgbg; // ...in this direction.

    /*
     * Typically, this contains all selected tiles.
     * We don't reorder the _oil past these. If _oil is a member of these,
     * that's okay, we can still reorder _oil itself. Only others matter here.
     */
    const(OilSet) _doNotZOrderAmong;

    // null until something was successfully reordered.
    // This doesn't necessarily happen on the first reordering.
    ZOrdering _candidateOrNull = null;

public:
    this(
        const(Level) lev,
        const(OilSet) doNotZOrderAmong,
        const(Oil) o,
        in FgBg afgbg,
    ) {
        _level = lev;
        _oil = o;
        _fgbg = afgbg;
        _doNotZOrderAmong = doNotZOrderAmong;
        _oil.occ(_level).tile.accept(this);
    }

    @property inout(ZOrdering) resultOrNull() inout pure nothrow @safe @nogc
    {
        return _candidateOrNull;
    }

protected:
    override void visit(const(TerrainTile) te) {
        _candidateOrNull = makeZOrderingOrNull!TerOcc(
            _level.terrain, MoveTowards.untilIntersects);
    }

    override void visit(const(GadgetTile) ga) {
        _candidateOrNull = makeZOrderingOrNull!GadOcc(
            _level.gadgets[ga.type],
            ga.type == GadType.hatch || ga.type == GadType.goal
            ? MoveTowards.once : MoveTowards.untilIntersects);
    }

    override void visit(const(TileGroup) gr) {
        visit(cast(const(TerrainTile)) gr);
    }

private:
    enum MoveTowards { once, untilIntersects }

    // ignoreThese means _doNotZOrderPastThese.
    // ignoreThese: Editor will pass selection. We shall not reorder among the
    // selection. Never reorder the current piece with any from ignoreThese.
    // The editor must take responsibility to call this function in correct order:
    // Correct order ensures that we can break while (adj() >= 0 ...) when we have
    // run into a piece from ignoreThese. This means that the editor must call
    // zOrdering for moving to bg on the regularly-ordered list (bg at front,
    // fg at back), and call zOrdering for moving to fg on the retro list!
    private ZOrdering makeZOrderingOrNull(P)(
        in P[] list,
        in MoveTowards mt
    )   if (is (P : Occurrence) && !is(P == Occurrence))
    {
        const(Occurrence) occOf(in Oil oil)
        {
            return oil.occ(_level);
        }
        int newPos = list.countUntil!"a is b"(occOf(_oil)).to!int;
        assert (newPos >= 0, "_occ must be in list[]");

        int adj()
        {
            return (_fgbg == FgBg.fg) ? newPos + 1 : newPos - 1;
        }
        /+
         + Dieses ganze Zeug muss ins Undoable.
         + Und da dann eben direkten Listenzugriff, den scheint man eh zu
         + brauchen.
         +/
        while (adj() >= 0
            && adj() < list.len
            && ! _doNotZOrderAmong[].map!occOf.canFind!"a is b"(list[adj()])
        ) {
            newPos = adj();
            if (mt == MoveTowards.once
                || _level.topology.rectIntersectsRect(
                occOf(_oil).selboxOnMap, list[newPos].selboxOnMap)
            ) {
                return new ZOrdering(_oil,
                    Oil.makeViaLookup(_level, list[newPos]));
            }
        }
        return null;
    }
}

