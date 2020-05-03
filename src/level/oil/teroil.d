module level.oil.teroil;

import std.conv;

import basics.help;
import level.level;
import level.oil.compoil;
import level.oil.oil;
import tile.occur;

class TerOil : ComparableBase, Oil {
private:
    immutable int _id;

public:
    this(in int aId)
    {
        _id = aId;
    }

    inout(TerOcc) occ(inout(Level) level) const pure nothrow @nogc @safe
    {
        assert (_id < level.terrain.len,
            "can't deref Oil at end of terrain");
        return level.terrain[_id];
    }

    override void insert(Level level, Occurrence occ) const
    {
        /*
         * Hack! Dynamic cast to avoid triple dispatch!
         * (Triple dispatch by Oil, by Occ, and by the contained Tile.)
         */
        TerOcc terOcc = cast (TerOcc) occ;
        assert (terOcc, "Type mismatch: TerOil needs a TerOcc");
        insert(level, terOcc);
    }

    void insert(Level level, TerOcc occ) const
    {
        arrInsert(level.terrain, _id, occ);
    }

    void remove(Level level) const
    {
        arrRemove(level.terrain, _id);
    }

    void zOrderUntil(Level level, in Oil rhsUncast) const
    {
        /*
         * Same hack as in insertIntoLevel(general Occ).
         */
        auto rhs = cast (const(TerOil)) rhsUncast;
        assert (rhs !is null, "Type mismatch: TerOil must zOrder with TerOil");
        zOrderUntil(level, rhs);
    }

    void zOrderUntil(Level level, in TerOil rhs) const
    {
        arrZOrderUntil(level.terrain, _id, rhs._id);
    }

protected:
    override @property int[2] lexOrd() const @safe pure nothrow @nogc
    {
        int[2] ret = void;
        ret[0] = 0;
        ret[1] = _id;
        return ret;
    }
}
