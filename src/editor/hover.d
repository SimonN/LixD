module editor.hover;

// Hovers appear when you have the mouse over a tile in the editor.
// They point to a Pos in the level, and offer moving, manipulating, deleting.
// The Hover class hierarchy mimics the hierarchy of Pos and Tile.

// Opportunity for refactoring: Move the hover rectangle drawing all into
// here, so we accept a map. Or accept a visitor from editor.draw.

import std.algorithm;

import basics.alleg5; // timer ticks for the hover
import basics.help;
import basics.rect;
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
        removeFromList(level.terrain, _pos);
        _pos = null;
    }

    override void cloneThenPointToClone()
    {
        _pos = cloneInListReturnsClone(level.terrain, _pos);
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

    override void removeFromLevel()
    {
        assert (_pos);
        assert (_pos.ob);
        removeFromList(level.pos[_pos.ob.type], _pos);
        _pos = null;
    }

    override void cloneThenPointToClone()
    {
        _pos = cloneInListReturnsClone(level.pos[_pos.ob.type], _pos);
    }

    override AlCol hoverColor(int val) const
    {
        return color.makecol(val, val, val/2);
    }
}

private:

void removeFromList(P)(ref P[] list, P pos)
    if (is (P : AbstractPos))
{
    assert (pos);
    auto found = list.find!"a is b"(pos);
    assert (found.length > 0);
    list = list[0 .. $ - found.length] ~ found[1 .. $];
}

P cloneInListReturnsClone(P)(ref P[] list, P pos)
    if (is (P : AbstractPos))
{
    assert (pos);
    auto found = list.find!"a is b"(pos);
    assert (found.length > 0);
    list ~= found[0].clone();
    return list[$-1];
}
