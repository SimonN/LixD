module graphic.gadget.tribelis;

/* _tribes stores Styles, because a style is the key to retrieve tribes.
 * We don't care about PlNrs: those identify players, not Tribes.
 * Tribes can have many players during a team game.
 */

import std.algorithm;

import enumap;

import basics.topology;
import graphic.gadget;
import net.style;
import tile.occur;

class GadgetWithTribeList : Gadget {
private:
    alias This = GadgetWithTribeList;
    Enumap!(Style, bool) _tribeSet;

public:
    mixin (StandardGadgetCtor);
    this(in This rhs)
    {
        super(rhs);
        _tribeSet = rhs._tribeSet;
    }

    override This clone() const { return new This(this); }

    bool hasTribe(in Style st) const pure nothrow @safe @nogc
    {
        return _tribeSet[st];
    }

    void addTribe(in Style st) pure nothrow @safe @nogc
    out { assert (hasTribe(st)); }
    do {
        _tribeSet[st] = true;
    }

    void clearTribes() pure nothrow @safe @nogc
    out {
        assert (! hasTribe(Style.garden));
        assert (! hasTribe(Style.red));
    }
    do { _tribeSet = typeof(_tribeSet).init; }

    const(Enumap!(Style, bool)) tribes() const pure nothrow @safe @nogc
    {
        return _tribeSet;
    }
}
// end class GadgetWithTribeList
