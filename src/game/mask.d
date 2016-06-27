module game.mask;

import std.conv;
import std.algorithm;
import std.range;
import std.string;

import enumap;

import basics.help;
import basics.matrix;
import game.terchang;

enum explodeMaskOffsetY = -6; // used in game.debris, too

const(Mask)[TerrainDeletion.Type] masks; // DTODO: should be const to outsiders

void initialize() { with (TerrainDeletion.Type)
{
    assert (! masks.length, "game.mask.initialize is called twice.");
    Mask[TerrainDeletion.Type] mutableMasks;
    scope (success)
        masks = mutableMasks;

    mutableMasks[bashRight] = Mask([
        "NNNNNNNNNNNN....", // Top 2 rows can cut through steel without
        "NNNNNNNNNNNNNN..", // cancelling the basher. Other rows would cancel.
        "XXXXXXXXXXXXXXX."] ~
        "XXXXXXXXXXXXXXXX".repeat(12).array ~ [
        "XXXXXXXXXXXXXXX.",
        "#XXXXXXXXXXXXX..", // '#' = effective coordinate
        "XXXXXXXXXXXX....",
    ]);
    mutableMasks[bashLeft] = mutableMasks[bashRight].mirrored;

    mutableMasks[bashNoRelicsRight] = Mask(
        "NNNNNNNNNNNNNNNN".repeat( 2).array ~ // ignore steel here
        "XXXXXXXXXXXXXXXX".repeat(14).array ~ [
        "#XXXXXXXXXXXXXXX", // '#' = effective coordinate
        "XXXXXXXXXXXXXXXX",
    ]);
    mutableMasks[bashNoRelicsLeft] = mutableMasks[bashNoRelicsRight].mirrored;

    mutableMasks[mineRight] = Mask([
        "...NNNNN..........", // -20
        ".NNNNNNNNN........",
        "NNXXXXXXNNNN......",
        "NNXXXXXXXXXXNN....",
        "NNXXXXXXXXXXXXN...", // -16
        "NNXXXXXXXXXXXXXX..", // -15
        "NNXXXXXXXXXXXXXXX.", // -14
        "NNXXXXXXXXXXXXXXX.", ] ~
        "NNXXXXXXXXXXXXXXXX".repeat(12).array ~ [ // from -12 to -1 inclusive
        "#XXXXXXXXXXXXXXXX.", // 0, with '#' the effective coordinate
        "XXXXXXXXXXXXXXXXX.", // 1
        "..XXXXXXXXXXXXXX..", // 2 = old ground level
        "....XXXXXXXXXXX...", // 3
        "......XXXXXXXX....", // 4
        "........XXXX......", // 5 = deepest air = miner hole depth is 4 px
    ]);
    mutableMasks[mineLeft] = mutableMasks[mineRight].mirrored;

    mutableMasks[explode] = Mask(22, explodeMaskOffsetY),
    mutableMasks[implode] = Mask([
    //  -16     -8       0       8       16
    //   |       |       |       |       |
        "..............XXXXXX..............", // -26
        "...........XXXXXXXXXXXX...........",
        ".........XXXXXXXXXXXXXXXX.........", // -24
        "........XXXXXXXXXXXXXXXXXX........",
        ".......XXXXXXXXXXXXXXXXXXXX.......",
        "......XXXXXXXXXXXXXXXXXXXXXX......", ] ~
        ".....XXXXXXXXXXXXXXXXXXXXXXXX.....".repeat(2).array ~// -20-19
        "....XXXXXXXXXXXXXXXXXXXXXXXXXX....".repeat(2).array ~// -18-17
        "...XXXXXXXXXXXXXXXXXXXXXXXXXXXX...".repeat(2).array ~// -16-15
        "..XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX..".repeat(3).array ~// -14-12
        ".XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.".repeat(5).array ~// -11 -7
        "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX".repeat(6).array ~//  -6 -1
        "XXXXXXXXXXXXXXXX#XXXXXXXXXXXXXXXXX".repeat(1).array ~//   0
        "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX".repeat(5).array ~//   1  5
        ".XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.".repeat(3).array ~//   6  8
        "..XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX..".repeat(2).array ~ [
        "...XXXXXXXXXXXXXXXXXXXXXXXXXXXX...",
        "....XXXXXXXXXXXXXXXXXXXXXXXXXX....",
        ".....XXXXXXXXXXXXXXXXXXXXXXXX.....", // 13
        "......XXXXXXXXXXXXXXXXXXXXXX......", // 14
        ".......XXXXXXXXXXXXXXXXXXXX.......", // 15
        ".........XXXXXXXXXXXXXXXX.........", // 16
        "............XXXXXXXXXX............", // 17
    //   |       |       |       |       |
    //  -16     -8       0       8       16
    ]);
}}

unittest
{
    initialize();
}

struct Mask {
    enum CharOK : char {
        solid       = 'X',
        solidIgnore = 'N', // ignore steel here, but remove terrain
        air         = '.',
        solidOffset = '#',
        airOffset   = 'o'
    }

    int offsetX;
    int offsetY;

    private Matrix!bool _solid;
    private Matrix!bool _ignoreSteel;
    const(Matrix!bool) solid()       const { return _solid; }
    const(Matrix!bool) ignoreSteel() const { return _ignoreSteel; }

