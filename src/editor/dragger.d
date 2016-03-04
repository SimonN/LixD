module editor.dragger;

/* Editor should check for mouse clicks, and call the functions here depending
 * on mouse click status and whether we're hovering above tiles. MouseDragger
 * is only concerned with coordinates, not with clicks.
 */

import std.algorithm;
import std.math;

import basics.topology; // Rect
import graphic.map;
static import hardware.mouse; // only for position, not for clicks

class MouseDragger {
private:
    DragMode _mode;
    int _fromMapX;
    int _fromMapY;
    int _fromScreenX; // Used to determine the frame direction on torus maps.
    int _fromScreenY; // We must select one of the 4 meaningful rectangles.

    enum DragMode { none, frame, move }

public:
    @property bool framing() const { return _mode == DragMode.frame; }
    @property bool moving()  const { return _mode == DragMode.move;  }

    void stop()
    {
        _mode = DragMode.none;
    }

    void startFrame(const(Map) map)
    {
        _mode = DragMode.frame;
        saveFroms(map);
    }

    // Returns the frame rectangle on the map, not on the screen.
    Rect frame(const(Map) map) const
    {
        assert (framing);
        return Rect(min(_fromMapX, map.mouseOnLandX),
                    min(_fromMapY, map.mouseOnLandY),
                    abs(_fromMapX - map.mouseOnLandX),
                    abs(_fromMapY - map.mouseOnLandY));
    }

    void startMove(const(Map) map)
    {
        _mode = DragMode.move;
        saveFroms(map);
    }

    void movedSince(const(Map) map, int* dx, int* dy)
    {
        assert (moving);
        assert (dx != null && dy != null);
        *dx = map.mouseOnLandX - _fromMapX;
        *dy = map.mouseOnLandY - _fromMapY;
        saveFroms(map);
    }

private:
    void saveFroms(const(Map) map)
    {
        _fromMapX = map.mouseOnLandX;
        _fromMapY = map.mouseOnLandY;
        _fromScreenX = hardware.mouse.mouseX;
        _fromScreenY = hardware.mouse.mouseY;
    }
}
