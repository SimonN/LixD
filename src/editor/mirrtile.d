module editor.mirrtile;

/*
 * Mirror, rotate, darken tiles.
 * This module accesses the package fields of Editor and creates Undoables,
 * so that the Undoables don't have to access the Editor fields anymore.
 */

import std.algorithm;
import std.range;

import basics.help;
import basics.topology;
import editor.editor;
import editor.undoable.addrm;
import editor.undoable.compound;
import editor.undoable.dark;
import editor.undoable.rotmirr;
import level.oil;
import tile.occur;

void removeFromLevelTheSelection(Editor editor) { with (editor)
{
    apply(_selection[]
        .map!(oil => new TileRemoval(oil, oil.occ(level).clone))
        .array
        .sort!((a, b) => a.shouldBeAppliedBefore(b))
        .toCompoundUndoable);
}}

void toggleDarkTheSelection(Editor editor) { with (editor)
{
    OilSet selectedDarkenable = _selection[]
        .filter!(oil => oil.occ(level).can.darken)
        .toOilSet;
    if (selectedDarkenable.empty)
        return;
    apply(new ToggleDark(selectedDarkenable.assumeUnique));
}}

///////////////////////////////////////////////////////////////////////////////
// Mirroring and Rotating /////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

alias mirrorSelectionHorizontally
    = transformSelectionInBoxAndApply!createMirroredOccWithin;
alias rotateSelectionClockwise
    = transformSelectionInBoxAndApply!createRotatedOccWithin;

private auto transformInBox(alias trafo, Range)(
    Editor editor,
    Range range
) {
    immutable Rect smallestContainingBox = range.save
        .map!(oil => oil.occ(editor.level).selboxOnMap)
        .reduce!(Rect.smallestContainer);
    return range.map!(oil => trafo(
        oil.occ(editor.level),
        editor.level.topology,
        smallestContainingBox));
}

private void transformSelectionInBoxAndApply(alias trafo)(Editor editor)
{ with (editor)
{
    if (editor._selection[].empty)
        return;
    auto occsBefore = _selection[]
        .map!(oil => cast(immutable(Occurrence)) oil.occ(level).clone);
    auto occsAfter = editor.transformInBox!trafo(_selection[]);
    static assert (is (
        ElementType!(typeof(occsAfter)) == immutable(Occurrence)));
    apply(zip(StoppingPolicy.requireSameLength,
        editor._selection[], occsBefore, occsAfter)
        .map!(tup => new TileRotation(tup[0], tup[1], tup[2]))
        .toCompoundUndoable);
}}

private immutable(Occurrence) createMirroredOccWithin(
    in Occurrence old,
    in Topology topol,
    in Rect box // see mirrorSelectionHorizontally
) {
    Occurrence ret = old.clone;
    immutable self = ret.cutbitOnMap;
    /*
     * The box is around all the selboxes, but we move according to our
     * cutbit's box, not according to our selbox. This fixes github #144.
     * This differs fundamentally from what we do for rotations!
     */
    ret.loc.x -= self.x - box.x;
    ret.loc.x += box.x + box.xl - self.x - self.xl;
    ret.loc = topol.wrap(ret.loc);
    if (ret.can.mirror) {
        ret.mirrY = ! ret.mirrY;
    }
    if (ret.can.rotate) {
        ret.rotCw = (2 - ret.rotCw) & 3;
    }
    return cast(immutable(Occurrence)) ret;
}

private immutable(Occurrence) createRotatedOccWithin(
    in Occurrence old,
    in Topology topol,
    in Rect box // see mirrorSelectionHorizontally
) {
    Occurrence ret = old.clone;
    /*
     * A rotation is a movement around the midpoint.
     * After computing the occ's selbox's midpoint and the box's midpoint,
     * we don't need the box anymore.
     */
    immutable Rect self = ret.selboxOnMap;
    immutable float ourX = self.x + self.xl / 2f;
    immutable float ourY = self.y + self.yl / 2f;
    immutable float aroundX = box.x + box.xl / 2f;
    immutable float aroundY = box.y + box.yl / 2f;
    immutable float boxRoundFix = ((box.xl + box.yl) & 1) ? 0.5f : 0;
    ret.loc = topol.wrap(Point(
        roundInt(aroundX + (aroundY - ourY) - self.xl / 2f - boxRoundFix),
        roundInt(aroundY - (aroundX - ourX) - self.yl / 2f - boxRoundFix))
        - ret.selboxOnTile.topLeft);

    if (ret.can.rotate) {
        immutable oldCenter = ret.selboxOnMap.center;
        ret.rotCw = (ret.rotCw + 1) & 3;
        // There is a rounding error: Without this function, 18x17 cutbits
        // keep their bottom-right-hand corner regardless of
        // their orientation, and 17x16 tiles keep their top-left
        // corner, no matter their orientation. Add error-recovery point
        // to always keep the top-left corner:
        Point errorRecovery()
        {
            // Bypass the rotation, access the tile without its rotation
            if ((ret.tile.selbox.xl & 1) == 0 && (ret.tile.selbox.yl & 1))
                // We have already rotated, check out the new value here
                return (ret.rotCw & 1) ? Point(-1, 1) : Point(1, -1);
            else
                return Point(0, 0);
        }
        // Editing rotCw doesn't turn around the occurrence's center,
        // but instead keeps the occurrence's topLeft the same. To compensate
        // for this, move the tile so that the rotation seems to have been
        // around the center.
        ret.loc += oldCenter - ret.selboxOnMap.center + errorRecovery;
        ret.loc = topol.wrap(ret.loc);
    }
    else if (ret.can.mirror) {
        // Hack for hatches, so you can flip them by mirroring or by rotating
        ret.mirrY = ! ret.mirrY;
    }
    return cast (immutable(Occurrence)) ret;
}
