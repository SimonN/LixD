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
import physics.tribes;
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

    Torbit land;
    Phymap lookup;
    Tribes tribes; // update order is garden, red, orange, yellow, ...

    Hatch[] hatches;
    Goal[] goals;
    Water[] waters;
    TrapTrig[] traps;
    FlingPerm[] flingPerms;
    FlingTrig[] flingTrigs;

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

    const pure nothrow @safe @nogc {
        bool isPuzzle() { return tribes.isPuzzle; }
        bool isBattle() { return tribes.isBattle; }
        bool isSolvedPuzzle(in int req) { return tribes.isSolvedPuzzle(req); }
    }

    bool someoneDoesntYetPreferGameToEnd() const
    {
        return tribes.playerTribes.any!(tr => ! tr.prefersGameToEnd);
    }

    // False as long as overtime hasn't started running yet.
    // True after overtime has started running, or after overtime has run out.
    bool isOvertimeRunning() const pure nothrow @safe @nogc
    in { assert (isBattle || isPuzzle, "Add players to avoid empty truth."); }
    do {
        return tribes.playerTribes.all!(tr => tr.prefersGameToEnd)
            || tribes.playerTribes.any!(tr => tr.triggersOvertime);
    }

    // Call this only if isOvertimeRunning.
    // Use this only for effect handling. For nuking or exit locking,
    // use nukeIsAssigningExploders or lixMayUseGoals.
    Phyu overtimeRunningSince() const
    in {
        assert (isOvertimeRunning);
    }
    do {
        if (tribes.playerTribes.all!(tr => tr.prefersGameToEnd)) {
            return tribes.playerTribes
                .map!(tr => tr.prefersGameToEndSince.front)
                .reduce!max;
        }
        else {
            assert (tribes.playerTribes.any!(tr => tr.triggersOvertime));
            return tribes.playerTribes
                .filter!(tr => tr.triggersOvertime)
                .map!(tr => tr.triggersOvertimeSince.front)
                .reduce!min;
        }
    }

    // Returns as int, not as Phyu. Phyu is a point in time, not a duration.
    int overtimeRemainingInPhyus() const
    {
        if (! isOvertimeRunning)
            return overtimeAtStartInPhyus;
        if (tribes.playerTribes.all!(tr => tr.prefersGameToEnd))
            return 0;
        return clamp(overtimeAtStartInPhyus + overtimeRunningSince - age,
            0, overtimeAtStartInPhyus);
    }

    bool nukeIsAssigningExploders() const
    {
        return isOvertimeRunning() && overtimeRemainingInPhyus == 0;
    }

    // Extra check (other than nukeIsAssigningExploders) for edge case during
    // race maps (overtime 0, i.e., terminate on first scoring):
    // Assume 3 players enter the exit at the same time. Since one
    // player has to be processed first, that player would, without
    // the next comparison, change the nuke status before processing
    // the next player. The nuke prevents lixes from exiting.
    // Solution: In race maps, allow that one update to finish with scoring.
    bool lixMayUseGoals() const
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
        tribes = rhs.tribes.clone();
        hatches  = basics.help.clone(rhs.hatches);
        goals    = basics.help.clone(rhs.goals);
        waters   = basics.help.clone(rhs.waters);
        traps    = basics.help.clone(rhs.traps);
        flingPerms = basics.help.clone(rhs.flingPerms);
        flingTrigs = basics.help.clone(rhs.flingTrigs);
    }
}
