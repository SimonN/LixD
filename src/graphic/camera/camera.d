module graphic.camera.camera;

/*
 * No hardware is queried here.
 * Pass all hardware readings (mouse, keyboard) into here.
 * Camera does not know about Torbit, only about Topology.
 */

import std.conv;
import std.math;

import basics.help;
import basics.topology;
import graphic.camera.camera1d;
import graphic.camera.zoom;

class Camera {
private:
    Zoom _zoom; // owned, created by ourself
    Camera1D _x;
    Camera1D _y;

public:
    this(in Topology tp, in Point targetLen)
    {
        _zoom = new Zoom(tp, targetLen);
        _x = new Camera1D(tp.xl, tp.torusX, targetLen.x, _zoom);
        _y = new Camera1D(tp.yl, tp.torusY, targetLen.y, _zoom);
    }

    /*
     * Stuff here gets called in graphic.camera.map.
     * This is legacy behavior. Find everything from those call sites
     * that can instead go into Camera.
     * Then decide whether these functions should become public or erased.
     */
    package @property const pure nothrow @nogc {
        int targetXl() { return _x.targetLen; }
        int targetYl() { return _y.targetLen; }
        Point targetL() { return Point(_x.targetLen, _y.targetLen); }

        Point focus() { return Point(_x.focus, _y.focus); }
        final float zoom() { return _zoom.current; }
    }

    package @property const pure {
        bool mayScrollRight() { return _x.mayScrollHigher(); }
        bool mayScrollLeft()  { return _x.mayScrollLower(); }
        bool mayScrollDown()  { return _y.mayScrollHigher(); }
        bool mayScrollUp()    { return _y.mayScrollLower(); }

        bool preferNearestNeighbor() { return _zoom.preferNearestNeighbor; }
        final int divByZoomCeil(in float x) { return _zoom.divideCeil(x); }

        Rect sourceSeen()
        {
            return Rect(_x.sourceSeen, _y.sourceSeen);
        }

        Rect sourceSeenBeforeFirstTorusSeam()
        {
            return Rect(
                _x.sourceSeenBeforeFirstTorusSeam,
                _y.sourceSeenBeforeFirstTorusSeam);
        }
    }

    @property Point focus(in Point p)
    {
        _x.focus = p.x;
        _y.focus = p.y;
        return Point(_x.focus, _y.focus);
    }

    void zoomInKeepingSourcePointFixed(in Point sourceToFix)
    {
        zoomKeepingSourcePointFixed(sourceToFix, { _zoom.zoomIn(); });
    }

    void zoomOutKeepingSourcePointFixed(in Point sourceToFix)
    {
        zoomKeepingSourcePointFixed(sourceToFix, { _zoom.zoomOut(); });
    }

    void zoomInKeepingTargetPointFixed(in Point targetToFix)
    {
        zoomKeepingTargetPointFixed(targetToFix, { _zoom.zoomIn(); });
    }

    void zoomOutKeepingTargetPointFixed(in Point targetToFix)
    {
        zoomKeepingTargetPointFixed(targetToFix, { _zoom.zoomOut(); });
    }

    void zoomOutToSeeEntireSource()
    {
        while (_zoom.zoomableOut
            && ! (_x.seesEntireSource && _y.seesEntireSource)
        ) {
            _zoom.zoomOut();
        }
        focus = focus;
    }

    void snapToBoundary()
    {
        _x.snapToBoundary();
        _y.snapToBoundary();
    }

    /*
     * Input: A point on the target, as offset from top-left corner of target.
     *
     * Output: The point on the source that the camera, given its current
     * position and zoom, projects to the input point. The output point is
     * measured from the top-left corner of the source.
     *
     * This is a purely linear transformation. It doesn't cut off at the
     * source or target boundaries. If you ask what is far left of the screen,
     * you'll get source coordinates with far negative x.
     */
    Point sourceOf(in Point onTarget) const pure
    {
        return Point(_x.sourceOf(onTarget.x), _y.sourceOf(onTarget.y));
    }

private:
    void zoomKeepingSourcePointFixed(
        in Point sourceToFix,
        void delegate() callZoom,
    ) {
        immutable oldZoom = zoom;
        callZoom();
        /*
         * Now, we want to move the focus such that sourceToFix will be
         * projected to the same target pixel before and after callZoom().
         * The new focus is a convex combination of sourceToFix and old focus.
         * We'll denote by (a) the factor of the two-fold convex combi.
         */
        immutable a = 1f - (oldZoom / zoom);
        focus = Point(
            roundInt(a * sourceToFix.x + (1f - a) * focus.x),
            roundInt(a * sourceToFix.y + (1f - a) * focus.y));
    }

