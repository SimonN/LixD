module editor.hover.terrain;

import std.array;
import std.algorithm;
import std.conv;
import std.exception; // assumeUnique
import std.range;
import std.string;

import basics.help;
import editor.hover.hover;
import file.language;
import graphic.color;
import level.level;
import tile.occur;
import tile.group;

class TerrainHover : Hover {
private:
    TerOcc _occ;

public:
    this(Level l, TerOcc p, Hover.Reason r)
    {
        super(l, r);
        _occ = p;
    }

    static TerrainHover newViaEvilDynamicCast(Level l, TerOcc forThis)
    {
        // There is no subclass of TerOcc for groups
        if (cast (TileGroup) forThis.tile)
            return new GroupHover(l, forThis, Hover.Reason.addedTile);
        return new TerrainHover(l, forThis, Hover.Reason.addedTile);
    }

    override inout(TerOcc) occ() inout { return _occ; }

    override void removeFromLevel()
    {
        level.terrain = level.terrain.remove!(a => a is _occ);
        _occ = null;
    }

    override void cloneThenPointToClone()
    {
        level.terrain ~= _occ.clone();
        _occ = level.terrain[$-1];
    }

    override void zOrderTowardsButIgnore(Hover.FgBg fgbg, in Hover[] ignore)
    {
        zOrderImpl(level.topology, level.terrain, _occ, ignore,
            fgbg, MoveTowards.untilIntersects);
    }

    override void toggleDark()
    {
        assert (_occ);
        _occ.dark = ! _occ.dark;
    }

    override AlCol hoverColor(int val) const
    {
        return color.makecol(val, val, val);
    }

    final override int zOrderAmongAllTiles() const
    {
        return level.terrain.countUntil!"a is b"(_occ).to!int;
    }

protected:
    override void mirrorHorizontally()
    {
        _occ.mirrY = ! _occ.mirrY;
        _occ.rotCw = (2 - _occ.rotCw) & 3;
    }

    override void rotateCw()
    {
        immutable oldCenter = _occ.selboxOnMap.center;
        _occ.rotCw = (_occ.rotCw == 3 ? 0 : _occ.rotCw + 1);
        moveBy(oldCenter - _occ.selboxOnMap.center);
    }

    final override @property string tileDescription() const
    {
        assert (_occ);
        string ret = this.tileName;
        if (_occ.rotCw || _occ.mirrY)
            ret ~= " [%s%s]".format(_occ.mirrY ? "f" : "",
                                    'r'.repeat(_occ.rotCw));
        return ret;
    }

    @property string tileName() const
    {
        return _occ.tile.name;
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
        auto tile = cast (TileGroup) occ().tile;
        assert (tile);
        if (tile.key.elements.len < 2)
            return [ this ];
        TerrainHover moveToOurPosition(TerrainHover ho)
        {
            ho.occ.loc += this.occ.loc - tile.transpCutOff;
            return ho;
        }
        TerrainHover[] newHovers = tile.key.elements
            .map!(e => TerrainHover.newViaEvilDynamicCast(level, e.clone()))
            .map!moveToOurPosition
            .array;
        // Remove this.occ from level, add the >= 2 new occurrences.
        immutable id = level.terrain.countUntil!"a is b"(occ);
        assert (id >= 0);
        level.terrain = level.terrain[0 .. id]
            ~ newHovers.map!(ho => ho.occ).array
            ~ level.terrain[id + 1 .. $];
        // cast is OK because I guarantee that nobody has access
        // to newHovers, except for who reads this returned array.
        return cast(Hover[]) newHovers;
    }

    override AlCol hoverColor(int val) const
    {
        return color.makecol(val/2, val*2/3, val);
    }

protected:
    override @property string tileName() const
    {
        auto tile = cast (TileGroup) occ().tile;
        return "%d%s".format(tile.key.elements.len,
                             Lang.editorBarGroup.transl);
    }
}
