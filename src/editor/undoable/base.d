module editor.undoable.base;

import level.level;
import level.oil;

/*
 * Undoables should be treated like a Java immutable.
 *
 * apply(Level l) and undo(Level l) apply/undo the changes (that the Undoable
 * remembers itself) to the Level l. The level is passed externally into
 * the Undoable to allow the Undoable (and by D's language rules, all of its
 * information) to be const/immutable.
 *
 * The return value of selectionAfter*() is the suggested tile selection
 * for an editor after the apply() or undo() has completed.
 * The returned OilSet may be empty, then the editor shall deselect everything.
 * selectionAfter*() must return the correct OilSets even if no apply()/undo()
 * has ever been called.
 */
interface Undoable {
public:
    void apply(Level) const;
    void undo(Level) const;

    immutable(OilSet) selectionAfterApply() const pure nothrow @safe @nogc;
    immutable(OilSet) selectionAfterUndo() const pure nothrow @safe @nogc;
}

// Generic assertion message while undo isn't completely implemented
enum string inconsistentHistory
    = "Inconsistent history, can't apply/undo this."
    ~ " Undo isn't fully implemented.";
