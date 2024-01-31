module editor.group;

import std.algorithm;
import std.conv;
import std.range;

import basics.help;
import editor.editor;
import editor.undoable.addrm;
import editor.undoable.compound;
import level.level;
import level.oil;
import tile.group;
import tile.occur;
import tile.tilelib;
import tile.visitor;

void createGroup(Editor editor) {
    with (editor)
{
    // Choose only the terrain occurrences. _selection may gadget Oils,
    // those gadgets shall not become part of the new group.
    // I would like to remove the dynamic cast, but this code is clearest.
    auto occurrences = editor._selection[]
        .map!(oil => cast (TerOil) oil)
        .filter!(oil => oil !is null)
        .map!(oil => oil.occ(levelRefacme));
    static assert (is (ElementType!(typeof(occurrences)) == TerOcc),
        "As of 2020-11, we need mutable TerOccs for this algo");

    assert (occurrences.all!(occ => occ !is null && occ.tile !is null));
    if (   occurrences.walkLength < 2
        || occurrences.all!(occ => occ.dark))
        return;

    TileGroup group;
    TerOcc groupOcc;
    try {
        editor.minimizeSelectionSelboxByMovingSomeAcrossTorus(occurrences);
        /*
         * Now the torus invariant (coordinates must be in [0, L[ and never
         * < 0 or >= L) is violated until we restore it in the 'finally'.
         * We need the violation during group creation and smallestContainer.
         */
        group = getGroup(TileGroupKey(occurrences)); // Or InvisibleException.
        groupOcc = new TerOcc(group);
        groupOcc.loc = occurrences
            .map!(occ => occ.cutbitOnMap)
            .reduce!(Rect.smallestContainer)
            .topLeft + group.transpCutOff;
        groupOcc.loc = editor.level.topology.wrap(groupOcc.loc);
    }
    catch (TileGroup.InvisibleException) {
        return;
    }
    finally {
        // Restore the torus invariant.
        foreach (occ; occurrences) {
            occ.loc = editor.level.topology.wrap(occ.loc);
        }
    }

    auto deletions = _selection[]
        .filter!(oil => null !is cast (TerOil) oil)
        .map!(oil => new TileRemoval(oil, oil.occ(level)))
        .array
        .sort!((a, b) => a.shouldBeAppliedBefore(b));
    TileInsertion insertion = new TileInsertion(
        new TerOil(level.terrain.len - deletions.length.to!int), groupOcc);
    apply(deletions
        .chain(only(insertion))
        .toCompoundUndoable);
}}

void ungroup(Editor editor) { with (editor)
{
    if (_selection.empty)
        return;
    auto visitor = new UngroupingVisitor(editor.level);
    /*
     * Each tile can generate an ungrouping, which is a CompoundUndoable.
     * We might want to ungroup all group in the selection, and if there is
     * more than one group in the selection, we could make a CompoundUndoable
     * of all the ungrouping CompoundUndoables.
     *
     * But for fear of inconsistent Oils,
     * I will only apply the first ungrouping and then cancel.
     */
    foreach (oil; editor._selection[]) {
        visitor.theGroup = oil.occ(levelRefacme);
        visitor.theGroup.tile.accept(visitor);
        if (visitor.retOrNull !is null) {
            apply(visitor.retOrNull);
            break;
        }
    }
}}

private:

void minimizeSelectionSelboxByMovingSomeAcrossTorus(Occurrences)(
    Editor editor,
    Occurrences occs
)   if (isInputRange!Occurrences && is (ElementType!Occurrences == TerOcc))
{   with (editor)
{
    void moveSomeOneDimension(
        in bool torus, in int torusLen,
        Side delegate(TerOcc) occToSide,
        int  delegate(TerOcc) occStart,
        int  delegate(TerOcc) occEnd,
        void delegate(TerOcc, int) occMove
    ) {
        if (! torus)
            return;
        Side s = occs.map!occToSide.nepstersAlgo(torusLen);
        foreach (occ; occs) {
            while (occStart(occ) < s.start)         occMove(occ,  torusLen);
            while (occEnd  (occ) > s.start + s.len) occMove(occ, -torusLen);
        }
    }
    moveSomeOneDimension(_map.topology.torusX, _map.topology.xl,
        (occ) { return occ.selboxOnMap.sideX; },
        (occ) { return occ.selboxOnMap.x; },
        (occ) { return occ.selboxOnMap.x + occ.selboxOnMap.xl; },
        (occ, by) { occ.loc.x += by; });
    moveSomeOneDimension(_map.topology.torusY, _map.topology.yl,
        (occ) { return occ.selboxOnMap.sideY; },
        (occ) { return occ.selboxOnMap.y; },
        (occ) { return occ.selboxOnMap.y + occ.selboxOnMap.yl; },
        (occ, by) { occ.loc.y += by; });
}}

