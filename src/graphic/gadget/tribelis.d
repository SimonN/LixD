module graphic.gadget.tribelis;

/* _tribes stores Styles, because a style is the key to retrieve tribes.
 * We don't care about PlNrs: those identify players, not Tribes.
 * Tribes can have many players during a team game.
 */

import std.algorithm;

import basics.topology;
import graphic.gadget;
import net.style;
import tile.occur;

class GadgetWithTribeList : Gadget {
private:
    alias This = GadgetWithTribeList;
    Style[] _tribes;

public:
    mixin (StandardGadgetCtor);
    this(in This rhs)
    {
        super(rhs);
        _tribes = rhs._tribes.dup;
    }

    override This clone() const { return new This(this); }

    bool hasTribe(in Style st) const { return _tribes.canFind(st); }
    void addTribe(in Style st)
    {
        if (hasTribe(st))
            return;
        _tribes ~= st;
        _tribes.sort();
    }

    void clearTribes() { _tribes = []; }
    @property inout(Style[]) tribes() inout { return _tribes; }
}
// end class GadgetWithTribeList
