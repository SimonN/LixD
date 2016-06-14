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

enum Mask[TerrainDeletion.Type] masks = [
    TerrainDeletion.Type.bashLeft          : _bashLeft,
    TerrainDeletion.Type.bashRight         : _bashRight,
    TerrainDeletion.Type.bashNoRelicsLeft  : _bashNoRelicsLeft,
    TerrainDeletion.Type.bashNoRelicsRight : _bashNoRelicsRight,
    TerrainDeletion.Type.mineLeft          : _mineLeft,
    TerrainDeletion.Type.mineRight         : _mineRight,
    TerrainDeletion.Type.implode           : _implode,
    TerrainDeletion.Type.explode           : Mask(22, explodeMaskOffsetY),
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

private enum _implode = Mask([
//   -16.. -9   -8 .. -1   0    2  ..  9   10  .. 15
    "........" "......XX" "XX" "XX......" "........", // -26
    "........" "...XXXXX" "XX" "XXXXX..." "........",
    "........" ".XXXXXXX" "XX" "XXXXXXX." "........", // -24
    "........" "XXXXXXXX" "XX" "XXXXXXXX" "........",
    ".......X" "XXXXXXXX" "XX" "XXXXXXXX" "X.......",
    "......XX" "XXXXXXXX" "XX" "XXXXXXXX" "XX......", ] ~
    ".....XXX" "XXXXXXXX" "XX" "XXXXXXXX" "XXX.....".repeat(2).array ~// -20-19
    "....XXXX" "XXXXXXXX" "XX" "XXXXXXXX" "XXXX....".repeat(2).array ~// -18-17
    "...XXXXX" "XXXXXXXX" "XX" "XXXXXXXX" "XXXXX...".repeat(2).array ~// -16-15
    "..XXXXXX" "XXXXXXXX" "XX" "XXXXXXXX" "XXXXXX..".repeat(3).array ~// -14-12
    ".XXXXXXX" "XXXXXXXX" "XX" "XXXXXXXX" "XXXXXXX.".repeat(5).array ~// -11 -7
    "XXXXXXXX" "XXXXXXXX" "XX" "XXXXXXXX" "XXXXXXXX".repeat(6).array ~//  -6 -1
    "XXXXXXXX" "XXXXXXXX" "#X" "XXXXXXXX" "XXXXXXXX".repeat(1).array ~//   0
    "XXXXXXXX" "XXXXXXXX" "XX" "XXXXXXXX" "XXXXXXXX".repeat(5).array ~//   1  5
    ".XXXXXXX" "XXXXXXXX" "XX" "XXXXXXXX" "XXXXXXX.".repeat(3).array ~//   6  8
    "..XXXXXX" "XXXXXXXX" "XX" "XXXXXXXX" "XXXXXX..".repeat(2).array ~ [
    "...XXXXX" "XXXXXXXX" "XX" "XXXXXXXX" "XXXXX...",
    "....XXXX" "XXXXXXXX" "XX" "XXXXXXXX" "XXXX....",
    ".....XXX" "XXXXXXXX" "XX" "XXXXXXXX" "XXX.....", // 13
    "......XX" "XXXXXXXX" "XX" "XXXXXXXX" "XX......", // 14
    ".......X" "XXXXXXXX" "XX" "XXXXXXXX" "X.......", // 15
    "........" ".XXXXXXX" "XX" "XXXXXXX." "........", // 16
    "........" "....XXXX" "XX" "XXXX...." "........", // 17
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
    Mask a = Mask([
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

    Mask b = Mask([
        "..X.X.",
        "..#...",
        "...XX.",
    ]);
    assert (b.offsetX == 2);
    assert (b == a.mirrored());

    Mask topOfBasher = Mask([
        "NNNNNNNN" "NNNN....",
        "NNNNNNNN" "NNNNNN..",
        "#XXXXXXX" "XXXXXXX.",
        "XXXXXXXX" "XXXXXXXX"]);
    Mask topOfBasherLeft = Mask([
        "....NNNN" "NNNNNNNN",
        "..NNNNNN" "NNNNNNNN",
        ".XXXXXXX" "XXXXXX#X",
        "XXXXXXXX" "XXXXXXXX"]);
    assert (topOfBasherLeft == topOfBasher.mirrored());

    // Compared to L1, the imploder mask is wider by 1 lo-res pixel.
    // This makes the imploder mask symmetric.
    assert (masks[TerrainDeletion.Type.implode].mirrored
        ==  masks[TerrainDeletion.Type.implode]);
}
