module editor.hover;

// Hovers appear when you have the mouse over a tile in the editor.
// They point to a Pos in the level, and offer moving, manipulating, deleting.
// The Hover class hierarchy mimics the hierarchy of Pos and Tile.

// Opportunity for refactoring: Move the hover rectangle drawing all into
// here, so we accept a map. Or accept a visitor from editor.draw.

import std.algorithm;
import std.conv;

import basics.alleg5; // timer ticks for the hover
import basics.help;
import basics.rect;
import basics.topology;
import graphic.color;
import level.level;
import tile.occur;
import tile.gadtile;

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
    {
        assert (forThis);
        if (auto h = cast (TerOcc) forThis)
            return new TerrainHover(l, h, Reason.addedTile);
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

    abstract inout(Occurrence) pos() inout;
    abstract void removeFromLevel();
    abstract void cloneThenPointToClone();
    abstract AlCol hoverColor(int val) const;

    enum FgBg { fg, bg }
    abstract void zOrderTowardsButIgnore(FgBg, in Hover[]);

    // Override opCmp, such that all gadget hovers sort before all
    // terrain hovers. Within each class, sort like level does.
    abstract override int opCmp(Object rhsObj);

    void toggleDark() { }

protected:
    void mirrorHorizontally() { }
    void rotateCw() { }
}

class TerrainHover : Hover {
private:
    TerOcc _pos;

public:
    this(Level l, TerOcc p, Hover.Reason r)
    {
        super(l, r);
        _pos = p;
    }

    override inout(TerOcc) pos() inout { return _pos; }

    override void removeFromLevel()
    {
        level.terrain = level.terrain.remove!(a => a is pos);
        _pos = null;
    }

    override void cloneThenPointToClone()
    {
        level.terrain ~= pos.clone();
        _pos = level.terrain[$-1];
    }

    override void zOrderTowardsButIgnore(Hover.FgBg fgbg, in Hover[] ignore)
    {
        zOrderImpl(level.topology, level.terrain, _pos, ignore,
            fgbg, MoveTowards.untilIntersects);
    }

    override void toggleDark()
    {
        assert (_pos);
        _pos.dark = ! _pos.dark;
    }

    override AlCol hoverColor(int val) const
    {
        return color.makecol(val, val, val);
    }

    final override int opCmp(Object rhsObj) const
    {
        if (cast (GadgetHover) rhsObj)
            return 1; // Terrain sorts after Gadget, see comment in super
        else if (auto rhs = cast (TerrainHover) rhsObj)
            return level.terrain.countUntil!"a is b"(this.pos).to!int
                -  level.terrain.countUntil!"a is b"(rhs .pos).to!int;
        else
            assert (false, "add extra classes here, this violates OCP. :-(");
    }

protected:
    override void mirrorHorizontally()
    {
        _pos.mirrY = ! _pos.mirrY;
        _pos.rotCw = (2 - _pos.rotCw) & 3;
    }

    override void rotateCw()
    {
        immutable oldCenter = _pos.selboxOnMap.center;
        _pos.rotCw = (_pos.rotCw == 3 ? 0 : _pos.rotCw + 1);
        moveBy(oldCenter - _pos.selboxOnMap.center);
    }
}

class GadgetHover : Hover {
private:
    GadOcc _pos;

public:
    this(Level l, GadOcc p, Hover.Reason r)
    {
        super(l, r);
        _pos = p;
    }

    override inout(GadOcc) pos() inout { return _pos; }

    ref inout(GadOcc[]) list() inout
    {
        assert (_pos);
        assert (_pos.tile);
        return level.pos[_pos.tile.type];
    }

    override void removeFromLevel()
    {
        list = list.remove!(a => a is pos);
        _pos = null;
    }

    override void cloneThenPointToClone()
    {
        list ~= pos.clone();
        _pos = list[$-1];
    }

    override void zOrderTowardsButIgnore(Hover.FgBg fgbg, in Hover[] ignore)
    {
        zOrderImpl(level.topology, list, _pos, ignore, fgbg,
            (pos.tile.type == GadType.HATCH || pos.tile.type == GadType.GOAL)
            ? MoveTowards.once : MoveTowards.untilIntersects);
    }

    override AlCol hoverColor(int val) const
    {
        return color.makecol(val, val, val/2);
    }

    final override int opCmp(Object rhsObj) const
    {
        if (cast (TerrainHover) rhsObj)
            return -1; // Gadget sorts before Terrain, see comment in super
        else if (auto rhs = cast (GadgetHover) rhsObj) {
            if (this.pos.tile.type != rhs.pos.tile.type)
                return this.pos.tile.type.to!int - rhs.pos.tile.type.to!int;
            else {
                auto list = level.pos[this.pos.tile.type];
                return list.countUntil!"a is b"(this.pos).to!int
                    -  list.countUntil!"a is b"(rhs .pos).to!int;
            }
        }
        else
            assert (false, "add extra classes here, this violates OCP. :-(");
    }

protected:
    override void rotateCw() { mirrorHorizontally(); }
    override void mirrorHorizontally()
    {
        _pos.hatchRot = (_pos.tile.type == GadType.HATCH && ! _pos.hatchRot);
    }
}

private:

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
