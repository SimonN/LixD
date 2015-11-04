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
    GadgetCanBeOpen[] flingers;
    Trampoline[] trampolines;

    Torbit land;
    Lookup lookup;

    this() { }

    this(GameState rhs)
    {
        assert (rhs, "don't copy-construct from a null GameState");
        assert (rhs.land, "don't copy-construct from GameState without land");
        update         = rhs.update;
        clock          = rhs.clock;
        clockIsRunning = rhs.clockIsRunning;
        _goalsLocked   = rhs._goalsLocked;
        tribes      = tribes     .clone;
        hatches     = hatches    .clone;
        goals       = goals      .clone;
        decos       = decos      .clone;
        waters      = waters     .clone;
        traps       = traps      .clone;
        flingers    = flingers   .clone;
        trampolines = trampolines.clone;

        land   = new Torbit(rhs.land);
        lookup = new Lookup(rhs.lookup);
    }

    mixin CloneableBase;

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

    GameState _zero, _user;
    GameState[2 * pairsToKeep] _auto;

    // For the user-triggered save (_user), remember the replay that was
    // correct by then. Otherwise, the user could restart, do something
    // deviating, and then load the user state that supposes the old,
    // differing replay.
    Replay _userReplay;

public:

    void saveZero(GameState s) { _zero = s; }
    void saveUser(GameState s, Replay r) { _user = s; _userReplay = r; }

    @property inout(GameState) zero()       inout { return _zero;       }
    @property inout(GameState) user()       inout { return _user;       }
    @property inout(Replay)    userReplay() inout { return _userReplay; }

    GameState autoBeforeUpdate(in int u)
    {
        GameState ret = _zero;
        foreach (ref GameState candidate; _auto)
            if (candidate !is null && candidate.update < u) {
                ret = candidate;
                break;
            }

        foreach (ref GameState possibleGarbage; _auto)
            if (possibleGarbage && possibleGarbage.update >= ret.update)
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
                    if (_auto[2*(pair-1)] !is null)
                        _auto[2*pair + whichOfPair] = _auto[2*(pair-1)];
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
