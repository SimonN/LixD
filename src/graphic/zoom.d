module graphic.zoom;

import std.array;
import std.algorithm;
import std.conv;
import std.math;
import std.range;

import basics.help;
import basics.rect;
import level.level;

class Zoom {
private:
    int _selected; // points int array allowed
    float[] _allowed;

public:
    this(Point levelL, Point cameraL)
    {
        populateAllowed(levelL, cameraL);
        selectOneAllowed(levelL, cameraL);
    }

    @property float current() const pure { return _allowed[_selected]; }

    @property bool zoomableIn() const { return _selected < _allowed.len - 1; }
    @property bool zoomableOut() const { return _selected > 0; }

    void zoomIn()  { if (zoomableIn) ++_selected; }
    void zoomOut() { if (zoomableOut) --_selected; }

    bool preferNearestNeighbor() const
    {
        return abs(current.roundInt - current) < 0.01f || current >= 3;
    }

private:
    mixin template aAndB() {
        /* a is fit-level-width-to-map, (b) is fit-level-height-to-map-height.
         * Even if blurry, these should be supported?
         */
        immutable float a = 1f / levelL.x * cameraL.x;
        immutable float b = 1f / levelL.y * cameraL.y;
    }

    void populateAllowed(in Point levelL, in Point cameraL)
    {
        mixin aAndB;
        enum root2 = 1.41421f;
        _allowed = [ a, b, 1f/2, root2/2, 1, root2, 2, 3, 4, 6, 8, 16 ].sort()
            .filter!(x => x >= min(a, b, 1)) // even on torus maps? Probably
            .uniq.array;
    }

    void selectOneAllowed(in Point levelL, in Point cameraL)
    {
        mixin aAndB;
        void select(in float val)
        {
            assert (_allowed.canFind!(x => x == val));
            _selected = 0xFFFF & _allowed.countUntil!(x => x == val);
            assert (_selected >= 0);
            assert (_selected < _allowed.len);
        }
        // In general, fit to height (b), except fit small maps onto the screen
        // entirely by min(a, b) or have huge maps select at least zoom 1.
        select(max(1f, levelL.x <= Level.cppLixOneScreenXl ? min(a, b) : b));

        void roundDownToInt(float target)
        {
            // never round up, that might obscure vertically outlying ledges
            if (current/target > 1f && current/target < 1.1f)
                select(target);
        }
        [1f, 2f, 3f, 4f].each!roundDownToInt;
    }
}
