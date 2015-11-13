module game.state;

/* A gamestate. It saves everything about the current position, but not
 * how we got here. The class Replay saves everything about the history,
 * so you can reconstruct the current state from the beginning gamestate and
 * a replay.
 *
 * StateManager holds many states, and knows when to auto-save.
 * Feed the StateManager with the current state all the time, it will do
 * nothing most of the time with the state fed.
 */

import basics.help; // clone(T[]), a deep copy for arrays
import game;
import graphic.torbit;
import graphic.gadget;

import std.string : format;

class GameState {

    int  update;
    int  clock;
    bool clockIsRunning;

    private bool _goalsLocked; // in singleplayer, when time has run out

    Tribe[] tribes;

    Hatch[] hatches;
    Goal[] goals;
    Gadget[] decos;
    Water[] waters;
    TrapTrig[] traps;
    Flinger[] flingers;
    Trampoline[] trampolines;

    Torbit land;
    Lookup lookup;

    this() { }

    this(in GameState rhs)
    {
        assert (rhs, "don't copy-construct from a null GameState");
        assert (rhs.land, "don't copy-construct from GameState without land");
        update         = rhs.update;
        clock          = rhs.clock;
        clockIsRunning = rhs.clockIsRunning;
        _goalsLocked   = rhs._goalsLocked;

        tribes      = rhs.tribes     .clone;
        hatches     = rhs.hatches    .clone;
        goals       = rhs.goals      .clone;
        decos       = rhs.decos      .clone;
        waters      = rhs.waters     .clone;
        traps       = rhs.traps      .clone;
        flingers    = rhs.flingers   .clone;
        trampolines = rhs.trampolines.clone;

        land   = new Torbit(rhs.land);
        lookup = new Lookup(rhs.lookup);
    }

    GameState clone() const { return new GameState(this); }

    @property bool goalsLocked() const { return _goalsLocked; }
    @property bool goalsLocked(in bool b)
    {
        _goalsLocked = b;
        foreach (goal; goals)
            goal.drawWithNoSign = _goalsLocked;
        return _goalsLocked;
    }

    void foreachGadget(void delegate(Gadget) func)
    {
        foreach (g; hatches)     func(g);
        foreach (g; goals)       func(g);
        foreach (g; decos)       func(g);
        foreach (g; waters)      func(g);
        foreach (g; traps)       func(g);
        foreach (g; flingers)    func(g);
        foreach (g; trampolines) func(g);
    }

}



// ############################################################################
// ############################################################################
// ############################################################################



class StateManager {

private:

    enum updatesMostFrequentPair = 10;
    enum updatesMultiplierNextPairIsSlowerBy = 5; // 10, 50, 250, 1250
    enum pairsToKeep = 4;

    GameState _zero, _userState;
    GameState[2 * pairsToKeep] _auto;

    // For the user-triggered save (_user), remember the replay that was
    // correct by then. Otherwise, the user could restart, do something
    // deviating, and then load the user state that supposes the old,
    // differing replay.
    Replay _userReplay;

    invariant()
    {
        if (_zero)
            assert(_zero.update == 0,
                format("_zero.update is %d instead of 0", _zero.update));
    }

public:

    void saveZero(GameState s) { _zero = s.clone(); }

    void saveUser(GameState s, Replay r)
    {
        _userState  = s.clone();
        _userReplay = r.clone();
    }

    @property inout(GameState) zeroState()  inout { return _zero;       }
    @property inout(GameState) userState()  inout { return _userState;  }
    @property inout(Replay)    userReplay() inout { return _userReplay; }

    GameState autoBeforeUpdate(in int u)
    {
        assert (zeroState, "need _zero as a fallback for autoBeforeUpdate");
        GameState ret = _zero;
        foreach (ref GameState candidate; _auto)
            if (   candidate !is null
                && candidate.update < u
                && candidate.update > ret.update
            ) {
                ret = candidate;
            }

        foreach (ref GameState possibleGarbage; _auto)
            if (possibleGarbage && possibleGarbage.update >= u)
                // DTODO: find out whether we should manually destroy the
                // torbit and lookup matrix here, and then garbage-collect
                possibleGarbage = null;

        return ret;
    }

    // Examine the number of updates in s, then decide what to do with s:
    // Auto-save this state s, potentially pushing older auto-saved states
    // down the hierarchy, or do nothing.
    void calcSaveAuto(GameState s)
    {
        assert (s);
        if (s.update < updatesMostFrequentPair)
            return;
        // First, make the largest copy the second-largest, and so on.
        // Finally save s into the most frequently updated pair. The most
        // frequently updated pair has array indices 0 and 1. The next one
        // has array indices 2 and 3, and so on.
        for (int pair = pairsToKeep - 1; pair >= 0; --pair) {
            int updateMultipleForPair = updatesMostFrequentPair;
            foreach (i; 0 .. pair)
                updateMultipleForPair *= updatesMultiplierNextPairIsSlowerBy;
            if (s.update % updateMultipleForPair == 0) {
                int whichOfPair = (s.update / updateMultipleForPair) % 2;
                if (pair > 0) {
                    // make a shallow copy, because we treat states inside
                    // the save manager like immutable data. If the thing
                    // to copy is null, don't copy it, because we might
                    // currently hold good data that is old, and the newer
                    // data to copy was set to null because it's a wrong
                    // timeline.
                    GameState moreFrequentToCopy = _auto[2*(pair-1)];
                    if (moreFrequentToCopy is null)
                        moreFrequentToCopy = _auto[2*(pair-1) + 1];
                    if (moreFrequentToCopy !is null)
                        _auto[2*pair + whichOfPair] = moreFrequentToCopy;
                }
                else {
                    // make a hard copy of the current state
                    _auto[0 + whichOfPair] = s.clone();
                }
            }
        }
    }
    // end function calcSaveAuto
}
// end class StateManager