    bool ignoreSteel(in int x, in int y) const
    {
        return ! _ignoreSteel || ignoreSteel.get(x, y);
    }

    this(in string[] strs)
    in {
        assert (strs.length    > 0, "need at least 1 row");
        assert (strs[0].length > 0, "need at least 1 column");
        assert (strs.all!(a => a.length == strs[0].length),
            "matrix of chars is not rectangular");
    }
    body {
        _solid         = new Matrix!bool(strs[0].len, strs.len);
        bool offsetSet = false;
        foreach     (const int y, const string s; strs)
            foreach (const int x, const char   c; s) {
                CharOK cc;
                try cc = std.conv.to!CharOK(c);
                catch (Exception)
                    assert (false, format("Bad character in string %d, `%s', "
                        ~ "at position %d: `%c'. Expected "
                        ~ "`.', `o', `X', `N', or `#'.", y, s, x, c).idup);
                _solid.set(x, y, cc == CharOK.solid
                              || cc == CharOK.solidIgnore
                              || cc == CharOK.solidOffset);
                if (cc == CharOK.solidIgnore) {
                    if (_ignoreSteel is null)
                    _ignoreSteel = new Matrix!bool(strs[0].len, strs.len);
                    _ignoreSteel.set(x, y, true);
                }
                if (cc == CharOK.solidOffset || cc == CharOK.airOffset) {
                    assert (! offsetSet, format(
                        "Offset is (%d, %d), but there is another "
                        ~ "offset-setting char `%c' at (%d, %d).",
                        offsetX, offsetY, c, x, y).idup);
                    offsetX = x;
                    offsetY = y;
                    offsetSet = true;
                }
            }
    }
    // end this()

    // generate circular mask
    this(in int radius, in int offsetFromCenterY)
    {
        // you'd normally want 2*radius + 1, but we're hi-res, so we use + 2
        // instead of + 1 for the central 2x2 block of of pixels.
        _solid     = new Matrix!bool(2*radius + 2, 2*radius + 2);
        auto midX = _solid.xl / 2 - 1; // top-left corner of central 2x2 block
        auto midY = _solid.yl / 2 - 1;
        offsetX   = midX;
        offsetY   = midY - offsetFromCenterY;

        foreach (int x; 0 .. _solid.xl)
            foreach (int y; 0 .. _solid.yl) {
                immutable int centralX = midX + (x > midX ? 1 : 0);
                immutable int centralY = midY + (y > midY ? 1 : 0);
                _solid.set(x, y, (radius + 0.5f)^^2 >=
                    (x - centralX)^^2 + (y - centralY)^^2);
            }
    }

    unittest {
        const a = typeof(this)(0, 0);
        assert (a == a.mirrored);
        assert (a == typeof(this)(["#X", "XX"]));
    }

    Mask mirrored() const
    in {
        assert (_solid.xl % 2 == 0, "can't mirror a matrix with odd xl");
        assert (offsetX   % 2 == 0, "can't mirror a matrix with odd offsetX");
    }
    body {
        Mask ret;
        ret._solid = new Matrix!bool(_solid.xl, _solid.yl);
        if (_ignoreSteel !is null)
            ret._ignoreSteel = new Matrix!bool(_solid.xl, _solid.yl);
        foreach     (const int y; 0 .. ret._solid.yl)
            foreach (const int x; 0 .. ret._solid.xl) {
                immutable mirrX = _solid.xl - 1 - x;
                ret._solid.set(x, y, this._solid.get(mirrX, y));
                if (ret._ignoreSteel)
                    ret._ignoreSteel.set(x, y, this._ignoreSteel.get(mirrX,y));
            }
        // Enforce the offset at an even coordinate, because the physics use
        // 2-pixel-wide chunks everywhere, using the left pixel's coordinates.
        ret.offsetX = basics.help.even(_solid.xl - 1 - offsetX);
        ret.offsetY = offsetY;
        return ret;
    }

}

unittest {
    const Mask a = Mask([
        ".X.X..",
        "..oX..",
        ".XX...",
    ]);
    assert (  a.solid.get(3, 0));
    assert (  a.solid.get(3, 1));
    assert (! a.solid.get(0, 0));
    assert (! a.solid.get(2, 1));
    assert (a.offsetX == 2);
    assert (a.offsetY == 1);

    const Mask b = Mask([
        "..X.X.",
        "..#...",
        "...XX.",
    ]);
    assert (b.offsetX == 2);
    assert (b == a.mirrored());

    const Mask topOfBasher = Mask([
        "NNNNNNNNNNNN....",
        "NNNNNNNNNNNNNN..",
        "#XXXXXXXXXXXXXX.",
        "XXXXXXXXXXXXXXXX"]);
    const Mask topOfBasherLeft = Mask([
        "....NNNNNNNNNNNN",
        "..NNNNNNNNNNNNNN",
        ".XXXXXXXXXXXXX#X",
        "XXXXXXXXXXXXXXXX"]);
    assert (topOfBasherLeft == topOfBasher.mirrored());

    // Compared to L1, the imploder mask is wider by 1 lo-res pixel.
    // This makes the imploder mask symmetric.
    assert (masks[TerrainDeletion.Type.implode].mirrored
        ==  masks[TerrainDeletion.Type.implode]);
}
