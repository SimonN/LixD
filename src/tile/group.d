module tile.group;

import std.algorithm;
import std.range;

import basics.alleg5;
import basics.rect;
import graphic.color;
import graphic.cutbit;
import graphic.torbit; // only as middleware interface, we discard it later
import hardware.tharsis;
import tile.abstile;
import tile.draw;
import tile.occur;
import tile.terrain;

class TileGroup : TerrainTile {
private:
    // Array of dupped tile occurrences, all moved by a constant amount
    // such that their relative positions remain the same, but the top-left
    // element starts at (0, 0).
    TerOcc[] _elements;

    // When we create the group, maybe we cut off transparent space at the
    // boundary, to create the smallest VRAM bitmap possible. We should then
    // remember how much space we cut off from the top-left, so the editor
    // can move the group towards the bottom-left by this positive amount.
    // Then, the group doesn't appear to move from its creation spot.
    Point _transpCutOff;

public:
    @property Point transpCutOff() const { return _transpCutOff; }

    this(T)(T occRange)
        if (isInputRange!T && is (ElementType!T == TerOcc))
    in {
        assert (! occRange.empty, "can't group zero tiles");
        assert (occRange.all!(occ => occ !is null));
    }
    out {
        assert (selbox == Rect(0, 0, cb.xl, cb.yl),
            "VRAM tile shall be as small as possible, no transparent border");
    }
    body {
        version (tharsisprofiling) {
            import std.string;
            Zone zone = Zone(profiler,
                "grouping %d tiles".format(occRange.walkLength));
        }
        Rect surround = occRange.map!(occ => occ.selboxOnMap)
                                .reduce!(Rect.smallestContainer);
        assert (surround.xl > 0 && surround.yl > 0);
        _elements = occRange.map!(occ => occ.clone).array;
        _elements .         each!(occ => occ.point -= surround.topLeft);

        // This torbit is probably too large, there is lots of empty space
        // at its sides. We will dispose the VRAM bitmap later.
        Torbit tb = new Torbit(surround.xl, surround.yl);
        tb.clearToColor(color.transp);
        with (DrawingTarget(tb.albit))
            _elements.each!(e => e.drawOccurrence(tb));
        auto tooLarge = new Cutbit(tb.loseOwnershipOfAlbit);
        Rect foundSelbox;
        with (LockReadOnly(tooLarge.albit))
            foundSelbox = tooLarge.findSelboxAssumeLocked();

        // This torbit now is of correct size.
        tb = new Torbit(foundSelbox.xl, foundSelbox.yl);
        tb.clearToColor(color.transp);
        with (DrawingTarget(tb.albit))
            al_draw_bitmap_region(tooLarge.albit,
                                  foundSelbox.x,  foundSelbox.y,
                                  foundSelbox.xl, foundSelbox.yl, 0, 0, 0);
        tooLarge.dispose();
        super(new Cutbit(tb.loseOwnershipOfAlbit));
        _transpCutOff = foundSelbox.topLeft;
    }
    // Thoughts about this constructor:
    // It's inefficient to allocate two bitmaps and only use one later.
    // I'm doing it like this to reuse code. Creating a tile will only
    // be performance-critical if we do it many times on level load.
    // I'll have to see how bad that will be.
}
