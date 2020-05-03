module editor.stack;

/*
 * In the editor, all modifications to the level shall go through UndoRedo.
 * This isn't enforced by the Undo classes, you must ensure this yourself.
 * A step towards this is that Editor._level is private, not package.
 */

import std.range;

import basics.help;
import level.level;
import level.oil;
import editor.undoable.base;

class UndoRedoStack {
private:
    Undoable[] _done; // most recently done has the highest index
    Undoable[] _undone; // most recently undone has the highest index

public:
    this() { }

    @property const pure nothrow @nogc {
        bool anythingToUndo() { return !_done.empty; }
        bool anythingToRedo() { return !_undone.empty; }
    }

    const(OilSet) apply(Level l, Undoable cmd)
    {
        _done ~= cmd;
        _undone = null;
        cmd.apply(l);
        return cmd.selectionAfterApply;
    }

    const(OilSet) undoOne(Level l)
    {
        if (_done.empty) {
            return emptyOilSet;
        }
        _undone ~= _done[$-1];
        _done = _done[0 .. $-1];
        _undone[$-1].undo(l);
        return _undone[$-1].selectionAfterUndo;
    }

    const(OilSet) redoOne(Level l)
    {
        if (_undone.empty) {
            return emptyOilSet;
        }
        _done ~= _undone[$-1];
        _undone = _undone[0 .. $-1];
        _done[$-1].apply(l);
        return _done[$-1].selectionAfterApply;
    }
}

import editor.undoable.move;

class UndoRedoStackThatMergesTileMoves {
private:
    UndoRedoStack _stack;

    // Tracks separately what sits on top of _done.
    // If there is no TileMove on top, then this is null.
    // If it points to something, we may extend that.
    TileMove _topOfDoneOrNull;

public:
    this() {
        _stack = new UndoRedoStack;
    }

    @property const pure nothrow @nogc {
        bool anythingToUndo() { return _stack.anythingToUndo; }
        bool anythingToRedo() { return _stack.anythingToRedo; }
    }

    const(OilSet) apply(Level l, Undoable cmd)
    {
        _topOfDoneOrNull = null;
        return _stack.apply(l, cmd);
    }

    const(OilSet) apply(Level l, TileMove tm)
    {
        if (_topOfDoneOrNull !is null
            && _topOfDoneOrNull.mayAdd(l.topology, tm)
        ) {
            _stack.undoOne(l); // we will replace that with the extended top
            _topOfDoneOrNull = _topOfDoneOrNull.add(l.topology, tm);
            return _stack.apply(l, _topOfDoneOrNull);
        }
        else {
            _topOfDoneOrNull = tm;
            return _stack.apply(l, tm);
        }
    }

    /*
     * Tells us that we shouldn't merge any more TileMoves into top of _done.
     */
    void stopCurrentMove()
    {
        _topOfDoneOrNull = null;
    }

    const(OilSet) undoOne(Level l)
    {
        _topOfDoneOrNull = null;
        return _stack.undoOne(l);
    }

    const(OilSet) redoOne(Level l)
    {
        _topOfDoneOrNull = null;
        return _stack.redoOne(l);
    }
}
