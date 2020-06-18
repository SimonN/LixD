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
import tile.visitor;

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
    // It's allowed to even call this with only dark tiles, but discouraged:
    // The caller checking that beforehand might be smarter than relying on
    // the exception that this constructor throws.
    // It's allowed to call it with dark tiles completely overlapping the
    // nondark tiles, the constructor will throw InvisibleException.
    this(TileGroupKey aKey)
    in { assert (aKey.elements.all!(occ => occ !is null)); }
    out {
        import std.format;
        assert (selbox.xl > 0 && selbox.yl > 0, "Tile can't be trivial.");
        assert (selbox == Rect(0, 0, cb.xl, cb.yl), format(
            "VRAM tile shall be as small as possible, no transparent border. "
            ~ "But this selbox is %s, not (0,0;%d,%d)", selbox, cb.xl, cb.yl));
        if (cb)
            assert (cb.xfs == 1 && cb.yfs == 1);
    }
    body {
        if (aKey.elements.all!(occ => occ.dark))
            throw new InvisibleException();

        this._key = aKey;
        version (tharsisprofiling) {
            import std.string;
            Zone zone = Zone(profiler,
                "grouping %d tiles".format(_key.elements.walkLength));
        }
        // Because of github 322 (see comment at top of TileGroupKey),
        // allow space for occ.cutbitOnMap, not merely occ.selboxOnMap.
        Rect surround = _key.elements.map!(occ => occ.cutbitOnMap)
                                     .reduce!(Rect.smallestContainer);
        // Unlike regular tile creation, we make the phymap first for groups,
        // only then make the image for groups. We make the phymap too large
        // and then crop it to the best size.
        Phymap phy = new Phymap(surround.xl, surround.yl);
        _key.elements.each!(e => e.drawOccurrence(phy));
        immutable Rect foundSelbox = phy.smallestNonzeroArea;
        if (foundSelbox.xl <= 0 || foundSelbox.yl <= 0)
            throw new InvisibleException();

        phy.cropTo(foundSelbox);
        _transpCutOff = foundSelbox.topLeft;

        Torbit tb = new Torbit(Torbit.Cfg(phy));
        tb.clearToColor(color.transp);
        with (TargetTorbit(tb))
            _key.elements.each!(e => e.drawOccurrence(-_transpCutOff));
        super("", new Cutbit(tb.loseOwnershipOfAlbit, Cutbit.Cut.no), phy);
    }

public:
    @property TileGroupKey key() const { return _key; }

    // No need to override name(): we initialize super with name = null.
    override @property const(TerrainTile)[] dependencies() const @nogc
    {
        assert (_key.tilesOfElements.length > 0);
        return _key.tilesOfElements;
    }

    override void accept(TileVisitor v) const { v.visit(this); }

    @property Point transpCutOff() const { return _transpCutOff; }

    class InvisibleException : Exception {
        this() { super("Can't create tile group with zero visible pixels."); }
    }
}

struct TileGroupKey {
private:
    // Array of dupped tile occurrences, all moved by a constant amount
    // such that their relative positions remain the same, but the leftmost
    // element starts at (0, y) and the topmost element starts at (x, 0).
    // These "starts" refer to the bitmap's positions, not the selboxes!
    // The selbox may be smaller if the bitmap has a transparent outline.
    // (There was a bug here with github issue 322.)
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
        // occ => occ.cutbitOnMap instead of occ => occ.selboxOnMap
        // because of Github 322; see comment at top of struct TileGroupKey.
        Point offsetFrom00ofTmp = tmp.map!(occ => occ.cutbitOnMap)
                           .reduce!(Rect.smallestContainer).topLeft;
        tmp.each!(occ => occ.loc -= offsetFrom00ofTmp);
        _elements = tmp.assumeUnique;
        _tilesOfElements = _elements.map!(occ => rebindable(occ.tile))
            .array
            .sort!((a, b) => a.toHash < b.toHash)
            .uniq
            .map!(occ => occ.get) // Rebindable!(const A) => const(A)
            .array;
    }

    auto elements() const
    {
        return _elements;
    }

    // dmd 2.078: This opEquals should be declared @safe nothrow pure,
    // but the compiler doesn't like that and wouldn't consider TileGroupKey
    // a possible AA key type then.
    bool opEquals(ref const typeof(this) rhs) const
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
    auto tilesOfElements() const @nogc { return _tilesOfElements; }
}
