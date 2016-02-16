module basics.topology;

/* Topology represents a rectangle of a given size, possibly with one or both
 * sides wrapping around. Can compute distances.
 *
 * If size/topology is changed, protected overridables are called.
 */

import std.range; // iseputRange

import std.algorithm;
import std.conv;
import std.math;
import std.string;

import basics.help; // positiveMod

abstract class Topology {
private:
    int  _xl, _yl; // x- and y-length of our rectangular area
    bool _tx, _ty; // torus property in either direction, making edges loop

public:
    this(in int nxl, in int nyl, in bool ntx = false, in bool nty = false)
    in {
        assert (nxl > 0 && nyl > 0,
            "Topology: (xl, yl) > 0 required, not (%d, %d)".format(nxl, nyl));
    }
    body {
        _xl = nxl;
        _yl = nyl;
        _tx = ntx;
        _ty = nty;
    }

    this(in Topology rhs)
    {
        _xl = rhs._xl;
        _yl = rhs._yl;
        _tx = rhs._tx;
        _ty = rhs._ty;
    }

    override bool opEquals(Object rhsObj) const
    {
        const(Topology) rhs = cast (const Topology) rhsObj;
        if (! rhs)
            return false;
        return _xl == rhs._xl
            && _yl == rhs._yl
            && _tx == rhs._tx
            && _ty == rhs._ty;
    }

    final @property int  xl()     const { return _xl; }
    final @property int  yl()     const { return _yl; }
    final @property bool torusX() const { return _tx; }
    final @property bool torusY() const { return _ty; }

    final void resize(in int nxl, in int nyl)
    in {
        assert (_xl > 0, "Topology: xl > 0 required");
        assert (_yl > 0, "Topology: yl > 0 required");
    }
    body {
        if (_xl == nxl && _yl == nyl)
            return;
        _xl = nxl;
        _yl = nyl;
        onResize();
        onAnyChange();
    }

    final void setTorusXY(in bool x, in bool y)
    {
        if (_tx == x && _ty == y)
            return;
        _tx = x;
        _ty = y;
        onAnyChange();
    }

    // This computes distances similar to (1st_arg - 2nd_arg), but it
    // check for shortcuts around the cylinder/torus if appropriate.
    int distanceX(in int x1, in int x2) const
    {
        if (! _tx) return x2 - x1;
        else {
            int[] possible = [x2-x1, x2-x1-_xl, x2-x1+_xl];
            return std.algorithm.minPos!"abs(a) < abs(b)"(possible)[0];
        }
    }

    int distanceY(in int y1, in int y2) const
    {
        if (! _ty) return y2 - y1;
        else {
            int[] possible = [y2-y1, y2-y1-_yl, y2-y1+_yl];
            return std.algorithm.minPos!"abs(a) < abs(b)"(possible)[0];
        }
    }

    float hypot(in int x1, in int y1, in int x2, in int y2) const
    {
        return std.math.sqrt(hypotSquared(x1, y1, x2, y2).to!float);
    }

    int hypotSquared(in int x1, in int y1, in int x2, in int y2) const
    {
        immutable int dx = distanceX(x2, x1);
        immutable int dy = distanceY(y2, y1);
        return (dx * dx + dy * dy);
    }

    bool isPointInRectangle(
        // given point  // given rectangle by position and length
        int px, int py, int rx, int ry, in int rxl, in int ryl) const
    {
        if (_tx) {
            px = positiveMod(px, _xl);
            rx = positiveMod(rx, _xl);
            // the following (if) omits the need for a 4-subrectangle-check
            if (px < rx) px += _xl;
        }
        if (_ty) {
            py = positiveMod(py, _yl);
            ry = positiveMod(ry, _yl);
            if (py < ry) py += _yl;
        }
        return (px >= rx && px < rx + rxl)
            && (py >= ry && py < ry + ryl);
    }

    int torusAverageX(Range)(Range range) const if (isInputRange!Range)
    {
        return torusAverage(xl, torusX, (a, b) => distanceX(a, b), range);
    }

    int torusAverageY(Range)(Range range) const if (isInputRange!Range)
    {
        return torusAverage(yl, torusY, (a, b) => distanceY(a, b), range);
    }

protected:
    void onResize()    { }
    void onAnyChange() { }

private:
    // dmd 2.070 has a 6-year old bug: This template is public, even though
    // it's marked private. Please take care not to call it. :-]
    // Call torusAverageX/Y instead, those are public methods.
    int torusAverage(Range)(
        in int  screenLen,
        in bool torus,
        int delegate(int, int) dist,
        Range hatchPoints
    ) const
        if (isInputRange!Range)
    {
        immutable int len = hatchPoints.walkLength.to!int;
        immutable int avg = hatchPoints.sum / len;
        if (! torus)
            return avg;
        auto distToAllHatches(in int point)
        {
            return hatchPoints.map!(h => dist(point, h).abs).sum;
        }
        int closestPoint(in int a, in int b)
        {
            return distToAllHatches(a) <= distToAllHatches(b) ? a : b;
        }
        auto possiblePointsOnTorus = sequence!((unused, n) =>
            (avg + n.to!int * screenLen/len) % screenLen).takeExactly(len);
        static assert (is (typeof(possiblePointsOnTorus[0]) == int));
        return possiblePointsOnTorus.reduce!closestPoint;
    }
}
