module graphic.camera.camera1d;

import std.algorithm;
import std.conv;
import std.math;

import basics.help;
import basics.rect; // Side
import graphic.camera.zoom;

class Camera1D {
private:
    const(Zoom) _zoomOwnedBy2DCamera;

    /*
     * The point of the source Torbit that will be blit to the center
     * of the target. Also determines whether we can still scroll further.
     * Always in [0, sourceLen[.
     */
    int _focus;

public:
    /*
     * Number of pixels in the entire source Torbit. We will often copy
     * fewer than this to the target with the deeper zooms.
     * (sourceLen) and (torus) together describe one dimension of the
     * source Torbit.
     */
    immutable int sourceLen;
    immutable bool torus;

    /* Number of pixels in the target canvas. */
    immutable int targetLen;

public:
    this(
        in int aSourceLen,
        in bool aTorus,
        in int aTargetLen,
        const(Zoom) aZoom,
    ) in {
        assert (aSourceLen > 0, "Camera1D: source len must be > 0");
        assert (aTargetLen > 0, "Camera1D: target len must be > 0");
    }
    body {
        _zoomOwnedBy2DCamera = aZoom;
        targetLen = aTargetLen;
        sourceLen = aSourceLen;
        torus = aTorus;
        focus = aSourceLen / 2;
    }

    @property int focus() const pure nothrow @nogc
    {
        return _focus;
    }

    @property int focus(in int aFocus) pure
    {
        return _focus
            = torus ? basics.help.positiveMod(aFocus, sourceLen)
            : focusMin >= focusMax ? sourceLen / 2 // happens on small maps
            : clamp(aFocus, focusMin, focusMax);
    }

    // On non-torus maps, we want the initial scrolling position exactly at the
    // boundary, or a good chunk away from the boundary.
    void snapToBoundary()
    {
        if (torus)
            return;
        immutable int margin = focusMin / 6;
        if (2 * focus < focusMin + focusMax && focus < focusMin + margin)
            focus = focusMin;
        else if (focus > focusMax - margin)
            focus = focusMax;
    }

    @property const pure {
        bool mayScrollHigher() { return _focus < focusMax || torus; }
        bool mayScrollLower()  { return _focus > focusMin || torus; }
        bool seesEntireSource() { return numPixelsSeen >= sourceLen; }

        Side sourceSeen()
        out (side) {
            assert (side.start >= 0);
            assert (side.len >= 0);
        } body {
            immutable int first = focus - focusMin;
            immutable int start = torus
                ? positiveMod(first, sourceLen) : max(first, 0);
            return Side(start, numPixelsSeen);
        }

        /*
         * The rectangle never wraps over a torus seam, but instead is cut off.
         * Callers who what to draw a full screen rectangle must compute the
         * remainder behind the seam themselves.
         * This is bad design, Camera1D should compute the remainder.
         */
        Side sourceSeenBeforeFirstTorusSeam()
        out (side) {
            assert (side.start >= 0);
            assert (side.len >= 0);
            assert (side.start + side.len <= sourceLen);
        } body {
            immutable Side uncut = sourceSeen;
            return Side(uncut.start, min(uncut.len, sourceLen - uncut.start));
        }
    }

    /*
     * Input: Coordinate on the target, offset from its lower end.
     * Output: The coordinate of the source that projects there.
     * A purely linear transformation, no cutting at source boundaries.
     */
    int sourceOf(in int onTarget) const pure
    {
        immutable ret = divByZoom(onTarget) + sourceSeen.start;
        return torus ? positiveMod(ret, sourceLen) : ret;
    }

private:
    @property const pure {
        int focusMin() { return numPixelsSeen / 2; }
        int focusMax() { return sourceLen - numPixelsSeen + focusMin; }
        // Why not focusMax = sourceLen - focusMin? If numPixelsSeen is odd,
        // dividing by 2 discards some length, and we want
        // (focusMax - focusMin) == numPixelsSeen exactly.

        /*
         * numPixelsSeen: Number of pixels from the source that are copied.
         * With deep zoom, (large value zoom()), then this is small.
         * Zoomed out, this might be more than the source.
         */
        int numPixelsSeen() { return divByZoom(targetLen); }

        final int divByZoom(in float x) { return (x / zoom).ceil.to!int; }
        final float zoom() { return _zoomOwnedBy2DCamera.current; }
    }
}
