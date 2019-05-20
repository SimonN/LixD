module editor.clone;

import std.algorithm;

import basics.topology;
import editor.editor;

void cloneSelection(Editor editor) {
    with (editor)
{
    /*
     * awsbiamb, "All would still be inside map after moving by":
     * Assuming we moved all selected tiles by (by), would all tiles still be
     * within the map boundaries? We even require that they're inside the map
     * by a considerable safety margin, not merely by a few pixels.
     */
    bool awsbimamb(in Point by)
    {
        // Omit safety margin for torus directions since everything is inside.
        immutable int safetyX = _level.topology.torusX ? 0 : 16 - 1;
        immutable int safetyY = _level.topology.torusY ? 0 : 16 - 1;
        immutable Rect insideMap = Rect(Point(safetyX, safetyY),
            _level.topology.xl - 2 * safetyX,
            _level.topology.yl - 2 * safetyY);
        assert (insideMap.xl > 0 && insideMap.yl > 0, "safetyMargin too big");
        return _selection.map!(s => s.occ.selboxOnMap + by)
            .all!(rect => _level.topology.rectIntersectsRect(insideMap, rect));
    }

    immutable Point clonedShouldMoveBy = () {
        immutable Point idea = editor._dragger.clonedShouldMoveBy;
        return awsbimamb(idea) ? idea : awsbimamb(-idea) ? -idea : idea;
    }();

    foreach (sel; _selection) {
        sel.cloneThenPointToClone();
        sel.moveBy(clonedShouldMoveBy);
    }
    // editor._dragger.startRecordingCopyMove();
}}
