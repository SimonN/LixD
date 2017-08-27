module editor.group;

import std.algorithm;
import std.range;

import basics.help; // positiveMod
import editor.editor;
import editor.hover;
import tile.group;
import tile.occur;
import tile.tilelib;

void createGroup(Editor editor) {
    with (editor)
{
    // Choose only the terrain occurrences. _selection may have hovers
    // of gadgets, those gadgets shall not become part of the new group.
    // I would like to remove the dynamic cast, but this code is clearest.
    auto occurrences = editor._selection
        .map   !(hov => cast (TerrainHover) hov)
        .filter!(hov => hov !is null)
        .map   !(hov => hov.occ);
    assert (occurrences.all!(occ => occ !is null && occ.tile !is null));
    if (   occurrences.walkLength < 2
        || occurrences.all!(occ => occ.dark))
        return;
    editor.minimizeSelectionSelboxByMovingSomeAcrossTorus(occurrences);
    TileGroup group;
    try
        group = getGroup(TileGroupKey(occurrences));
    catch (TileGroup.InvisibleException)
        return;

    // Hack. In all other cases, we let Level add occurrences to itself
    // by giving to Level the key and the position.
    // Here, we add the new occurrence ourselves.
    TerOcc groupOcc = new TerOcc(group);
    groupOcc.loc  = occurrences.map!(occ => occ.selboxOnMap)
                              .reduce!(Rect.smallestContainer)
                              .topLeft + group.transpCutOff;
    _level.terrain ~= groupOcc;
    _selection.filter!(s => cast (TerrainHover) s)
              .each  !(s => s.removeFromLevel());
    _selection = [ new GroupHover(_level, groupOcc, Hover.Reason.addedTile)];
}}

void ungroup(Editor editor)
{
    editor._selection
        = editor._selection.map!(hov => hov.replaceInLevelWithElements()).join;
}

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
    moveSomeOneDimension(_map.torusX, _map.xl,
        (occ) { return occ.selboxOnMap.sideX; },
        (occ) { return occ.selboxOnMap.x; },
        (occ) { return occ.selboxOnMap.x + occ.selboxOnMap.xl; },
        (occ, by) { occ.loc.x += by; });
    moveSomeOneDimension(_map.torusY, _map.yl,
        (occ) { return occ.selboxOnMap.sideY; },
        (occ) { return occ.selboxOnMap.y; },
        (occ) { return occ.selboxOnMap.y + occ.selboxOnMap.yl; },
        (occ, by) { occ.loc.y += by; });
}}

/* http://www.lemmingsforums.net/index.php?topic=2720.msg58235#msg58235
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
