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
    Flinger[] flingers;

    Torbit land;
    Phymap lookup;

    this(this) { this.opAssign(this); }

    ref RawGameState opAssign(ref const(RawGameState) rhs)
    {
        if (this is rhs)
            return this;
        this.copyValuesArraysFrom(rhs);
        if (! land) {
            land = rhs.land.clone();
        }
        else if (land.matches(rhs.land))
            land.copyFrom(rhs.land);
        else {
            land.dispose();
            land = rhs.land.clone();
        }
        lookup = rhs.lookup.clone();
        return this;
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

    void foreachGadget(void delegate(Gadget) func)
    {
        chain(hatches, goals, waters, traps, flingers).each!func;
    }

    // It's sad that I need the duplication of this function, but inout
    // didn't work with delegates. No idea if it's me or D.
    void foreachConstGadget(void delegate(const Gadget) func) const
    {
        foreach (g; hatches) func(g);
        foreach (g; goals) func(g);
        foreach (g; waters) func(g);
        foreach (g; traps) func(g);
        foreach (g; flingers) func(g);
    }

    void drawAllGadgets()
    {
        goals.each!(g => g.lockedWithNoSign =
            nuking && ! tribes.byValue.all!(tr => tr.doneDeciding));
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
        return tribes.byValue.all!(tr => tr.wantsAbortiveTie)
            || tribes.byValue.any!(tr => tr.triggersOvertime);
    }

    @property Phyu overtimeRunningSince() const
    in {
        assert (overtimeRunning);
        assert (tribes.length > 0);
    }
    body {
        if (tribes.byValue.all!(tr => tr.wantsAbortiveTie)) {
            return tribes.byValue.map!(tr => tr.wantsAbortiveTieSince)
                                 .reduce!max;
        }
        else {
            assert (tribes.byValue.any!(tr => tr.triggersOvertime));
            return tribes.byValue.filter!(tr => tr.triggersOvertime)
                .map!(tr => tr.triggersOvertimeSince).reduce!min;
        }
    }

    // This doesn't return Phyu because Phyu is a point in time, not a duration
    @property int overtimeRemainingInPhyus() const
    {
        if (! overtimeRunning)
            return overtimeAtStartInPhyus;
        if (tribes.byValue.all!(tr => tr.doneDeciding || tr.wantsAbortiveTie))
            return 0;
        return clamp(overtimeAtStartInPhyus + overtimeRunningSince - update,
                    0, overtimeAtStartInPhyus);
    }

    @property bool nuking() const
    {
        return overtimeRunning() && overtimeRemainingInPhyus == 0;
    }

private:
    void copyValuesArraysFrom(ref const(RawGameState) rhs)
    {
        overtimeAtStartInPhyus = rhs.overtimeAtStartInPhyus;
        update   = rhs.update;
        hatches  = basics.help.clone(rhs.hatches);
        goals    = basics.help.clone(rhs.goals);
        waters   = basics.help.clone(rhs.waters);
        traps    = basics.help.clone(rhs.traps);
        flingers = basics.help.clone(rhs.flingers);

        // Deep-clone this by hand, I haven't written a generic clone for AAs
        // Don't start with (tribes = null;) because rhs could be this.
        typeof(tribes) temp;
        foreach (style, tribe; rhs.tribes)
            temp[style] = tribe.clone();
        tribes = temp;
    }
}
