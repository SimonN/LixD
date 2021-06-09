module level.noowalgo;

/* Lemmings 1 and C++ Lix allow no-overwrite pieces. A no-overwrite piece N
 * is drawn at normal time, i.e., when it comes in the terrain list in order.
 * N's pixels drawn like this: For each pixel, the pixel is only drawn where
 * there is air on the target land pixel exactly before the tile N is drawn.
 *
 * This drawing is time-consuming for the machine. It doesn't match the mental
 * model either: The no-overwrite trick is a poor man's tile cutting.
 * We should cut by grouping tiles instead.
 */

import std.algorithm;
import std.range;

import basics.topology;
import hardware.tharsis;
import tile.group;
import tile.occur;
import tile.tilelib;

/* Algorithm: No-overwrite to groups autoconversion.
 * Input: TerOcc[], some occurrences are no-overwrite
 * Output: TerOcc[], no occurrences are no-overwrite, may have more TileGroups.
 *
 * Theory: http://www.lemmingsforums.net/index.php?topic=2695.0
 */
TerOcc[] noowAlgorithm(TerOcc[] terrain, in Topology topol)
out (ret) {
    assert (ret.all!(occ => ! occ.noow));
}
do {
    version (tharsisprofiling)
        auto zone = Zone(profiler, "noowAlgo, any level");
    if (! terrain.any!(occ => occ.noow))
        return terrain;
    version (tharsisprofiling)
        auto zone2 = Zone(profiler, "noowAlgo, exists noow");

    MarkedOcc[] output;
    foreach (next; terrain) {
        if (! next.noow)
            output ~= MarkedOcc(next);
        else {
            output.groupWhatIsDangerousFor(next, topol);
            next.noow = false;
            output = MarkedOcc(next) ~ output;
        }
    }
    return output.map!(mo => mo.occ).array;
}

private struct MarkedOcc {
    TerOcc occ;
    bool mustGroup;
    /*
     * I'll remove...
     *      alias occurrence this;
     * ...because this prints a warning with DMD 2.084:
     * Warning: struct MarkedOcc has method toHash, however it cannot be
     * called with const(MarkedOcc) this.
     * Re this warning: https://issues.dlang.org/show_bug.cgi?id=19517
     * And I'll patiently wait for D's ProtoObject. >_>;
     */
}

/* Algorithm: Find pieces for 0 or 1 new group, replace pieces by group.
 * Input: The noow-free list of already-processed tiles. The next no-overwrite
 *        tile that may require grouping of tiles in the list.
 * Output: Nothing, but we modify the mutable input list. Either the list stays
 *         the same, or we remove some pieces and replace them by 1 group.
 *
 * Clobbers: This function modifies the input list.
 *           This function clobbers list[n].mustGroup.
 *
 * Invariant: Before and after this function, nothing in the list is noow.
 * This doesn't add (TerOcc next) to the list. This only makes groups.
 */
private void groupWhatIsDangerousFor(
    ref MarkedOcc[] list,
    const(TerOcc) next,
    const(Topology) topol)
in {
    assert (next.noow);
    assert (! list.any!(mo => mo.occ.noow));
}
out {
    assert (! list.any!(mo => mo.occ.noow));
}
do {
    bool overlaps(in TerOcc top, in TerOcc bottom)
    {
        return topol.rectIntersectsRect(top.selboxOnMap, bottom.selboxOnMap);
    }
    bool isDangerous(in TerOcc occ)
    {
        return occ.dark && overlaps(next, occ);
    }
    version (tharsisprofiling)
        auto zone = Zone(profiler, "noow group, any noow");
    if (! list.any!(mo => isDangerous(mo.occ)))
        return;
    version (tharsisprofiling)
        auto zone2 = Zone(profiler, "noow group, exists danger");

    // Initialize the set of pieces to be grouped.
    foreach (ref mo; list)
        mo.mustGroup = isDangerous(mo.occ);
    assert (list.any!(mo => mo.mustGroup));

    // Enlarge the group until we don't find anything worthwhile to add
    bool continueGrouping = true;
    while (continueGrouping) {
        continueGrouping = false;
        /* Explanation of the following long pipeline:
         * (1) list.enumerate maps MarkedOccs to
         *     struct { int index; MarkedOcc value; }
         * (2) We want to enlarge the group:
         *     We only care about what's not yet in it.
         *     Thus, our subject of interest is a non-group piece.
         * (3) Select only non-group pieces that are overlapped by a
         *     group piece. Even though overlaps(a, b) == overlaps(b, a),
         *     we only compare group pieces with higher list index
         *     than the non-group piece. That's why we enumerated in (1).
         * (4) Don't do addToGroupAndContinue(tuple.value) because structs
         *     are value types and tuple.value is a copy of struct MarkedOcc.
         *     We want to affect list[i]. Thus, access the list with index.
         */
        list.enumerate // (1)
            .filter!(tuple => ! tuple.value.mustGroup) // (2)
            .filter!(tuple => list[tuple.index + 1 .. $]
                .filter!(later => later.mustGroup)
                .any!(later => overlaps(later.occ, tuple.value.occ))) // (3)
            .each!((tuple) {
                assert (! tuple.value.mustGroup);
                list[tuple.index].mustGroup = true; // (4)
                continueGrouping = true;
            });
    }
    // We create a large tile from all occurrences marked with mustGroup,
    // remove the marked occurrences, and put the large tile into the list.
    auto key = list.filter!(elem => elem.mustGroup).map!(mo => mo.occ);
    assert (! key.empty);
    auto loc = key.map!(occ => occ.selboxOnMap)
                  .reduce!(Rect.smallestContainer)
                  .topLeft;
    try {
        TileGroup group = getGroup(TileGroupKey(key));
        assert (group);
        auto minPos = list.countUntil!(mo => mo.occ == key.front);
        assert (minPos < list.length);
        assert (minPos >= 0);
        // Alter the input list for the 1st time in this function.
        // Don't remove all pieces and then add the group, because that would
        // allocate. The algo doesn't need to reallocate the list if we
        // replace the first-to-delete and only delete the rest.
        list[minPos] = MarkedOcc(new TerOcc(group,
                       topol.wrap(loc + group.transpCutOff)));
        assert (! list[minPos].mustGroup);
    }
    catch (TileGroup.InvisibleException) {
        // The algorithm has decided that we make a group entirely from
        // tiles (dark or non-dark, but at least the noow piece should be
        // non-dark) that leave only dark pixels in the group. Don't add this!
        // We will remove the group pieces and put nothing back, perfect.
    }
    // Now alter the input list for the 2nd time.
    list = std.algorithm.remove!(elem => elem.mustGroup)(list);
}
