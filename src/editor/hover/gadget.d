module editor.hover.gadget;

import std.algorithm;
import std.conv;

import basics.help; // len
import editor.hover.hover;
import graphic.color;
import level.level;
import tile.gadtile;
import tile.occur;

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

    final override int sortedPositionInLevel() const
    {
        assert (pos);
        return level.terrain.len
            + level.pos[0 .. pos.tile.type].map!(vec => vec.len).sum
            + level.pos[pos.tile.type].countUntil!"a is b"(pos).to!int;
    }

protected:
    override void rotateCw() { mirrorHorizontally(); }
    override void mirrorHorizontally()
    {
        _pos.hatchRot = (_pos.tile.type == GadType.HATCH && ! _pos.hatchRot);
    }

    override @property string tileDescription() const
    {
        return _pos.tile.name;
    }
}
