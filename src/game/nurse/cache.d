module game.nurse.cache;

/* PhysicsCache (former name: StateManager) holds many states, and knows when
 * to auto-save. Feed the StateManager with the current state all the time,
 * feed to function autoSave(). That will nop often.
 */

import std.algorithm;
import std.range;
import std.string;
import std.typecons;

import basics.alleg5 : OutOfVramException;
import basics.globals : levelPixelsToWarn;
import basics.help; // clone(T[]), a deep copy for arrays
import file.replay;
import file.log;
import hardware.tharsis;
import net.repdata;
import physics.state;

enum DuringTurbo : bool { no = false, yes = true }

class PhysicsCache {

private:

    enum updatesMostFrequentPair = 10;
    enum updatesMultiplierNextPairIsSlowerBy = 5; // 10, 50, 250, 1250
    enum pairsToKeep = 4;

    GameState _zero;
    GameState _userState;
    GameState[2 * pairsToKeep] _auto;

    // For the user-triggered save (_user), remember the replay that was
    // correct by then. Otherwise, the user could restart, do something
    // deviating, and then load the user state that supposes the old,
    // differing replay.
    Replay _userReplay;
    bool _recommendGC; // because we don't call the GC ourselves

public:
    void dispose()
    {
        destroy(_zero);
        destroy(_userState);
        forgetAutoSavesOnAndAfter(Phyu(0));
        assert (! _auto[0].refCountedStore.isInitialized);
    }

    void considerGC() nothrow
    {
        if (! _recommendGC)
            return;
        _recommendGC = false;

        import core.memory;
        GC.collect();
        GC.minimize();
    }

    // This throws if we can't allocate VRAM for the zero state.
    // Letting that exception fly out of main is fine for the zero state.
    void saveZero(in GameState s) { _zero = s.clone(); }

    @property Phyu zeroStatePhyu() const {
        assert (_zero.refCountedStore.isInitialized);
        return _zero.update;
    }

    void saveUser(in GameState s, in Replay r)
    {
        try {
            if (_userState.refCountedStore.isInitialized)
                _recommendGC = true;
            assert (r);
            _userState = s.clone();
            _userReplay = r.clone();
        }
        catch (OutOfVramException e)
            log(e.msg);
    }

    bool userStateExists() const @nogc nothrow
    out (ret) {
        assert (ret == _userState.refCountedStore.isInitialized,
            "Bad user savestate: We have a replay XOR we have state");
    }
    body {
        return _userReplay !is null;
    }

    // Depending on mismatches between Nurse's replay and our saved replay,
    // some cached states must be invalidated. Fixes user-stateload desyncs.
    // See inner struct for the many return values.
    auto loadUser(in Replay nurseReplay, in Phyu wantEqualBefore)
    in {
        assert (userStateExists, "don't load if there is nothing to load");
        assert (nurseReplay, "need reference so I know what to invalidate");
    }
    body {
        forgetAutoSavesOnAndAfter(Phyu(0));
        /+
         + Anything here but the line above is instead speed optimization.
         + Make the thing correct first, then fast!
         +
        // Different 'before' than in SaveStatingNurse; see her comment too.
        immutable before = min(wantEqualBefore, Phyu(_userState.update + 1));
        forgetAutoSavesOnAndAfter(nurseReplay.equalBefore(_userReplay, before)
            ? before : Phyu(0));
         +/
        struct Ret {
            const(GameState) state;
            const(Replay) replay;
        }
        return Ret(_userState, _userReplay);
    }

    const(GameState) loadBeforePhyu(in Phyu u)
    {
        GameState ret = _zero;
        foreach (gs; _auto)
            if (   gs.refCountedStore.isInitialized
                && gs.update < u && gs.update > ret.update)
                ret = gs;
        forgetAutoSavesOnAndAfter(u);
        return ret;
    }

    bool wouldAutoSave(
        in GameState s,
        in Phyu updTo,
        in DuringTurbo duringTurbo) const
    {
        immutable pair = duringTurbo ? 1 : 0;
        assert (pair >= 0 && pair < pairsToKeep);
        if (s.update == 0 || s.update % updateMultipleForPair(pair) != 0)
            return false;
        foreach (possible; pair .. pairsToKeep)
            // We save 2 states per update multiple. But when we want to update
            // 100 times, there is no need saving states after 10, 20, 30, ...
            // updates, we would only keep the states at 90 and 100, anyway.
            // And the state at 50 and 100, in a higher pair.
            if (s.update > updTo - 2 * updateMultipleForPair(possible)
                && s.update % updateMultipleForPair(possible) == 0)
                return true;
        return false;
    }

    void autoSave(in GameState s, in Phyu ultimatelyTo)
    {
        if (! wouldAutoSave(s, ultimatelyTo, DuringTurbo.no))
            return;
        _recommendGC = true;
        // For large maps, don't save the final pair. This is a feeble attempt
        // at conserving RAM. See github issue 296 about RAM on Windows:
        // https://github.com/SimonN/LixD/issues/296
        static assert (pairsToKeep >= 2);
        immutable int pairsToKeepForThisMap = s.land.xl * s.land.yl
            > levelPixelsToWarn ? pairsToKeep - 1 : pairsToKeep;

        // Potentially push older auto-saved states down the hierarchy.
        // First, if it's time to copy a frequent state into a less frequent
        // state, make these copies. Start with least frequent copying the
        // second-to-least freqent.
        // After copying the internal states like that, save s into the most
        // frequently updated pair. The most frequently updated pair has
        // array indices 0 and 1. The next one has array indices 2 and 3, ...
        for (int pair = pairsToKeepForThisMap - 1; pair >= 0; --pair) {
            immutable int umfp = updateMultipleForPair(pair);
            if (s.update % umfp != 0)
                continue;

            int whichOfPair = (s.update / umfp) % 2;
            if (pair > 0)
                // Make a shallow copy of the more-frequently-hit state:
                // We treat states inside PhysicsCache like immutable.
                // Only clone when we return to outside of PhysicsCache.
                _auto[2*pair + whichOfPair] = _auto[2*(pair-1)];
            else {
                try {
                    _auto[0 + whichOfPair] = s.clone(); // deep copy of current
                }
                catch (OutOfVramException e) {
                    _auto[0 + whichOfPair] = GameState.init;
                    log(e.msg);
                }
            }
        }
    }

private:
    void forgetAutoSavesOnAndAfter(in Phyu u)
    {
        foreach (ref GameState gs; _auto)
            if (gs.refCountedStore.isInitialized && (u <= 0 || gs.update >= u))
                destroy(gs);
        _recommendGC = true;
    }

    int updateMultipleForPair(in int pair) const pure @nogc
    in { assert (pair >= 0 && pair < pairsToKeep); }
    body {
        return updatesMostFrequentPair
            * updatesMultiplierNextPairIsSlowerBy^^pair;
    }
}
// end class StateManager
