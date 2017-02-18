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

        /* Allowed zoom values are (a), (b), and furthermore all nice powers
         * of 2 that aren't close to either a or b.
         */
        bool apart(in float x, in float y)
        {
            assert (x > 0 && y > 0);
            return x/y + y/x > 2.08f;
        }
        _allowed = [ 1f/2, 1, 2, 4, 8, 16 ]
            .filter!(x => x > min(a, b)) // even on torus maps? Probably
            .filter!(x => apart(x, a) && apart(x, b))
            .chain(apart(a, b) ? [a, b] : [ min(a, b) ])
            .array;
        _allowed.sort();

        /* Select initial zoom:
         * In general, fit the level's height onto the screen's height.
         * Special case: If the level is extremely large, use zoom 1.
         * Special case: If matching height isn't in _allowed, match width.
         */
        if (a < 1 && b < 1 && _allowed.canFind(1f))
            _selected = 0xFFFF & _allowed.countUntil(1f);
        else
            _selected = 0xFFFF & _allowed.countUntil!(x =>
                                    x == b || x == a && ! apart(a, b));
    }

    @property float current() const pure { return _allowed[_selected]; }

    @property bool zoomableIn() const { return _selected < _allowed.len - 1; }
    @property bool zoomableOut() const { return _selected > 0; }

    void zoomIn()  { if (zoomableIn) ++_selected; }
    void zoomOut() { if (zoomableOut) --_selected; }

    bool preferNearestNeighbor() const
    {
        return abs(current.roundInt - current) < 0.02f || current >= 3;
    }
}
