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
import std.typecons;

import basics.alleg5;
import basics.rect;
import graphic.color;
import graphic.cutbit;
import graphic.torbit; // only as middleware interface, we discard it later
import hardware.tharsis;
import tile.abstile;
import tile.draw;
import tile.occur;
import tile.phymap;
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

package:
    // This constructor is package access: To get a group from a TileGroupKey,
    // use tile.tilelib.get_group(TileGroupKey) instead, it caches these.
    this(TileGroupKey aKey)
    in {
        assert (! aKey.elements.empty, "can't group zero tiles");
        assert (aKey.elements.all!(occ => occ !is null));
        assert (aKey.elements.any!(occ => ! occ.dark),
            "can't group only dark.");
    }
    out {
        import std.format;
        assert (selbox == Rect(0, 0, cb.xl, cb.yl),
            "VRAM tile shall be as small as possible, no transparent border. "
            "But this selbox is %s, not (0,0;%d,%d)"
            .format(selbox, cb.xl, cb.yl));
    }
    body {
        this._key = aKey;
        version (tharsisprofiling) {
            import std.string;
            Zone zone = Zone(profiler,
                "grouping %d tiles".format(_key.elements.walkLength));
        }
        Rect surround = _key.elements.map!(occ => occ.selboxOnMap)
                                     .reduce!(Rect.smallestContainer);
        // Unlike regular tile creation, we make the phymap first for groups,
        // only then make the image for groups. We make the phymap too large
        // and then crop it to the best size.
        Phymap phy = new Phymap(surround.xl, surround.yl);
        _key.elements.each!(e => e.drawOccurrence(phy));
        immutable Rect foundSelbox = phy.smallestNonzeroArea;
        phy.cropTo(foundSelbox);
        _transpCutOff = foundSelbox.topLeft;

        Torbit tb = new Torbit(phy);
        tb.clearToColor(color.transp);
        with (DrawingTarget(tb.albit))
            _key.elements.each!(e => e.drawOccurrence(tb, -_transpCutOff));
        super("", new Cutbit(tb.loseOwnershipOfAlbit), phy);
    }

public:
    @property TileGroupKey key() const { return _key; }

    // No need to override name(): we initialize super with name = null.
    // dependencies() allocates, I'd like to see how to prevent that :-(
    override @property const(TerrainTile)[] dependencies() const
    {
        assert (_key.tilesOfElements.length > 0);
        return _key.tilesOfElements;
    }

    @property Point transpCutOff() const { return _transpCutOff; }
}

struct TileGroupKey {
private:
    // Array of dupped tile occurrences, all moved by a constant amount
    // such that their relative positions remain the same, but the leftmost
    // element starts at (0, y) and the topmost element starts at (x, 0).
    immutable(TerOcc)[] _elements;
    const(TerrainTile)[] _tilesOfElements; // for AbstractTile.dependencies()

public:
    // This will move the copied tiles according to the comment at _elements.
    this(T)(T occRange)
        if (isInputRange!T && is (ElementType!T : const(TerOcc)))
    out {
        import std.string;
        assert (_elements.empty == _tilesOfElements.empty,
            "%d elements, but %d tilesOfElements"
            .format(_elements.length, _tilesOfElements.length));
    }
    body {
        if (occRange.empty)
            return;
        auto tmp = occRange.map!(occ => occ.clone).array;
        Rect surround = tmp.map!(occ => occ.selboxOnMap)
                           .reduce!(Rect.smallestContainer);
        assert (surround.xl > 0 && surround.yl > 0);
        tmp.each!(occ => occ.loc -= surround.topLeft);
        _elements = tmp.assumeUnique;

        const(TerrainTile) unrebind(Rebindable!(const(TerrainTile)) a)
        {
            return a;
        }
        _tilesOfElements = _elements.map!(occ => rebindable(occ.tile))
            .array
            .sort!((a, b) => a.toHash < b.toHash)
            .map!unrebind
            .uniq.array;
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

protected:
    auto tilesOfElements() const { return _tilesOfElements; }
}
