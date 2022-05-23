module editor.undoable.addrm;

import editor.undoable.base;
import level.level;
import tile.occur;
import level.oil;

/*
 * Insert before the given Oil. That Oil would then point to the new element.
 * Everything that was >= that Oil is now > that Oil.
 * May insert at end of list using the Oil that points to the end.
 */
class TileInsertion : TileAdditionOrRemoval, Undoable {
public:
    this(
        Oil aOil,
        const(Occurrence) aOccToAdd
        /*
         * There is a subtle design oddity here: We take aOccToAdd, but don't
         * require our caller to make a deep copy only for us to bunker.
         * This happens to be fine in practice: Our caller will apply us
         * anyway, thus either
         *  -> removing the source occ, or
         *  -> adding an Occurrence that wasn't in the level anyway.
         */
    ) {
        super(aOil, aOccToAdd);
    }

    bool shouldBeAppliedBefore(in typeof(this) rhs) const pure nothrow @nogc
    {
        return oil.appearsBefore(rhs.oil);
    }

    final void apply(Level l) const { addTheOcc(l); }
    final void undo(Level l) const { removeTheOcc(l); }

    immutable(OilSet) selectionAfterApply() const pure nothrow @safe @nogc
    {
        return selectionAfterAdding();
    }

    immutable(OilSet) selectionAfterUndo() const pure nothrow @safe @nogc
    {
        return emptyOilSet;
    }
}

class TileRemoval : TileAdditionOrRemoval, Undoable {
public:
    this(Oil aOil, const(Occurrence) aOccToAddInCaseOfUndo
    ) {
        super(aOil, aOccToAddInCaseOfUndo);
    }

    /*
     * Deleting via an Oil points will invalidate all Oils with larger indices.
     * Thus, delete largest Oils first.
     * (CompoundUndoables are applied from front to back,
     * undone from back to front.)
     */
    bool shouldBeAppliedBefore(in typeof(this) rhs) const pure nothrow @nogc
    {
        return rhs.oil.appearsBefore(oil);
    }

    final void apply(Level l) const { removeTheOcc(l); }
    final void undo(Level l) const { addTheOcc(l); }

    immutable(OilSet) selectionAfterApply() const pure nothrow @safe @nogc
    {
        return emptyOilSet;
    }

    immutable(OilSet) selectionAfterUndo() const pure nothrow @safe @nogc
    {
        return selectionAfterAdding();
    }
}

abstract class TileAdditionOrRemoval : Undoable {
private:
    immutable(OilSet) _theSingleOil; // contains exactly one element
    const(Occurrence) _toAdd;

public:
    this(Oil aOil, const(Occurrence) aOccToAdd)
    {
        _theSingleOil = aOil.toOilSet.assumeUnique;
        _toAdd = aOccToAdd;
    }

protected:
    final immutable(Oil) oil() const pure nothrow @safe @nogc
    {
        return _theSingleOil[].front;
    }

    final void addTheOcc(Level l) const
    {
        _theSingleOil[].front.insert(l, _toAdd.clone);
    }

    final void removeTheOcc(Level l) const
    {
        version (assert) {
            import std.conv : text;
            assert (oil.occ(l) == _toAdd, text(
                "removeTheOcc: Expected ", _toAdd, " to then remove it,",
                " but instead found ", oil.occ(l), ". Inconsistent history.",
                " These occs should match without Topology.wrap."));
        }
        oil.remove(l);
    }

    immutable(OilSet) selectionAfterAdding() const pure nothrow @safe @nogc
    {
        return _theSingleOil;
    }
}
