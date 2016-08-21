module editor.hover.hover;

// Hovers appear when you have the mouse over a tile in the editor.
// They point to an Occurrence in the level, and offer moving, manipulating,
// deleting. The Hover class hierarchy mimics the hierarchy of Occ and Tile.

// Opportunity for refactoring: Move the hover rectangle drawing all into
// here, so we accept a map. Or accept a visitor from editor.draw.

import std.algorithm;
import std.conv;
import std.string;

import basics.alleg5; // timer ticks for the hover
import basics.help;
import basics.topology;
import file.language;
import graphic.color;
import level.level;
import tile.occur;

abstract class Hover {
    Level  level;
    Reason reason;

    enum Reason {
        none,
        selectAll,
        frameSpanning,
        addedTile,
        mouseInSelbox,
        mouseOnSolidPixel
    }

    this(Level l, Reason r)
    in   { assert (l); }
    body { level = l; reason = r; }

    static Hover newViaEvilDynamicCast(Level l, Occurrence forThis)
    out (ret) { assert (ret.occ); }
    body {
        import editor.hover.gadget;
        import editor.hover.terrain;
        if (auto h = cast (TerOcc) forThis)
            return TerrainHover.newViaEvilDynamicCast(l, h);
        else if (auto h = cast (GadOcc) forThis)
            return new GadgetHover (l, h, Reason.addedTile);
        assert (false);
    }

    final override bool opEquals(Object rhsObj) const
    {
        auto rhs = cast (typeof(this)) rhsObj;
        return rhs && occ is rhs.occ;
    }

    final void moveBy(in Point p)
    {
        assert (occ);
        occ.loc = level.topology.wrap(occ.loc + p);
    }

    final void mirrorHorizontallyWithin(in Rect box)
    {
        // The box is around all the selboxes, but we move according to our
        // cutbit's box, not according to our selbox. This fixes github #144.
        immutable self = occ.cutbitOnMap;
        occ.loc.x -= self.x - box.x;
        occ.loc.x += box.x + box.xl - self.x - self.xl;
        occ.loc = level.topology.wrap(occ.loc);
        mirrorHorizontally();
    }

    /* A rotation is a movement around the midpoint.
     * After computing the occ's selbox's midpoint and the box's midpoint,
     * we don't need the box anymore.
     */
    final void rotateCwWithin(in Rect box)
    {
        immutable Rect self = occ.selboxOnMap;
        immutable float ourX = self.x + self.xl / 2f;
        immutable float ourY = self.y + self.yl / 2f;
        immutable float aroundX = box.x + box.xl / 2f;
        immutable float aroundY = box.y + box.yl / 2f;
        immutable float boxRoundFix = ((box.xl + box.yl) & 1) ? 0.5 : 0;
        occ.loc = level.topology.wrap(Point(
            roundInt(aroundX + (aroundY - ourY) - self.xl / 2f - boxRoundFix),
            roundInt(aroundY - (aroundX - ourX) - self.yl / 2f - boxRoundFix))
            - occ.selboxOnTile.topLeft);
        rotateCw();
    }

    final override int opCmp(Object rhsObj) const
    {
        const rhs = cast (const typeof(this)) rhsObj;
        assert (rhs);
        return this.zOrderAmongAllTiles - rhs.zOrderAmongAllTiles;
    }

    // This does 3 things:
    // 1. Delete the occ from the level.
    // 2. Put into the level all elements at correct positions.
    // 3. Return a list of the elements.
    Hover[] replaceInLevelWithElements()
    {
        return [ this ];
    }

    abstract inout(Occurrence) occ() inout;
    abstract int zOrderAmongAllTiles() const;

    abstract void removeFromLevel();
    abstract void cloneThenPointToClone();
    abstract AlCol hoverColor(int val) const;
    abstract @property string tileDescription() const;

    enum FgBg { fg, bg }
    abstract void zOrderTowardsButIgnore(FgBg, in Hover[]);

    void toggleDark() { }

protected:
    void mirrorHorizontally() { }
    void rotateCw() { }
}

package:

enum MoveTowards { once, untilIntersects }

// ignoreThese: Editor will pass selection. We shall not reorder among the
// selection. Never reorder the current piece with any from ignoreThese.
// The editor must take responsibility to call this function in correct order:
// Correct order ensures that we can break while (adj() >= 0 ...) when we have
// run into a piece from ignoreThese. This means that the editor must call
// zOrdering for moving to bg on the regularly-ordered list (bg at front,
// fg at back), and call zOrdering for moving to fg on the retro list!
void zOrderImpl(P)(
    Topology topology, ref P[] list, P occ,
    in Hover[] ignoreThese, // editor's selection. Don't reorder among these.
    Hover.FgBg fgbg, MoveTowards mt
)   if (is (P : Occurrence))
{
    int we = list.countUntil!"a is b"(occ).to!int;
    assert (we >= 0);
    int adj()
    {
        return (fgbg == Hover.FgBg.fg) ? we + 1 : we - 1;
    }
    while (adj() >= 0 && adj() < list.len) {
        assert (we >= 0 && we < list.len);
        if (ignoreThese.map!(hov => hov.occ).canFind!"a is b"(list[adj()]))
            break;
        swap(list[we], list[adj]);
        if (mt == MoveTowards.once || topology.rectIntersectsRect(
            list[we].selboxOnMap, list[adj].selboxOnMap)
        ) {
            break;
        }
        we = adj();
    }
}
