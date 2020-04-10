module editor.dragger;

/* Editor should check for mouse clicks, and call the functions here depending
 * on mouse click status and whether we're hovering above tiles. MouseDragger
 * is only concerned with coordinates, not with clicks.
 */

import std.algorithm;
import std.math;
import std.typecons;

import basics.rect;
import editor.hover;
import graphic.camera.mapncam;
static import hardware.mouse; // only for position, not for clicks

class MouseDragger {
private:
    DragMode _mode;
    Point _fromMap;
    Point _fromScreen; // Used to determine the frame direction on torus maps.
                       // We must select one of the 4 meaningful rectangles.

    // _snapper: Non-null exactly while moving (see invariant).
    // Movement of tiles is governed by the grid, and by which tile the
    // snapper is. The snapper snaps to grid when it's moved by the mouse.
    // Other tiles in the selection should move by the same distance as the
    // snapper has moved, even if they don't end up snapped to grid.
    // The editor should pick the clicked-to-move tile and make that the
    // snapper. We don't move the snapper ourselves, or anything else.
    Rebindable!(const(Hover)) _snapper;

    enum DragMode { none, frame, move }

public:
    @property bool framing() const { return _mode == DragMode.frame; }
    @property bool moving()  const { return _mode == DragMode.move;  }

    void stop()
    {
        _mode = DragMode.none;
        _snapper = null;
    }

    void startFrame(const(MapAndCamera) map)
    {
        _mode = DragMode.frame;
        _snapper = null; // probably already null, but let's not guess
        saveFroms(map);
    }

    // Returns the frame rectangle on the map, not on the screen.
    // Nonetheless, this function depends on mouse coordinates on the screen:
    // framePart() needs them to determine frame spanning direction on tori.
    Rect frame(const(MapAndCamera) map) const
    {
        assert (framing);
        auto mol = map.mouseOnLand;
        auto xPart = framePart(_fromMap.x, mol.x, _fromScreen.x,
                               hardware.mouse.mouseX, map.xl, map.torusX);
        auto yPart = framePart(_fromMap.y, mol.y, _fromScreen.y,
                               hardware.mouse.mouseY, map.yl, map.torusY);
        return Rect(xPart.start, yPart.start, xPart.len + 1, yPart.len + 1);
    }

    void startMove(const(MapAndCamera) map, Hover snapper)
    {
        assert (snapper, "must startMove with a non-null snapper");
        _mode = DragMode.move;
        _snapper = snapper;
        saveFroms(map);
    }

    // Side effect: calling this makes it return 0 if called again immediately
    Point snapperShouldMoveBy(const(MapAndCamera) map, in int grid)
    {
        if (! moving)
            return Point(0, 0);
        immutable draggedOnGrid = (map.mouseOnLand - _fromMap).roundTo(grid);
        if (draggedOnGrid == Point(0, 0))
            return Point(0, 0);
        _fromMap += draggedOnGrid;
        assert (_snapper);
        return (_snapper.occ.loc + draggedOnGrid).roundTo(grid)
              - _snapper.occ.loc;
    }

    Point clonedShouldMoveBy() const
    {
        // DTODO: Implement something smart instead of returning the constant
        // offset. Remember how far we have moved the last copied piece,
        // then move by that amount.
        return Point(16, 16);
    }

private:
    invariant()
    {
        import std.format;
        assert ((_snapper !is null) == (_mode == DragMode.move),
            format!"_snapper is %s, but _mode is %s."(
            _snapper ? "non-null" : "null", _mode));
    }

    void saveFroms(const(MapAndCamera) map)
    {
        _fromMap    = map.mouseOnLand;
        _fromScreen = hardware.mouse.mouseOnScreen;
    }
}

private:

// Returns start and length without +1 along one dimension due to
// (mouse position when we started framing) and (mouse position now)
Side framePart(
    in int oldMap,    in int newMap, // one-dimensional coordinate on map
    in int oldScreen, in int newScreen, // one-dimensional coordinate on screen
    in int mapLen,    in bool torus
) pure
{
    bool frameGoesOverTorusSeam() {
        if (! torus)
            return false;
        return newMap < oldMap && newScreen > oldScreen
            || newMap > oldMap && newScreen < oldScreen;
    }
    return frameGoesOverTorusSeam()
        ? Side(max(oldMap, newMap), mapLen - abs(newMap - oldMap))
        : Side(min(oldMap, newMap),          abs(newMap - oldMap));
}
