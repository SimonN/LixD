module level.oil.oil;

/*
 * Oil = O.i.l. = Occurence in list
 *                ^         ^  ^
 * The editor needs to remember occurrences and their positions even after
 * they're deleted from the level's arrays ([] terrain or [][] gadget).
 * Oil was introduced to implement the editor's undo feature.
 *
 * Oil specifies a position in these lists.
 * Oil is invalidated when elements before the specified position are removed.
 *
 * Oil can be treated as head-immutable.
 * You don't need to deep-copy an Oil; you can point to the same instance.
 */

import std.conv;

import basics.help;
import level.level;
import level.oil.compoil;
import level.oil.gadoil;
import level.oil.teroil;
import tile.occur;
import tile.visitor;

interface Oil {
    // The occ at the explic. remembered position.
    inout(Occurrence) occ(inout(Level)) const @safe pure nothrow @nogc;

    void insert(Level, Occurrence) const;
    void remove(Level) const;
    void zOrderUntil(Level, in Oil) const;

    /*
     * Hack for OilSet.
     * Even though all interface instances are classes and thus have opCmp
     * and we also implement opCmp in oil.ComparableBase for this,
     * OilSet doesn't want "a < b" as comparator for an interface.
     */
    final bool appearsBefore(const(Oil) rhs) const pure nothrow @nogc
    {
        return cast(const ComparableBase) this < cast(Object) rhs;
    }

    static Oil makeViaLookup(in Level lev, const(Occurrence) occ)
    {
        foreach (size_t id, const(TerOcc) t; lev.terrain) {
            if (t is occ) {
                return new TerOil(id.to!int);
            }
        }
        foreach (arr; lev.gadgets) {
            foreach (size_t id, const(GadOcc) g; arr) {
                if (g is occ) {
                    return new GadOil(g.tile.type, id.to!int);
                }
            }
        }
        assert (false, "Lookup of Occurrence that doesn't exist in the level");
    }

    static Oil makeAtEndOfList(in Level aLevel, const(AbstractTile) tile)
    {
        Oil ret;
        tile.accept(new class TileVisitor {
            void visit(const(TileGroup) gr)
            {
                ret = new TerOil(aLevel.terrain.len);
            }
            void visit(const(TerrainTile))
            {
                ret = new TerOil(aLevel.terrain.len);
            }
            void visit(const(GadgetTile) ga)
            {
                ret = new GadOil(ga.type, aLevel.gadgets[ga.type].len);
            }
        });
        return ret;
    }
}