    void zoomKeepingTargetPointFixed(
        in Point targetToFix,
        void delegate() callZoom,
    ) {
        immutable Point oldSource = sourceOf(targetToFix);
        callZoom();
        immutable Point newSource = sourceOf(targetToFix);
        focus = focus + oldSource - newSource;
    }
}

version (unittest) {
    void assertNear(in Point a, in Point b, in string msg = "")
    {
        assert (abs(a.x - b.x) < 3 && abs(a.y - b.y) < 3,
            "Points aren't together: "
            ~ a.to!string
            ~ " and "
            ~ b.to!string
            ~ (msg == "" ? "" : " - ")
            ~ msg);
    }

    void assertNear(in Point a, in Point b, in Camera c, in string msg = "")
    {
        assertNear(a, b,
            "zoom=" ~ c.zoom.to!string
            ~ " focus=" ~ c.focus.to!string
            ~ " sourceSeen=" ~ c.sourceSeen.to!string
            ~ (msg == "" ? "" : " - ")
            ~ msg);
    }
}

unittest {
    Topology tp = new Topology(400, 300, false, false);
    Camera c = new Camera(tp, Point(80, 50));

    void assertCIsLikeAtStart(in string msg)
    {
        assert (c.zoom == 1f, msg ~ ", zoom");
        assert (c.sourceSeen == Rect(160, 125, 80, 50));
        assert (c.sourceOf(Point(0, 0)) == Point(160, 125),
            msg ~ ", sourceOf(0)=" ~ c.sourceOf(Point(0, 0)).to!string);
        assert (c.focus == Point(200, 150), msg ~ " should focus on center");
    }
    for (int i = 0; i < 5; ++i) {
        assertCIsLikeAtStart("really at start");
        immutable mid = Point(200, 150);
        for (int _ = 0; _ < i; ++_) {
            c.zoomInKeepingSourcePointFixed(mid);
        }
        assertNear(c.focus, mid, c,
            "non-torus zooming in, focus - iteration " ~ i.to!string);
        assertNear(c.sourceSeen.center, mid, c,
            "non-torus zooming in, sourceSeen - iteration " ~ i.to!string);
        for (int _ = 0; _ < i; ++_) {
            c.zoomOutKeepingSourcePointFixed(mid);
        }
        assertCIsLikeAtStart("after zooming in and out at center of map");
    }

    immutable Point p = Point(200, 125);
    assert (p.y == c.sourceSeen.y, "want to zoom in at top of viewfield");

    assertCIsLikeAtStart("before considering p");
    c.zoomInKeepingSourcePointFixed(p);
    assert (c.focus.x == 200, "we zoomed into the x-center once");
    assert (c.focus.y >= 125, "beans " ~ c.focus.to!string);
    assert (c.focus.y <= 150, "bacon " ~ c.focus.to!string);
    assertNear(p, Point(c.focus.x, c.sourceSeen.y), c,
        "p should stay at top of viewfield 1");
    c.zoomInKeepingSourcePointFixed(p);
    assert (c.focus.x == 200, "we zoomed into the x-center twice");
    assert (c.zoom == 2f, "zoom in around p, zoom should be 2");
    assertNear(p, Point(c.focus.x, c.sourceSeen.y), c,
        "p should stay at top of viewfield 2");
    assertNear(c.focus, Point(200, 125 + 25/2), c, "after zooming in 2x at p");
}

unittest {
    Topology tp = new Topology(200, 200, false, true);
    Camera c = new Camera(tp, Point(50, 50));

    void assertCIsLikeAtStart(in string msg)
    {
        assert (c.zoom == 1f, msg);
        assert (c.sourceSeen == Rect(75, 75, 50, 50),
            msg ~ ", we see around the center: " ~ c.sourceSeen.to!string);
        assert (c.sourceOf(Point(5, 5)) == Point(80, 80),
            msg ~ ", now sourceOf(5, 5)=" ~ c.sourceOf(Point(5, 5)).to!string);
    }
    assertCIsLikeAtStart("really at start");
    immutable Point mid = Point(100, 100);
    c.zoomInKeepingSourcePointFixed(mid);
    assertNear(c.focus, mid, c, "zooming into center");
    c.zoomOutKeepingSourcePointFixed(mid);
    assertCIsLikeAtStart("after zoom in and out at center of map");

    immutable Point roof = Point(100, 75);
    c.zoomInKeepingSourcePointFixed(roof);
    c.zoomInKeepingSourcePointFixed(roof);
    {
        assert (c.zoom == 2f);
        assertNear(Point(c.focus.x, c.sourceSeen.y), roof, c,
            "after zooming to zoom 2 to roof");
    }
}
