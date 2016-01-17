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

enum Mask[TerrainChange.Type] masks = [
    TerrainChange.Type.bashLeft           : _bashLeft,
    TerrainChange.Type.bashRight          : _bashRight,
    TerrainChange.Type.bashNoRelicsLeft   : _bashNoRelicsLeft,
    TerrainChange.Type.bashNoRelicsRight  : _bashNoRelicsRight,
    TerrainChange.Type.mineLeft           : _mineLeft,
    TerrainChange.Type.mineRight          : _mineRight,
    TerrainChange.Type.implode            : _implode,
    TerrainChange.Type.explode            : Mask(22, explodeMaskOffsetY),
];

private enum Mask _bashLeft  = _bashRight.mirrored;
private enum Mask _bashRight = Mask([
    "NNNNNNNN" "NNNN....", // Top 2 rows can cut through steel without
    "NNNNNNNN" "NNNNNN..", // cancelling the basher. Other rows would cancel.
    "XXXXXXXX" "XXXXXXX."] ~
    "XXXXXXXX" "XXXXXXXX".repeat(12).array ~ [
    "XXXXXXXX" "XXXXXXX.",
    "#XXXXXXX" "XXXXXX..", // '#' = effective coordinate
    "XXXXXXXX" "XXXX....",
]);

private enum _bashNoRelicsLeft  = _bashNoRelicsRight.mirrored;
private enum _bashNoRelicsRight = Mask(
    "NNNNNNNN" "NNNNNNNN".repeat( 2).array ~ // ignore steel here
    "XXXXXXXX" "XXXXXXXX".repeat(14).array ~ [
    "#XXXXXXX" "XXXXXXXX", // '#' = effective coordinate
    "XXXXXXXX" "XXXXXXXX",
]);

private enum _mineLeft  = _mineRight.mirrored;
private enum _mineRight = Mask([
    "...XXXXX" "........" "..", // -20
    ".XXXXXXX" "XX......" "..",
    "XXXXXXXX" "XXXX...." "..",
    "XXXXXXXX" "XXXXXX.." "..",
    "XXXXXXXX" "XXXXXXX." "..", // -16
    "XXXXXXXX" "XXXXXXXX" "..", // -15
    "XXXXXXXX" "XXXXXXXX" "X.", // -14
    "XXXXXXXX" "XXXXXXXX" "X.", ] ~
    "XXXXXXXX" "XXXXXXXX" "XX".repeat(12).array ~ [ // from -12 to -1 inclusive
    "#XXXXXXX" "XXXXXXXX" "X.", // 0, with '#' the effective coordinate
    "XXXXXXXX" "XXXXXXXX" "X.", // 1
    "..XXXXXX" "XXXXXXXX" "..", // 2 = old ground level
    "....XXXX" "XXXXXXX." "..", // 3
    "......XX" "XXXXXX.." "..", // 4
    "........" "XXXX...." "..", // 5 = deepest air = miner hole depth is 4 px
]);

