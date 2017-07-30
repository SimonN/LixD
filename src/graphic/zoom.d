module graphic.zoom;

import std.array;
import std.algorithm;
import std.conv;
import std.math;
import std.range;

import basics.help;
import basics.rect;

class Zoom {
private:
    int _selected; // points int array allowed
    float[] _allowed;

public:
    this(Point levelL, Point cameraL)
    {
        /* a is fit-level-width-to-map, (b) is fit-level-height-to-map-height.
         * Even if blurry, these should be supported?
         */
        immutable float a = 1f / levelL.x * cameraL.x;
        immutable float b = 1f / levelL.y * cameraL.y;
        assert (a > 0.001f);
        assert (b > 0.001f);

        enum root2 = 1.41421f;
        _allowed = [ a, b, 1f/2, root2/2, 1, root2, 2, 3, 4, 6, 8, 16 ]
            .filter!(x => x >= min(a, b, 1)) // even on torus maps? Probably
            .array.sort().uniq.array;

        void initialZoom(in float val)
        {
            assert (_allowed.canFind!(x => x == val));
            _selected = 0xFFFF & _allowed.countUntil!(x => x == val);
            assert (_selected >= 0);
            assert (_selected < _allowed.len);
        }
        if (a < 1 && b < 1 && _allowed.canFind(1f))
            // Very large levels should use zoom 1.
            initialZoom(1f);
        else if ( ! _allowed.canFind(b)
                || (_allowed.canFind(a) && levelL.y > levelL.x))
            // If matching height is not allowed, match width.
            // Or, if the level is taller than wide, match width -- this
            // doesn't care about screen ratio to level ratio.
            initialZoom(a);
        else
            // In general, fit the level's height onto the screen's height.
            initialZoom(b);
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
}
