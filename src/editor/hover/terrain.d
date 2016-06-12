module editor.hover.terrain;

import std.array;
import std.algorithm;
import std.conv;
import std.range;
import std.exception; // assumeUnique

import basics.help;
import editor.hover.hover;
import graphic.color;
import level.level;
import tile.occur;
import tile.group;

class TerrainHover : Hover {
private:
    TerOcc _pos;

public:
    this(Level l, TerOcc p, Hover.Reason r)
    {
        super(l, r);
        _pos = p;
    }

    static TerrainHover newViaEvilDynamicCast(Level l, TerOcc forThis)
    {
        // There is no subclass of TerOcc for groups
        if (cast (TileGroup) forThis.tile)
            return new GroupHover(l, forThis, Hover.Reason.addedTile);
        return new TerrainHover(l, forThis, Hover.Reason.addedTile);
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

    final override int sortedPositionInLevel() const
    {
        return level.terrain.countUntil!"a is b"(this.pos).to!int;
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

class GroupHover : TerrainHover {
    this(Level l, TerOcc p, Hover.Reason r)
    {
        assert (p);
        assert (cast (TileGroup) p.tile);
        super(l, p, r);
    }

    override Hover[] replaceInLevelWithElements()
    {
        auto tile = cast (TileGroup) pos().tile;
        assert (tile);
        if (tile.key.elements.len < 2)
            return [ this ];
        TerrainHover moveToOurPosition(TerrainHover ho)
        {
            ho.pos.point += this.pos.point - tile.transpCutOff;
            return ho;
        }
        TerrainHover[] newHovers = tile.key.elements
            .map!(e => TerrainHover.newViaEvilDynamicCast(level, e.clone()))
            .map!moveToOurPosition
            .array;
        // Remove this.pos from level, add the >= 2 new posses.
        immutable id = level.terrain.countUntil!"a is b"(pos);
        assert (id >= 0);
        level.terrain = level.terrain[0 .. id]
            ~ newHovers.map!(ho => ho.pos).array
            ~ level.terrain[id + 1 .. $];
        // cast is OK because I guarantee that nobody has access
        // to newHovers, except for who reads this returned array.
        return cast(Hover[]) newHovers;
    }

    override AlCol hoverColor(int val) const
    {
        return color.makecol(val/2, val*2/3, val);
    }
}