// DTODOSKILLS: This mask is asymmetric! Should be 2 hi-res pixels thicker or
// thinner, or be mirrored for left-facers.
// Only asymmetric because of location of #. The X's themselves are symmetric.
private enum _implode = Mask([
//   -16.. -9   -8 .. -1   0  ..  7   8  .. 15
    "........" "....XXXX" "XXXX...." "........", // -26
    "........" "..XXXXXX" "XXXXXX.." "........",
    "........" "XXXXXXXX" "XXXXXXXX" "........",
    ".......X" "XXXXXXXX" "XXXXXXXX" "X.......", // -23

    "......XX" "XXXXXXXX" "XXXXXXXX" "XX......", // -22
    "......XX" "XXXXXXXX" "XXXXXXXX" "XX......",
    ".....XXX" "XXXXXXXX" "XXXXXXXX" "XXX.....",
    ".....XXX" "XXXXXXXX" "XXXXXXXX" "XXX.....", // -19
    "....XXXX" "XXXXXXXX" "XXXXXXXX" "XXXX....",
    "....XXXX" "XXXXXXXX" "XXXXXXXX" "XXXX....",
    "...XXXXX" "XXXXXXXX" "XXXXXXXX" "XXXXX...",
    "...XXXXX" "XXXXXXXX" "XXXXXXXX" "XXXXX...", // -15
    ] ~
    "..XXXXXX" "XXXXXXXX" "XXXXXXXX" "XXXXXX..".repeat(3).array ~// -14,-13,-12
    ".XXXXXXX" "XXXXXXXX" "XXXXXXXX" "XXXXXXX.".repeat(5).array ~// -11 thrg -7
    "XXXXXXXX" "XXXXXXXX" "XXXXXXXX" "XXXXXXXX".repeat(6).array ~// -6 thrg -1
    "XXXXXXXX" "XXXXXXXX" "#XXXXXXX" "XXXXXXXX".repeat(1).array ~// 0
    "XXXXXXXX" "XXXXXXXX" "XXXXXXXX" "XXXXXXXX".repeat(5).array ~// 1 2 3 4 5
    ".XXXXXXX" "XXXXXXXX" "XXXXXXXX" "XXXXXXX.".repeat(3).array ~// 6 7 8
    "..XXXXXX" "XXXXXXXX" "XXXXXXXX" "XXXXXX..".repeat(2).array ~// 9 10
    "...XXXXX" "XXXXXXXX" "XXXXXXXX" "XXXXX...".repeat(2).array ~ [
    "....XXXX" "XXXXXXXX" "XXXXXXXX" "XXXX....", // 13
    ".....XXX" "XXXXXXXX" "XXXXXXXX" "XXX.....", // 14
    ".......X" "XXXXXXXX" "XXXXXXXX" "X.......", // 15
    "........" ".XXXXXXX" "XXXXXXX." "........", // 16
    "........" "...XXXXX" "XXXXX..." "........", // 17
]);

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
        _solid          = new Matrix!bool(strs[0].len, strs.len);
        bool offsetSet = false;
        foreach     (const int y, const string s; strs)
            foreach (const int x, const char   c; s) {
                CharOK cc;
                try cc = std.conv.to!CharOK(c);
                catch (Exception)
                    assert (false, format(
                        "Bad character in string %d, `%s', "
                        "at position %d: `%c'. "
                        "Expected `.', `o', `X', `N', or `#'.",
                        y, s, x, c).idup);
                _solid.set(x, y, cc == CharOK.solid
                             || cc == CharOK.solidIgnore
                             || cc == CharOK.solidOffset);
                if (cc == CharOK.solidIgnore) {
                    if (_ignoreSteel is null)
                    _ignoreSteel = new Matrix!bool(strs[0].len, strs.len);
                    _ignoreSteel.set(x, y, true);
                }
                if (   cc == CharOK.solidOffset
                    || cc == CharOK.airOffset
                ) {
                    assert (! offsetSet, format(
                        "Offset is (%d, %d), but there is another "
                        "offset-setting char `%c' at (%d, %d).",
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
        auto a = typeof(this)(0, 0);
        assert (a == a.mirrored);
        assert (a == typeof(this)(["#X", "XX"]));
    }

    Mask mirrored() const
    in {
        assert (_solid.xl % 2 == 0, "can't mirror a matrix with odd xl");
        assert (offsetX  % 2 == 0, "can't mirror a matrix with odd offsetX");
    }
    body {
        Mask ret;
        ret._solid = new Matrix!bool(_solid.xl, _solid.yl);
        foreach     (const int y; 0 .. ret._solid.yl)
            foreach (const int x; 0 .. ret._solid.xl)
                ret._solid.set(x, y, this._solid.get(_solid.xl - 1 - x, y));
        // Enforce the offset at an even coordinate, because the physics use
        // 2-pixel-wide chunks everywhere, using the left pixel's coordinates.
        ret.offsetX = basics.help.even(_solid.xl - 1 - offsetX);
        ret.offsetY = offsetY;
        return ret;
    }

}

unittest {
    Mask a = Mask([
        ".X.X..",
        "..oX..",
        ".XX...",
    ]);
    assert (  a.get(3, 0));
    assert (  a.get(3, 1));
    assert (! a.get(0, 0));
    assert (! a.get(2, 1));
    assert (a.offsetX == 2);
    assert (a.offsetY == 1);

    Mask b = Mask([
        "..X.X.",
        "..#...",
        "...XX.",
    ]);
    assert (b.offsetX == 2);
    assert (b == a.mirrored());

    assert (masks[TerrainChange.Type.implode].mirrored
        !=  masks[TerrainChange.Type.implode]);
        // this is a physics bug, we should strive to get == instead of !=
}
