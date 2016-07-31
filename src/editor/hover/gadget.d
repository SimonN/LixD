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
    GadOcc _occ;

public:
    this(Level l, GadOcc p, Hover.Reason r)
    {
        super(l, r);
        _occ = p;
    }

    override inout(GadOcc) occ() inout { return _occ; }

    ref inout(GadOcc[]) list() inout
    {
        assert (_occ);
        assert (_occ.tile);
        return level.gadgets[_occ.tile.type];
    }

    override void removeFromLevel()
    {
        list = list.remove!(a => a is _occ);
        _occ = null;
    }

    override void cloneThenPointToClone()
    {
        list ~= _occ.clone();
        _occ = list[$-1];
    }

    override void zOrderTowardsButIgnore(Hover.FgBg fgbg, in Hover[] ignore)
    {
        zOrderImpl(level.topology, list, _occ, ignore, fgbg,
            (occ.tile.type == GadType.HATCH || occ.tile.type == GadType.GOAL)
            ? MoveTowards.once : MoveTowards.untilIntersects);
    }

    override AlCol hoverColor(int val) const
    {
        return color.makecol(val, val, val/2);
    }

    final override int zOrderAmongAllTiles() const
    {
        assert (occ);
        return level.terrain.len
            + level.gadgets[0 .. occ.tile.type].map!(vec => vec.len).sum
            + level.gadgets[occ.tile.type].countUntil!"a is b"(occ).to!int;
    }

    override @property string tileDescription() const
    {
        return _occ.tile.name;
    }

protected:
    override void rotateCw() { mirrorHorizontally(); }
    override void mirrorHorizontally()
    {
        _occ.hatchRot = (_occ.tile.type == GadType.HATCH && ! _occ.hatchRot);
    }
}
