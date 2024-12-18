module editor.movetile;

import std.algorithm;
import std.range;

import file.option;
import basics.rect;
import editor.editor;
import editor.undoable.move;
import level.oil;

void moveTiles(Editor editor) {
    with (editor)
{
    /*
     * (anyHardwarePressed...) is not necessarily the perfect way to check
     * for a fully finished undoable move that shouldn't be merged with
     * future moves. But it's the best I can think of in 2020.
     * Non-moving undoables (rotating, mirroring, deleting, adding, ...)
     * will stop the current move anyway, the undo stack will do that for us.
     */
    if (_selection.empty || ! editor.anyHardwarePressedThatCouldMoveTiles) {
        stopCurrentMove();
        return;
    }
    immutable total = movedByKeyboard()
        + _dragger.snapperShouldMoveBy(level, _map, editorGridSelected.value);
    if (total == Point(0, 0)) {
        return;
    }
    applyAndTrustThatTheSelectionWillNotChange(_selection[]
        .map!(oil => new TileMove(oil.toOilSet.assumeUnique,
            oil.occ(level).loc,
            level.topology.wrap(oil.occ(level).loc + total)))
        .reduce!((tileMove, nextMove)
            => tileMove.add(level.topology, nextMove)));
}}

///////////////////////////////////////////////////////////////////////////////
private: ///////////////////////////////////////////////////////////// :private
///////////////////////////////////////////////////////////////////////////////

Point movedByKeyboard()
{
    immutable grid = editorGridSelected.value;
    return Point(-grid, 0) * keyEditorLeft .wasTappedOrRepeated
        +  Point(+grid, 0) * keyEditorRight.wasTappedOrRepeated
        +  Point(0, -grid) * keyEditorUp   .wasTappedOrRepeated
        +  Point(0, +grid) * keyEditorDown .wasTappedOrRepeated;
}

bool anyHardwarePressedThatCouldMoveTiles(in Editor editor) {
    with (editor)
{
    return _dragger.moving
        || keyEditorLeft.isHeld
        || keyEditorRight.isHeld
        || keyEditorUp.isHeld
        || keyEditorDown.isHeld;
}}
