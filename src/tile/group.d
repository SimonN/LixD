module tile.group;

/* TileGroupKey guarantees that its leftmost element starts at x-coordinate 0
 * and its topmost element starts at y-coordinate 0.
 *
 * TileGroup may be smaller than the box that surrounds all of TileGroupKey's
 * elements' selection boxes. When you add a TileGroup occurrence at (30, 40),
 * then the elements of the TileGroup's TileGroupKey may look like they've
 * been placed at (< 30, < 40). This is because we cut the TileGroup to minimal
 * size, such that its selbox == its Cutbit's size.
 *
 * Client code in the editor should not call TileGroup's constructor directly.
 * Instead, that code should ask the tile library whether we already have
 * the group, and use the existing group. The tile library will create the
 * group for you if necessary.
 */

import std.algorithm;
import std.exception;
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
    TileGroupKey _key;

    // When we create the group, maybe we cut off transparent space at the
    // boundary, to create the smallest VRAM bitmap possible. We should then
    // remember how much space we cut off from the top-left, so the editor
    // can move the group towards the top-left by this positive amount.
    // Then, the group doesn't appear to move from its creation spot.
    Point _transpCutOff;

public:
    this(TileGroupKey aKey)
    in {
        assert (! aKey.elements.empty, "can't group zero tiles");
        assert (aKey.elements.all!(occ => occ !is null));
    }
    out {
        assert (selbox == Rect(0, 0, cb.xl, cb.yl),
            "VRAM tile shall be as small as possible, no transparent border");
    }
    body {
        this._key = aKey;
        version (tharsisprofiling) {
            import std.string;
            Zone zone = Zone(profiler,
                "grouping %d tiles".format(_key.elements.walkLength));
        }
        // This torbit is probably too large, there is lots of empty space
        // at its sides. We will dispose the VRAM bitmap later.
        Rect surround = _key.elements.map!(occ => occ.selboxOnMap)
                                     .reduce!(Rect.smallestContainer);
        Torbit tb = new Torbit(surround.xl, surround.yl);
        tb.clearToColor(color.transp);
        with (DrawingTarget(tb.albit))
            _key.elements.each!(e => e.drawOccurrence(tb));
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

    @property TileGroupKey key() const { return _key; }

    @property Point transpCutOff() const { return _transpCutOff; }
}

struct TileGroupKey {
private:
    // Array of dupped tile occurrences, all moved by a constant amount
    // such that their relative positions remain the same, but the leftmost
    // element starts at (0, y) and the topmost element starts at (x, 0).
    immutable(TerOcc)[] _elements;

public:
    this(T)(T occRange)
        if (isInputRange!T && is (ElementType!T == TerOcc))
    {
        if (occRange.empty)
            return;
        auto tmp = occRange.map!(occ => occ.clone).array;
        Rect surround = tmp.map!(occ => occ.selboxOnMap)
                           .reduce!(Rect.smallestContainer);
        assert (surround.xl > 0 && surround.yl > 0);
        tmp.each!(occ => occ.point -= surround.topLeft);
        _elements = tmp.assumeUnique;
    }

    auto elements() const
    {
        return _elements;
    }

    bool opEquals(ref const typeof(this) rhs) const @safe pure nothrow
    {
        return rhs._elements == this._elements;
    }

    size_t toHash() const @trusted nothrow
    {
        size_t accum = 0;
        foreach (terOcc; _elements)
            accum = ((accum << 5) & ~31) + (cast () terOcc.tile).toHash();
        return accum;
    }
}
