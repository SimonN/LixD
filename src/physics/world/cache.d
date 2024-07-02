module physics.world.cache;

/* PhysicsCache (former name: StateManager) holds many states, and knows when
 * to auto-save. Feed the StateManager with the current state all the time,
 * feed to function autoSave(). That will nop often.
 */

import std.algorithm;
import std.range;
import std.string;

import basics.alleg5 : OutOfVramException;
import basics.globals : levelPixelsToWarn;
import file.replay;
import net.repdata;
import physics.world.world;

enum DuringTurbo : bool { no = false, yes = true }

class PhysicsCache {
private:
    enum pairsToKeep = 4;

    MutableHalfOfWorld _zero; // for returning to the beginning
    MutableHalfOfWorld _userState; // for savestating
    MutableHalfOfWorld[2 * pairsToKeep] _auto;

    // For the user-triggered save (_user), remember the replay that was
    // correct by then. Otherwise, the user could restart, do something
    // deviating, and then load the user state that supposes the old,
    // differing replay.
    Replay _userReplay;
    bool _recommendGC; // because we don't call the GC ourselves

public:
    void dispose()
    {
        _zero.dispose();
        _userState.dispose();
        forgetAutoSavesOnAndAfter(Phyu(0));
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

    // Internally, this creates a deep copy.
    // This throws if we can't allocate VRAM for the zero state.
    // Letting that exception fly out of main is fine for the zero state.
    void saveZero(in World aZero)
    in {
        assert (aZero.isValid, "Complete the world first before saving it");
    }
    do {
        auto deepCopy = aZero.mutableHalf.clone();
        _zero.takeOwnershipOf(deepCopy);
    }

    Phyu zeroStatePhyu() const pure nothrow @safe @nogc {
        assert (_zero.isValid);
        return _zero.age;
    }

    // Internally, this creates a deep copy.
    // Deep copies may throw OutOfVramException.
    void saveUser(in World wo, in Replay r)
    {
        if (_userState.isValid) {
            _recommendGC = true;
        }
        assert (wo);
        assert (r);
        auto deepCopy = wo.mutableHalf.clone();
        _userState.takeOwnershipOf(deepCopy);
        _userReplay = r.clone();
    }

    bool userStateExists() const pure nothrow @safe @nogc
    out (ret) {
        assert (ret == _userState.isValid,
            "Bad user savestate: We have a replay XOR we have state");
    }
    do {
        return _userReplay !is null;
    }

    /*
     * Returns a deep copy of the user state. Caller may sell its ownership.
     * Returns a shallow copy of the replay. Caller should clone.
     *
     * We invalidate all cached states to kill all possible desynching bugs.
     * Maybe it's possible to optimize this:
     * Depending on mismatches between Nurse's replay and our saved replay
     * (let the caller pass you the nurse's replay), invalidate only some of
     * the cached states
     */
    auto loadUser()
    {
        forgetAutoSavesOnAndAfter(Phyu(0)); // See comment above loadUser().
        struct Ret {
            MutableHalfOfWorld state; // Deep copy. Caller may shallow-copy.
            const(Replay) replay; // Shallow copy. Caller should clone.
        }
        return Ret(_userState.clone(), _userReplay);
    }

    // Returns a deep copy by value. Caller can sell its ownership.
    MutableHalfOfWorld loadBeforePhyu(in Phyu u)
    {
        MutableHalfOfWorld* ret = &_zero;
        foreach (ref cand; _auto)
            if (cand.isValid && cand.age < u && cand.age > ret.age)
                ret = &cand;
        forgetAutoSavesOnAndAfter(u);
        return ret.clone();
    }

    bool wouldAutoSave(
        in World s,
        in Phyu updTo,
        in DuringTurbo duringTurbo) const
    {
        immutable pair = duringTurbo ? 1 : 0;
        assert (pair >= 0 && pair < pairsToKeep);
        if (s.age == 0 || s.age % updateMultipleForPair(pair) != 0)
            return false;
        foreach (possible; pair .. pairsToKeep)
            // We save 2 states per update multiple. But when we want to update
            // 100 times, there is no need saving states after 10, 20, 30, ...
            // updates, we would only keep the states at 90 and 100, anyway.
            // And the state at 50 and 100, in a higher pair.
            if (s.age > updTo - 2 * updateMultipleForPair(possible)
                && s.age % updateMultipleForPair(possible) == 0)
                return true;
        return false;
    }

    void autoSave(in World s, in Phyu ultimatelyTo)
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

        for (int pair = pairsToKeepForThisMap - 1; pair >= 0; --pair) {
            if (s.age % updateMultipleForPair(pair) != 0) {
                continue;
            }
            bool leapfrog = (s.age / updateMultipleForPair(pair)) & 1;
            auto deepCopy = s.mutableHalf.clone();
            _auto[2 * pair + leapfrog].takeOwnershipOf(deepCopy);
            return;
        }
    }

private:
    void forgetAutoSavesOnAndAfter(in Phyu u)
    {
        foreach (ref state; _auto) {
            if (state.isValid && (u <= _zero.age || state.age >= u)) {
                state.dispose();
            }
        }
        _recommendGC = true;
    }

    int updateMultipleForPair(in int pair) const pure @nogc
    in { assert (pair >= 0 && pair < pairsToKeep); }
    do {
        return pair == 0 ? 10
            : pair == 1 ? 10*5
            : pair == 2 ? 10*5*5 : 10*5*5*5;
    }
}
// end class StateManager
