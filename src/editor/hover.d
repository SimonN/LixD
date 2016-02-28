module editor.hover;

// Moving and manipulating tile instances (TerPos, GadPos).
// The Hover class hierarchy mimics the hierarchy of Pos and Tile.

// Opportunity for refactoring: Move the hover rectangle drawing all into
// here, so we accept a map. Or accept a visitor from editor.draw.

import std.algorithm;

import basics.alleg5; // timer ticks for the hover
import graphic.color;
import level.level;
import tile.pos;
import tile.gadtile;

abstract class Hover {
    Level  level;
    Reason reason;

    enum Reason { none, mouseInSelbox, mouseOnSolidPixel }

    this(Level l, Reason r)
    in   { assert (l); }
    body { level = l; reason = r; }

    abstract inout(AbstractPos) pos() inout;
    abstract void removeFromLevel();
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
