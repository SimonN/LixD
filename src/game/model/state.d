module game.model.state;

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
import net.repdata;
import basics.topology;
import tile.phymap;
import game.tribe;
import graphic.torbit;
import graphic.gadget;
import hardware.tharsis;
import net.style;

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
    Phyu update;
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

    enum updateFirstSpawn = Phyu(60);

    this(this) { opAssignImpl(this); }

    ref RawGameState opAssign(ref const(RawGameState) rhs)
    {
        if (this is rhs)
            return this;
        return opAssignImpl(rhs);
    }

    ~this()
    {
        update = Phyu(0);
        if (land) {
            land.dispose();
            land = null;
        }
        lookup = null;
    }

    int numTribes() const @nogc { return tribes.length & 0xFFFF; }

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

    void drawAllGadgets()
    {
        goals.each!(g => g.lockedWithNoSign =
            nuking && ! tribes.byValue.all!(tr => tr.outOfLix));
        foreachConstGadget(delegate void (const(Gadget) g) { g.draw; });
    }

    @property bool multiplayer() const @nogc
    {
        assert (numTribes > 0);
        return numTribes > 1;
    }

    @property bool singleplayerHasSavedAtLeast(in int lixRequired) const @nogc
    {
        return ! multiplayer
            && tribes.byValue.front.score.current >= lixRequired;
    }

    @property bool overtimeRunning() const
    in { assert (tribes.length > 0); }
    body{
        return tribes.byValue.all!(tr => tr.prefersGameToEnd)
            || tribes.byValue.any!(tr => tr.triggersOvertime);
    }

    // This doesn't return Phyu because Phyu is a point in time, not a duration
    @property int overtimeRemainingInPhyus() const
    {
        if (! overtimeRunning)
            return overtimeAtStartInPhyus;
        if (tribes.byValue.all!(tr => tr.prefersGameToEnd))
            return 0;
        return clamp(overtimeAtStartInPhyus + overtimeRunningSince - update,
                    0, overtimeAtStartInPhyus);
    }

    @property bool nuking() const
    {
        return overtimeRunning() && overtimeRemainingInPhyus == 0;
    }

private:
    ref RawGameState opAssignImpl(ref const(RawGameState) rhs)
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
        update   = rhs.update;
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

    @property Phyu overtimeRunningSince() const
    in {
        assert (overtimeRunning);
        assert (tribes.length > 0);
    }
    body {
        if (tribes.byValue.all!(tr => tr.prefersGameToEnd)) {
            return tribes.byValue.map!(tr => tr.prefersGameToEndSince)
                                 .reduce!max;
        }
        else {
            assert (tribes.byValue.any!(tr => tr.triggersOvertime));
            return tribes.byValue.filter!(tr => tr.triggersOvertime)
                .map!(tr => tr.triggersOvertimeSince).reduce!min;
        }
    }
}
