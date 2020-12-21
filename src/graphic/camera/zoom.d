module graphic.camera.zoom;

import std.array;
import std.algorithm;
import std.conv;
import std.math;
import std.range;

import basics.help;
import basics.topology;
import level.level;

class Zoom {
private:
    // The currently selected zoom is _allowed[_selected]: Call current().
    int _selected;

    // Ordered list (smallest number first) of allowed zoom factors.
    // Smaller zooms make the world appear smaller, fitting more world
    // on the screen.
    float[] _allowed;

public:
    this(in Topology level, in Point cameraLen)
    {
        populateAllowed(level, cameraLen);
        selectOneAllowed(level, cameraLen);
    }

    @property const pure nothrow @nogc @safe {
        float current() { return _allowed[_selected]; }
        bool zoomableIn() { return _selected < _allowed.len - 1; }
        bool zoomableOut() { return _selected > 0; }
    }

    bool preferNearestNeighbor() const pure
    {
        return abs(current.roundInt - current) < 0.01f || current >= 3;
    }

    void zoomIn()  { if (zoomableIn) ++_selected; }
    void zoomOut() { if (zoomableOut) --_selected; }

    const pure @safe {
        int divideFloor(in float x) { return (x / current).floor.to!int; }
        int divideCeil (in float x) { return (x / current).ceil .to!int; }
    }

private:
    mixin template aAndB() {
        /* a is fit-level-width-to-map, (b) is fit-level-height-to-map-height.
         * Even if blurry, these should be supported?
         */
        immutable float a = 1f / level.xl * cameraLen.x;
        immutable float b = 1f / level.yl * cameraLen.y;
    }

    void populateAllowed(in Topology level, in Point cameraLen)
    {
        mixin aAndB;
        enum root2 = 1.41421f;
        _allowed = [ a, b, 1f/2, root2/2, 1, root2, 2, 3, 4, 6, 8, 16 ].sort()
            .filter!(x => x >= min(a, b, 1)) // even on torus maps? Probably
            .uniq.array;
    }

    void selectOneAllowed(in Topology level, in Point cameraLen)
    {
        mixin aAndB;
        void selectAtMost(in float val)
        {
            assert (_allowed.canFind!(x => x <= val));
            _selected = 0xFFFF & (_allowed.count!(x => x <= val) - 1);
            assert (_selected >= 0);
            assert (_selected < _allowed.len);
        }
        if (level.torusY) {
            // Fit the map onto the screen, but never go below 1 or above
            // too many layers (more than 2) of the map. This is a separate
            // if-branch from (! level.torusY) because of:
            // https://github.com/SimonN/LixD/issues/323
            // Wide, flat level (768x160) starts too zoomed-in at 800x600.
            selectAtMost(max(1f, min(2*a, b), min(a, 2*b)));
        }
        else {
            // In general, fit to height (b), except fit small maps onto the
            // screen entirely by min(a, b) or have huge maps select
            // at least zoom 1.
            selectAtMost(max(1f, level.xl <= Level.cppLixOneScreenXl
                ? min(a, b) : b));
        }

        void roundDownToInt(float target)
        {
            // never round up, that might obscure vertically outlying ledges
            if (current/target > 1f && current/target < 1.2f)
                selectAtMost(target);
        }
        [1f, 2f, 3f, 4f].each!roundDownToInt;
    }
}

unittest {
    Zoom z = new Zoom(new Topology(1000, 1000, false, false), Point(640, 400));
    assert (z.current() >= 1,
        "Don't zoom out to less than 1 on large levels.");
    z = new Zoom(new Topology(768, 160, false, true), Point(800, 600));
    assert (z.current() <= 2.2, "Github #323: Wide, flat level shouldn't start"
        ~ " too zoomed-in. This issue was in 0.9.14, the zoom there was"
        ~ " more than 3. Zoom now is: "
        ~ z.current.to!string);
}