/* https://www.lemmingsforums.net/index.php?topic=2720.msg58235#msg58235
 * As explained by Nepster: For each dimension, you want to compute
 *
 *  min over all R1 in the list L
 *      max over all R2 in the list L
 *          ((R2.x - R1.x) mod M.Width + R2.xl),
 *
 * where both R1 and R2 range over all rectangles in the list L.
 * (In this post mod will always return a non-negative result,
 * even if the input was negative).
 * Explanation:
 *
 *  ((R2.x - R1.x) mod M.Width + R2.xl): Computes the size of the smallest
 *      rect with left border starting at the border of R1 and containing R2.
 *  maxR2 [...]: Computes the size of the smallest rectangle with
 *      left border starting at the border of R1 and containing all rects in L.
 *  minR1 [...]: We choose that "start" rectangle R1 in L, for which the
 *      resulting rectangle O has minimal size.
 *
 * This algorithm is easiest to implement, but has runtime O(n^2).
 * Nepster explains how to improve the runtime to O(n log n), by sorting
 * the input list first according to positiveMod(side.start). Nonetheless,
 * I will keep the easy algorithm for now.
 */
Side nepstersAlgo(Sides)(
    Sides sides,
    in int torusLen,
)   if (isInputRange!Sides && is (ElementType!Sides == Side))
{
    Side ret = Side(0, int.max);
    foreach (r1; sides) {
        int maxOverR2 = 0;
        foreach (r2; sides)
            maxOverR2 = max(maxOverR2,
                (r2.start - r1.start).positiveMod(torusLen) + r2.len);
        if (maxOverR2 < ret.len)
            ret = Side(r1.start.positiveMod(torusLen), maxOverR2);
    }
    return ret;
}

unittest {
    // For one input rectangle, it's the same as computing position's modulo
    assert ([ Side(530, 10) ].nepstersAlgo(100) == Side(30, 10));

    // The first rectangle ends at 30, we have to span from 80 to 30.
    Side[] sides = [ Side(10, 20), Side(80, 5), Side(90, 30) ];
    assert (sides.nepstersAlgo(100) == Side(80, 50));
}

class UngroupingVisitor : TileVisitor {
public:
    CompoundUndoable retOrNull = null; // output
    Occurrence theGroup; // input

private:
    const(Level) _level;

public:
    this(const(Level) aLevel) { _level = aLevel; }

    override void visit(const(TerrainTile) te) { retOrNull = null; }
    override void visit(const(GadgetTile) ga) { retOrNull = null; }

    override void visit(const(TileGroup) groupTile)
    {
        if (groupTile.key.elements.len < 2) {
            retOrNull = null;
            return;
        }
        immutable int id = _level.terrain.countUntil(theGroup).to!int;
        assert (id >= 0, "Trying to ungroup nonexistant group");

        const(Occurrence) moveToOurPosition(Occurrence part)
        {
            part.loc += theGroup.loc - groupTile.transpCutOff;
            part.loc = _level.topology.wrap(part.loc);
            return part;
        }
        auto additions = groupTile.key.elements
            .map!(e => e.clone)
            .map!moveToOurPosition
            .enumerate!int
            .map!(tuple => new TileInsertion(
                new TerOil(id + tuple.index), tuple.value));
        retOrNull = only(new TileRemoval(new TerOil(id), theGroup))
            .chain(additions)
            .toCompoundUndoable;
    }
}
