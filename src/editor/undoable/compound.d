module editor.undoable.compound;

import std.algorithm;
import std.format;
import std.range;

import editor.undoable.base;
import level.level;
import level.oil;

class CompoundUndoable : Undoable {
private:
    Undoable[] _components;
    immutable(OilSet) _selectionAfterApply;
    immutable(OilSet) _selectionAfterUndo;

public:
    this(Undoable[] aComponents)
    {
        _components = aComponents;

        immutable(OilSet) make(alias func)()
        {
            OilSet ret = new OilSet;
            foreach (cmd; _components) {
                ret = ret[].chain(func(cmd)[]).toOilSet;
            }
            return ret.assumeUnique;
        }
        _selectionAfterApply = make!(cmd => cmd.selectionAfterApply);
        _selectionAfterUndo = make!(cmd => cmd.selectionAfterUndo);
    }

    void apply(Level l) const
    {
        foreach (cmd; _components) {
            cmd.apply(l);
        }
    }

    void undo(Level l) const
    {
        foreach (cmd; _components.retro) {
            cmd.undo(l);
        }
    }

    immutable(OilSet) selectionAfterApply() const pure nothrow @safe @nogc
    {
        return _selectionAfterApply;
    }

    immutable(OilSet) selectionAfterUndo() const pure nothrow @safe @nogc
    {
        return _selectionAfterUndo;
    }
}

CompoundUndoable toCompoundUndoable(Undoable[] aComponents)
{
    return new CompoundUndoable(aComponents);
}

CompoundUndoable toCompoundUndoable(Range)(Range range)
    if (isInputRange!Range
    && ! is(Range == Undoable[])
    && is(ElementType!Range : Undoable)
) {
    Undoable[] ret;
    range.each!(e => ret ~= e);
    return new CompoundUndoable(ret);
}
