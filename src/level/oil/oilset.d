module level.oil.oilset;

/*
 * OilSet is a set of Oil, i.e., a set of Occurrences in levels.
 *                                        ^           ^  ^
 * Unlike an array of Oil, OilSet guarantees that it is always sorted.
 * The editor's selection set and the editor's hovering set can be OilSets.
 */

import std.container;
import std.range : only;

import level.oil;

alias OilSet = RedBlackTree!(Oil, "a.appearsBefore(b)",
    false // refuse duplicates
);

immutable OilSet emptyOilSet = new OilSet();

OilSet clone(const(OilSet) other) { return other[].toOilSet; }

void removeHack(OilSet set, const(Oil) oil)
{
    // See comment in insertHack
    set.removeKey(cast (Oil) oil);
}

void insertHack(OilSet set, const(Oil) oil)
{
    // Hack around language problem! Tree!(immutable Oil) broken!
    // core.?.hash.toHash isn't @trusted for immutable(Oil).
    set.insert(cast (Oil) oil);
}

OilSet toOilSet(const(Oil) oil)
{
    OilSet ret = new OilSet;
    ret.insertHack(oil);
    return ret;
}

OilSet toOilSet(Range)(Range range)
{
    OilSet ret = new OilSet;
    foreach (e; range) {
        ret.insertHack(e);
    }
    return ret;
}

immutable(OilSet) assumeUnique(OilSet aSet)
{
    return cast (immutable(OilSet)) aSet;
}

unittest {
    Oil x = new TerOil(1);
    Oil y = new TerOil(3);
    Oil z = new TerOil(3);
    assert (x !is y && y !is z && z !is y);
    assert (y == z);

    // OilSet shall refuse another equal non-very-same element
    {
        OilSet set = new OilSet(x, y, z);
        assert (set.length == 2); // we refuse equals even if y !is z

        OilSet b = new OilSet;
        while (! set.empty) {
            b.insert(set.removeAny);
        }
        assert (set.empty);
        assert (b.front == x || b.front == z);
    }

    // Oilsets shall be equal if they have equal non-very-same elements
    {
        OilSet a = new OilSet(x, y);
        OilSet b = new OilSet(z, x);
        assert (a == b);
        assert (a.front == b.front);
    }
}
