module level.oil.gadoil;

import std.conv;

import basics.help;
import level.level;
import level.oil.compoil;
import level.oil.oil;
import tile.occur;
import tile.gadtile;

class GadOil : ComparableBase, Oil {
private:
    immutable GadType _type;
    immutable int _id;

public:
    this(in GadType aType, in int aId)
    {
        _type = aType;
        _id = aId;
    }

    inout(GadOcc) occ(inout(Level) level) const pure nothrow @nogc @safe
    {
        assert (_id < level.gadgets[_type].len,
            "can't deref Oil at end of a gadget list");
        return level.gadgets[_type][_id];
    }

    override void insert(Level level, Occurrence occ) const
    {
        /*
         * Hack! Dynamic cast to avoid triple dispatch!
         * (Triple dispatch by Oil, by Occ, and by the contained Tile.)
         */
        auto gadOcc = cast (GadOcc) occ;
        assert (gadOcc, "Type mismatch: GadOil needs a GadOcc");
        insert(level, gadOcc);
    }

    void insert(Level level, GadOcc occ) const
    in {
        assert (occ.tile.type == _type, "Oil: trying to insert wrong GadType");
    }
    do {
        arrInsert(level.gadgets[_type], _id, occ);
    }

    void remove(Level level) const
    {
        arrRemove(level.gadgets[_type], _id);
    }

    void zOrderUntil(Level level, in Oil rhsUncast) const
    {
        /*
         * Same hack as in insertIntoLevel(general Occ).
         */
        auto rhs = cast (const(GadOil)) rhsUncast;
        assert (rhs !is null, "Type mismatch: GadOil must zOrder with GadOil");
        zOrderUntil(level, rhs);
    }

    void zOrderUntil(Level level, const(GadOil) rhs) const
    {
        assert (_type == rhs._type, "GadType mismatch during GadOil zOrdering");
        arrZOrderUntil(level.gadgets[_type], _id, rhs._id);
    }

protected:
    override @property int[2] lexOrd() const @safe pure nothrow @nogc
    {
        int[2] ret = void;
        ret[0] = 2 + 2 * _type.to!int;
        ret[1] = _id;
        return ret;
    }
}
