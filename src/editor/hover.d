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
import tile.pos;
import tile.gadtile;

abstract class Hover {
    Level  level;
    Reason reason;

    enum Reason {
        none,
        selectAll,
        frameSpanning,
        addedFromBrowser,
        mouseInSelbox,
        mouseOnSolidPixel
    }

    this(Level l, Reason r)
    in   { assert (l); }
    body { level = l; reason = r; }

    static Hover newViaEvilDynamicCast(Level l, AbstractPos forThis)
    {
        assert (forThis);
        if (auto h = cast (TerPos) forThis)
            return new TerrainHover(l, h, Reason.addedFromBrowser);
        else if (auto h = cast (GadPos) forThis)
            return new GadgetHover(l, h, Reason.addedFromBrowser);
        assert (false);
    }

    final override bool opEquals(Object rhsObj) const
    {
        auto rhs = cast (typeof(this)) rhsObj;
        return rhs && pos is rhs.pos;
    }

    final override int opCmp(Object rhsObj) const
    {
        const rhs = cast (typeof(this)) rhsObj;
        const cmp = cast (void*) pos - cast (void*) rhs.pos;
        return cmp < 0 ? -1 : cmp > 0 ? 1 : 0;
    }

    final void moveBy(in Point p)
    {
        assert (pos);
        pos.point = level.topology.wrap(pos.point + p);
    }

    abstract inout(AbstractPos) pos() inout;
    abstract void removeFromLevel();
    abstract void cloneThenPointToClone();
    abstract AlCol hoverColor(int val) const;

    enum FgBg { fg, bg }
    abstract void moveTowards(FgBg);
}

class TerrainHover : Hover {
private:
    TerPos _pos;

public:
    this(Level l, TerPos p, Hover.Reason r)
    {
        super(l, r);
        _pos = p;
    }

    override inout(TerPos) pos() inout { return _pos; }

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

    override void moveTowards(Hover.FgBg fgbg)
    {
        moveTowardsImpl(level.topology, level.terrain, _pos, fgbg,
                        MoveTowards.untilIntersects);
    }
    override AlCol hoverColor(int val) const
    {
        return color.makecol(val, val, val);
    }
}

class GadgetHover : Hover {
private:
    GadPos _pos;

public:
    this(Level l, GadPos p, Hover.Reason r)
    {
        super(l, r);
        _pos = p;
    }

    override inout(GadPos) pos() inout { return _pos; }

    ref inout(GadPos[]) list() inout
    {
        assert (_pos);
        assert (_pos.ob);
        return level.pos[_pos.ob.type];
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

    override void moveTowards(Hover.FgBg fgbg)
    {
        moveTowardsImpl(level.topology, list, _pos, fgbg,
            (pos.ob.type == GadType.HATCH || pos.ob.type == GadType.GOAL)
            ? MoveTowards.once : MoveTowards.untilIntersects);
    }

    override AlCol hoverColor(int val) const
    {
        return color.makecol(val, val, val/2);
    }
}

private:

enum MoveTowards { once, untilIntersects }

void moveTowardsImpl(P)(
    Topology topology, ref P[] list, P pos, Hover.FgBg fgbg, MoveTowards mt
)   if (is (P : AbstractPos))
{
    int we = list.countUntil!"a is b"(pos).to!int;
    assert (we >= 0);
    int adj()
    {
        return (fgbg == Hover.FgBg.fg) ? we + 1 : we - 1;
    }
    while (adj() >= 0 && adj() < list.len) {
        assert (we >= 0 && we < list.len);
        swap(list[we], list[adj]);
        if (mt == MoveTowards.once || topology.rectIntersectsRect(
            list[we].selboxOnMap, list[adj].selboxOnMap)
        ) {
            break;
        }
        we = adj();
    }
}
