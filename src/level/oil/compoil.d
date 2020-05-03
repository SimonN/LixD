module level.oil.compoil;

import basics.help;
import level.level;

///////////////////////////////////////////////////////////////////////////////
package: ///////////////////////////////////////////////////////////// :package
///////////////////////////////////////////////////////////////////////////////

abstract class ComparableBase {
public:
    final override bool opEquals(Object o) @safe pure nothrow @nogc
    {
        const rhs = cast (const ComparableBase) o;
        if (rhs is null)
            return false;
        return lexOrd == rhs.lexOrd;
    }

    final override int opCmp(Object o) const @safe pure nothrow @nogc
    {
        const rhs = cast (const ComparableBase) o;
        if (rhs is null)
            return 0;
        int[2] ours = lexOrd;
        int[2] theirs = rhs.lexOrd;
        return ours[0] - theirs[0] != 0
            ? ours[0] - theirs[0]
            : ours[1] - theirs[1];
    }

protected:
    abstract @property int[2] lexOrd() const @safe pure nothrow @nogc;
}

void arrInsert(T)(
    ref T[] arr, // insert into this array, mutating it, ...
    in int id, // ...before this position, may be arr.len to insert at end...
    T occToInsert // ...this element
) {
    assert (id >= 0, "Oil: can't insert before beginning of " ~ T.stringof);
    assert (id <= arr.len, "Oil: can't insert past end of " ~ T.stringof);
    arr = arr[0 .. id] ~ occToInsert ~ arr[id .. $];
}

void arrRemove(T)(
    ref T[] arr, // remove from this array, mutating it, ...
    in int id  // ...the element at this index
) {
    assert (id >= 0, "Oil: can't remove with negative index in " ~ T.stringof);
    assert (id < arr.len, "Oil: can't remove from end of " ~ T.stringof);
    arr = arr[0 .. id] ~ arr[id + 1 .. $];
}

void arrZOrderUntil(T)(
    ref T[] arr, // swap within this array, mutating it, ...
    in int idA, // ...the element at this position...
    in int idB, // ...with the element at this position. No allocation.
) @nogc
{
    assert (idA >= 0, "Oil: can't swap (idA < 0) in " ~ T.stringof);
    assert (idB >= 0, "Oil: can't swap (idB < 0) in " ~ T.stringof);
    assert (idA < arr.len, "Oil: can't swap (idA >= len) in " ~ T.stringof);
    assert (idB < arr.len, "Oil: can't swap (idB >= len) in " ~ T.stringof);

    immutable int step = idA < idB ? 1 : -1;
    T temp = arr[idA];
    for (int curA = idA; curA != idB; curA += step) {
        arr[curA] = arr[curA + step];
    }
    arr[idB] = temp;
}
