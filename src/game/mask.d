module game.mask;

import std.conv;
import std.algorithm;
import std.range;
import std.string;

import enumap;

import basics.help;
import basics.matrix;
import game.terchang;

enum Mask[TerrainChange.Type] masks = [
    TerrainChange.Type.bashLeft           : _bashLeft,
    TerrainChange.Type.bashRight          : _bashRight,
    TerrainChange.Type.bashNoRelicsLeft   : _bashNoRelicsLeft,
    TerrainChange.Type.bashNoRelicsRight  : _bashNoRelicsRight,
    TerrainChange.Type.mineLeft           : _mineLeft,
    TerrainChange.Type.mineRight          : _mineRight
];

private enum Mask _bashLeft  = _bashRight.mirrored;
private enum Mask _bashRight = Mask([
    "XXXXXXXX" "XXXX....", // Top 2 rows can cut through steel without
    "XXXXXXXX" "XXXXXX..", // cancelling the basher. Other rows would cancel.
    "XXXXXXXX" "XXXXXXX."] ~
    "XXXXXXXX" "XXXXXXXX".repeat(12).array ~ [
    "XXXXXXXX" "XXXXXXX.",
    "#XXXXXXX" "XXXXXX..", // '#' = effective coordinate
    "XXXXXXXX" "XXXX....",
]);

private enum _bashNoRelicsLeft  = _bashNoRelicsRight.mirrored;
private enum _bashNoRelicsRight = Mask(
    "XXXXXXXX" "XXXXXXXX".repeat(16).array ~ [
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

struct Mask {

    enum CharOK : char {
        solid       = 'X',
        air         = '.',
        solidOffset = '#',
        airOffset   = 'o'
    }

    int offsetX;
    int offsetY;

    private Matrix!bool _mat;
    const(Matrix!bool) aliasThis() const { return _mat; }
    alias aliasThis this;

    this(in string[] strs)
    in {
        assert (strs.length    > 0, "need at least 1 row");
        assert (strs[0].length > 0, "need at least 1 column");
        assert (strs.all!(a => a.length == strs[0].length),
            "matrix of chars is not rectangular");
    }
    body {
        _mat = new Matrix!bool(strs[0].len, strs.len);
        bool offsetSet = false;
        foreach     (const int y, const string s; strs)
            foreach (const int x, const char   c; s) {
                CharOK cc;
                try cc = std.conv.to!CharOK(c);
                catch (Exception)
                    assert (false, format(
                        "Bad character in string %d, `%s', "
                        "at position %d: `%c'. "
                        "Expected `.', `o', `X', or `#'.",
                        y, s, x, c).idup);
                _mat.set(x, y, cc == CharOK.solid
                            || cc == CharOK.solidOffset);
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

    Mask mirrored() const
    in {
        assert (xl      % 2 == 0, "can't mirror a matrix with odd xl");
        assert (offsetX % 2 == 0, "can't mirror a matrix with odd offsetX");
    }
    body {
        Mask ret;
        ret._mat = new Matrix!bool(xl, yl);
        foreach     (const int y; 0 .. ret._mat.yl)
            foreach (const int x; 0 .. ret._mat.xl)
                ret._mat.set(x, y, this.get(xl - 1 - x, y));
        // Enforce the offset at an even coordinate, because the physics use
        // 2-pixel-wide chunks everywhere, using the left pixel's coordinates.
        ret.offsetX = basics.help.even(xl - 1 - offsetX);
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
    assert (b == a.mirroredWithEvenOffsetX());
}
