module physics.world.cache;

/* PhysicsCache (former name: StateManager) holds many states, and knows when
 * to auto-save. Feed the StateManager with the current state all the time,
 * feed to function autoSave(). That will nop often.
 */

import std.algorithm;
import std.range;
import std.string;

import basics.help;
import basics.alleg5 : OutOfVramException;
import basics.globals : levelPixelsToWarn;
import basics.topology;
import file.replay;
import net.repdata;
import physics.world.world;

enum DuringTurbo : bool { no = false, yes = true }

class PhysicsCache {
private:
    MutableHalfOfWorld _zero; // for returning to the beginning

    LeapfrogPair[] _pairs; // Automatically taken savestates

    // For the user-triggered savestate, we remember the replay that was
    // correct by then. Otherwise, the user could restart, do something
    // deviating, and then load the user state that supposes the old,
    // differing replay.
    MutableHalfOfWorld _userState;
    Replay _userReplay;

    bool _recommendGC; // because we don't call the GC ourselves

public:
    this(in Topology levelThatWillBeSaved) pure nothrow @safe
    {
        _pairs = [
            LeapfrogPair(10), // The most frequent pair saves every 10 ticks.
            LeapfrogPair(10 * 6),
            LeapfrogPair(10 * 6 * 6),
            LeapfrogPair(10 * 6 * 6 * 6),
            LeapfrogPair(10 * 6 * 6 * 6 * 4)
        ].take(numPairsToKeepFor(levelThatWillBeSaved));
    }

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
        foreach (ref cand; allFrogs)
            if (cand.isValid && cand.age < u && cand.age > ret.age)
                ret = &cand;
        forgetAutoSavesOnAndAfter(u);
        return ret.clone();
    }

    /*
     * Reason for why this needs the target Phyu (weWillUpdateTo):
     *
     * We save 2 states per update multiple. But when we want to update
     * 120 times, there is no need saving states after 10, 20, 30, ...
     * updates, we would only keep the states at 110 and 120, anyway.
     * And we want to keep the state at 60 and 120, in a higher pair.
     */
    bool wouldAutoSave(
        in World worldToSave,
        in Phyu weWillUpdateTo,
        in DuringTurbo duringTurbo
    ) const pure nothrow @safe @nogc
    {
        if (! _pairs[0].accepts(worldToSave.age)) {
            return false; // Speed hack. If _pairs[0] won't bite, none will.
        }
        immutable firstAllowed = duringTurbo ? 1 : 0;
        for (int pair = _pairs.len - 1; pair >= firstAllowed; --pair) {
            if (_pairs[pair].accepts(worldToSave, weWillUpdateTo)) {
                return true;
            }
        }
        return false;
    }

    void autoSave(in World world)
    in {
        assert (wouldAutoSave(world, world.age, DuringTurbo.no),
        "Call autoSave() only when wouldAutoSave() returns true for you");
    }
    do {
        _recommendGC = true;
        try {
            // First, attempt to find a slower-frequency pair than _pairs[0].
            for (int pair = _pairs.len - 1; pair >= 1; --pair) {
                if (_pairs[pair].accepts(world.age)) {
                    _pairs[pair].save(world);
                    return;
                }
            }
            // No slow-frequency pair found. Save into the most frequent.
            saveIntoPair0ButMaybeBorrowSpaceFromHighestPair(world);
        }
        catch (OutOfVramException e) {
            /*
             * Do nothing here. We accept the error and don't savestate.
             *
             * We will let the exception fly out of PhysicsCache when we
             * savestate for the necessary zero state or for the user state.
             * The automatic savestates make rewinding/recomputing faster.
             * Slow rewinding is bad, but aborting the level would be worse.
             */
        }
    }

private:
    auto allFrogs() pure nothrow @system @nogc
    {
        auto ref toFrogs(return ref LeapfrogPair pair) { return pair.frogs[]; }
        return _pairs[].map!toFrogs.joiner;
    }

    void forgetAutoSavesOnAndAfter(in Phyu u)
    {
        foreach (ref state; allFrogs) {
            if (state.isValid && (u <= _zero.age || state.age >= u)) {
                state.dispose();
            }
        }
        _recommendGC = true;
    }

    int numPairsToKeepFor(in Topology lev) const pure nothrow @safe @nogc
    {
        // For large maps, don't save the final pair. This is a feeble attempt
        // at conserving RAM. See github issue 296 about RAM on Windows:
        // https://github.com/SimonN/LixD/issues/296
        immutable int pixels = lev.xl * lev.yl;
        return pixels     > levelPixelsToWarn     ? 3
            :  pixels * 3 > levelPixelsToWarn * 2 ? 4
                                                  : 5;
    }

    void saveIntoPair0ButMaybeBorrowSpaceFromHighestPair(in World world)
    in { assert (_pairs[0].accepts(world.age), "See autoSave()'s contract"); }
    do {
        /*
         * Quirk: _pairs[0] is special. Early in a level, the lowest-frequency
         * pair _pairs[$-1] isn't in use yet. During this time, _pairs[0]
         * behaves as having 4 frogs, not 2 frogs, and the extra 2 frogs
         * are the unused frogs from the highest pair.
         *
         * I.e., early in a level, we save
         * into _pairs[0].frog[0],
         * then _pairs[0].frog[1],
         * then _pairs[$-1].frog[0],
         * then _pairs[$-1].frog[1],
         * then _pairs[0].frog[0] again, and continue to cycle like this.
         */
        if (world.age >= _pairs[$-1].frequency - 2 * _pairs[0].frequency) {
            // We're late in the game. Treat _pairs[0] as normal with 2 frogs.
            _pairs[0].save(world);
            return;
        }
        immutable int divided = world.age / _pairs[0].frequency;
        immutable int whichPair = divided < 2 ? 0 : _pairs.len - 1;
        _pairs[whichPair].saveIntoSpecificFrog(world, divided & 1);
    }

}
// end class PhysicsCache

/*
 * LeapfrogPairs are pairs of automatic savestates that Lix takes in the
 * background, both during singleplayer (for rewinding) and during
 * multiplayer (for recalculating on newly arrived networking packets
 * that affect past physics updates).
 *
 * The most frequently saved pair is PhysicsCache._pairs[0] with frequency 10.
 * This means that we'll save every 10 ticks (physics updates) as follows:
 * During tick 70, we save into _pairs[0].frog[0],
 * during tick 80, we save into _pairs[0].frog[1],
 * during tick 90, we forget tick 70 and save again into _pairs[0].frog[0],
 * during tick 100, we forget tick 80 and save again into _pairs[0].frogs[1].
 */
private struct LeapfrogPair {
    immutable int frequency;
    MutableHalfOfWorld[2] frogs;

    bool accepts(in Phyu now) const pure nothrow @safe @nogc
    {
        return now > 0
            && now % frequency == 0;
    }

    bool accepts(
        in World worldToSave,
        in Phyu weWillUpdateTo
    ) const pure nothrow @safe @nogc
    {
        return accepts(worldToSave.age)
            && worldToSave.age > weWillUpdateTo - 2 * frequency;
    }

    void save(in World worldToSave)
    in { assert (accepts(worldToSave.age)); }
    do {
        immutable int divided = worldToSave.age / frequency;
        saveIntoSpecificFrog(worldToSave, divided & 1);
    }

    void saveIntoSpecificFrog(in World worldToSave, in bool frog0or1)
    {
        auto deepCopy = worldToSave.mutableHalf.clone();
        frogs[frog0or1].takeOwnershipOf(deepCopy);
    }
}
