module physics.state;

/* A gamestate. It saves everything about the current position, but not
 * how we got here. The class Replay saves everything about the history,
 * so you can reconstruct the current state from the beginning gamestate and
 * a replay.
 */

import std.algorithm;
import std.conv;
import std.range;
import std.typecons;

import basics.help; // clone(T[]), a deep copy for arrays
import basics.topology;
import graphic.torbit;
import graphic.gadget;
import hardware.tharsis;
import net.repdata;
import net.style;
import physics.tribe;
import tile.phymap;

alias GameState = RefCounted!(RawGameState, RefCountedAutoInitialize.no);

GameState clone(in GameState gs)
{
    GameState ret;
    ret.refCountedStore.ensureInitialized();
    ret.refCountedPayload = gs.refCountedPayload;
    return ret;
}

private struct RawGameState {
public:
    Phyu age;
    int overtimeAtStartInPhyus;

    Tribe[Style] tribes; // update order is garden, red, orange, yellow, ...

    Hatch[] hatches;
    Goal[] goals;
    Water[] waters;
    TrapTrig[] traps;
    FlingPerm[] flingPerms;
    FlingTrig[] flingTrigs;

    Torbit land;
    Phymap lookup;

    this(this) { opAssignImpl(this); }

    ref RawGameState opAssign(ref const(RawGameState) rhs) return
    {
        if (this is rhs)
            return this;
        return opAssignImpl(rhs);
    }

    ~this()
    {
        age = Phyu(0);
        if (land) {
            land.dispose();
            land = null;
        }
        lookup = null;
    }

    // With dmd 2.0715.1, inout doesn't seem to work for this.
    // Let's duplicate the function, once for const, once for mutable.
    void foreachConstGadget(void delegate(const(Gadget)) func) const
    {
        chain(hatches, goals, waters, traps, flingPerms, flingTrigs).each!func;
    }
    void foreachGadget(void delegate(Gadget) func)
    {
        chain(hatches, goals, waters, traps, flingPerms, flingTrigs).each!func;
    }

    int numTribes() const pure nothrow @safe @nogc
    {
        return tribes.length & 0xFFFF;
    }

    bool multiplayer() const pure nothrow @safe @nogc
    {
        assert (numTribes > 0);
        return numTribes > 1;
    }

    Style singleplayerStyle() const pure nothrow @safe @nogc
    in { assert (! multiplayer, "call this only in singleplayer"); }
    do { return tribes.byKey.front; }

    @property bool singleplayerHasSavedAtLeast(in int lixRequired) const @nogc
    {
        return ! multiplayer
            && tribes.byValue.front.score.lixSaved >= lixRequired;
    }

    @property bool singleplayerHasNuked() const @nogc
    {
        return ! multiplayer && tribes.byValue.front.hasNuked;
    }

    @property bool overtimeRunning() const
    in { assert (tribes.length > 0); }
    do {
        return tribes.byValue.all!(tr => tr.prefersGameToEnd)
            || tribes.byValue.any!(tr => tr.triggersOvertime);
    }

    // Call this only if overtimeRunning.
    // Use this only for effect handling. For nuking or exit locking,
    // use nukeIsAssigningExploders or lixMayUseGoals.
    Phyu overtimeRunningSince() const
    in {
        assert (overtimeRunning);
        assert (tribes.length > 0);
    }
    do {
        if (tribes.byValue.all!(tr => tr.prefersGameToEnd)) {
            return tribes.byValue.map!(tr => tr.prefersGameToEndSince.front)
                .reduce!max;
        }
        else {
            assert (tribes.byValue.any!(tr => tr.triggersOvertime));
            return tribes.byValue
                .filter!(tr => tr.triggersOvertime)
                .map!(tr => tr.triggersOvertimeSince.front)
                .reduce!min;
        }
    }

    // This doesn't return Phyu because Phyu is a point in time, not a duration
    @property int overtimeRemainingInPhyus() const
    {
        if (! overtimeRunning)
            return overtimeAtStartInPhyus;
        if (tribes.byValue.all!(tr => tr.prefersGameToEnd))
            return 0;
        return clamp(overtimeAtStartInPhyus + overtimeRunningSince - age,
                    0, overtimeAtStartInPhyus);
    }

    @property bool nukeIsAssigningExploders() const
    {
        return overtimeRunning() && overtimeRemainingInPhyus == 0;
    }

    // Extra check (other than nukeIsAssigningExploders) for edge case during
    // race maps (overtime 0, i.e., terminate on first scoring):
    // Assume 3 players enter the exit at the same time. Since one
    // player has to be processed first, that player would, without
    // the next comparison, change the nuke status before processing
    // the next player. The nuke prevents lixes from exiting.
    // Solution: In race maps, allow that one update to finish with scoring.
    @property bool lixMayUseGoals() const
    {
        return ! nukeIsAssigningExploders || overtimeRunningSince == age;
    }

private:
    ref RawGameState opAssignImpl(ref const(RawGameState) rhs) return
    {
        copyValuesArraysFrom(rhs);
        copyLandFrom(rhs);
        lookup = rhs.lookup ? rhs.lookup.clone() : null;
        return this;
    }

    void copyLandFrom(ref const(RawGameState) rhs)
    {
        if (land && land.matches(rhs.land)) {
            land.copyFrom(rhs.land);
        }
        else {
            if (land)
                land.dispose();
            land = rhs.land ? rhs.land.clone() : null;
        }
    }

    void copyValuesArraysFrom(ref const(RawGameState) rhs)
    {
        overtimeAtStartInPhyus = rhs.overtimeAtStartInPhyus;
        age = rhs.age;
        hatches  = basics.help.clone(rhs.hatches);
        goals    = basics.help.clone(rhs.goals);
        waters   = basics.help.clone(rhs.waters);
        traps    = basics.help.clone(rhs.traps);
        flingPerms = basics.help.clone(rhs.flingPerms);
        flingTrigs = basics.help.clone(rhs.flingTrigs);

        // Deep-clone this by hand, I haven't written a generic clone for AAs
        // Don't start with (tribes = null;) because rhs could be this.
        typeof(tribes) temp;
        foreach (style, tribe; rhs.tribes)
            temp[style] = tribe.clone();
        tribes = temp;
    }
}
