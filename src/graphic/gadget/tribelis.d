module graphic.gadget.tribelis;

/* A tribeID is the array index of a Tribe. This is not a player number (PlNr)!
 * PlNrs are associated with Tribe.Masters, not with Tribes.
 * To resolve tribeIDs into Tribes, the game's current state's dynamic array
 * of tribes is needed.
 */

import std.algorithm;

import basics.help;
import game.state;
import game.tribe;
import graphic.gadget;
import graphic.torbit;
import level.level;

class GadgetWithTribeList : Gadget {

    this(in Torbit tb, in ref Pos levelpos)
    {
        super(tb, levelpos);
    }

    this(in This rhs)
    {
        super(rhs);
        _tribeIDs = rhs._tribeIDs.dup;
    }

    override This clone() const { return new This(this); }

    bool hasTribe(in GameState state, in Tribe t) const
    {
        assert (state);
        assert (_tribeIDs.all!(id => id < state.tribes.len),
            "Gadget has stored unretrievable indices");
        return  _tribeIDs.any!(id => t is state.tribes[id]);
    }

    bool hasTribe(in int i) const
    {
        return _tribeIDs.find(i) != null;
    }

    void addTribe(GameState state, Tribe t)
    {
        assert (state);
        if (hasTribe(state, t))
            return;
        auto findResult = state.tribes.find!(a => a is t);
        assert (findResult.len > 0);
        _tribeIDs ~= state.tribes.len - findResult.len;
    }

    void addTribe(in int i)
    {
        if (! hasTribe(i))
            _tribeIDs ~= i;
    }

    void clearTribes()
    {
        _tribeIDs = null;
    }

    @property auto tribes(GameState state)
    {
        assert (state);
        return TribeRange!(This, GameState)(this, state);
    }

    @property auto tribes(const(GameState) state) const
    {
        assert (state);
        return TribeRange!(const(This), const(GameState))(this, state);
    }

    // override this
    void drawStateExtras(Torbit, in GameState) { }

private:

    private alias This = GadgetWithTribeList;
    int[] _tribeIDs;

    auto ref resolve(inout(GameState) state, in int id) inout
    {
        assert (state);
        assert (_tribeIDs.all!(id => id < state.tribes.len),
            "Gadget can't resolve IDs in the provided state.tribes");
        return state.tribes[_tribeIDs[id]];
    }

    static struct TribeRange(T, S)
        if (is (T : const(This))
         && is (S : const(GameState)))
    {
        T gad;
        S state;
        int id;

        static assert (
            is (T == This) && is (S == GameState) ||
            is (T == const(This)) && is (S == const(GameState))
        );

        @property bool empty() const
        {
            assert (gad);
            return id < gad._tribeIDs.len;
        }

        @property auto length() const { return gad._tribeIDs.length - id; }
        @property auto len()    const { return gad._tribeIDs.len    - id; }

        @property auto ref front() inout
        {
            assert (!empty);
            return gad.resolve(state, id);
        }

        @property void popFront()
        {
            assert (!empty);
            ++id;
        }
    }
    // end struct TribeRange
}
// end class GadgetWithTribeList
