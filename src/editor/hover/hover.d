module editor.hover.hover;

// Hovers appear when you have the mouse over a tile in the editor.
// They point to a Pos in the level, and offer moving, manipulating, deleting.
// The Hover class hierarchy mimics the hierarchy of Pos and Tile.

// Opportunity for refactoring: Move the hover rectangle drawing all into
// here, so we accept a map. Or accept a visitor from editor.draw.

import std.algorithm;
import std.conv;

import basics.alleg5; // timer ticks for the hover
import basics.help;
import basics.topology;
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
    out (ret) { assert (ret.pos); }
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
        return rhs && pos is rhs.pos;
    }

    final void moveBy(in Point p)
    {
        assert (pos);
        pos.point = level.topology.wrap(pos.point + p);
    }

    final void mirrorHorizontallyWithin(in Rect box)
    {
        immutable self = pos.selboxOnMap;
        pos.point.x -= self.x - box.x;
        pos.point.x += box.x + box.xl - self.x - self.xl;
        pos.point = level.topology.wrap(pos.point);
        mirrorHorizontally();
    }

    final void rotateCwWithin(in Rect box)
    {
        rotateCw();
        immutable self = pos.selboxOnMap;
        pos.point = level.topology.wrap(Point(
            box.center.x - (box.center - self.center).y,
            box.center.y + (box.center - self.center).x)
            - self.len/2 - pos.tile.selbox.topLeft);
    }

    final override int opCmp(Object rhsObj) const
    {
        const rhs = cast (const typeof(this)) rhsObj;
        assert (rhs);
        return this.sortedPositionInLevel - rhs.sortedPositionInLevel;
    }

    // This does 3 things:
    // 1. Delete the occ from the level.
    // 2. Put into the level all elements at correct positions.
    // 3. Return a list of the elements.
    Hover[] replaceInLevelWithElements()
    {
        return [ this ];
    }

    abstract inout(Occurrence) pos() inout;
    abstract int sortedPositionInLevel() const;

    abstract void removeFromLevel();
    abstract void cloneThenPointToClone();
    abstract AlCol hoverColor(int val) const;

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
    Topology topology, ref P[] list, P pos,
    in Hover[] ignoreThese, // editor's selection. Don't reorder among these.
    Hover.FgBg fgbg, MoveTowards mt
)   if (is (P : Occurrence))
{
    int we = list.countUntil!"a is b"(pos).to!int;
    assert (we >= 0);
    int adj()
    {
        return (fgbg == Hover.FgBg.fg) ? we + 1 : we - 1;
    }
    while (adj() >= 0 && adj() < list.len) {
        assert (we >= 0 && we < list.len);
        if (ignoreThese.map!(hov => hov.pos).canFind!"a is b"(list[adj()]))
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
