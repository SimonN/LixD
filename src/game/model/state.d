module game.model.state;

/* A gamestate. It saves everything about the current position, but not
 * how we got here. The class Replay saves everything about the history,
 * so you can reconstruct the current state from the beginning gamestate and
 * a replay.
 */

import std.range;
import std.algorithm;

import basics.help; // clone(T[]), a deep copy for arrays
import net.repdata;
import basics.topology;
import tile.phymap;
import game.tribe;
import graphic.torbit;
import graphic.gadget;
import hardware.tharsis;

class GameState {

    Update update;
    int  clock;
    bool clockIsRunning;

    bool goalsLocked; // in singleplayer, when time has run out

    Tribe[] tribes;

    Hatch[] hatches;
    Goal[] goals;
    Water[] waters;
    TrapTrig[] traps;
    Flinger[] flingers;

    Torbit land;
    Phymap lookup;

    this() { }
/*  this         (in GameState rhs);
 *  void copyFrom(in GameState rhs);
 */
    GameState clone() const { return new GameState(this); }

    void dispose()
    {
        if (land) {
            land.dispose();
            land = null;
        }
    }

    void foreachGadget(void delegate(Gadget) func)
    {
        chain(hatches, goals, waters, traps, flingers)
            .each!func;
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

    @property bool multiplayer() const
    {
        assert (tribes.length > 0);
        return (tribes.length > 1);
    }

    @property bool singleplayerHasWon() const
    {
        return ! multiplayer && tribes[0].lixSaved >= tribes[0].lixRequired;
    }

    private void
    copyValuesArraysFrom(in GameState rhs)
    {
        update         = rhs.update;
        clock          = rhs.clock;
        clockIsRunning = rhs.clockIsRunning;
        goalsLocked    = rhs.goalsLocked;

        tribes   = rhs.tribes  .clone;
        hatches  = rhs.hatches .clone;
        goals    = rhs.goals   .clone;
        waters   = rhs.waters  .clone;
        traps    = rhs.traps   .clone;
        flingers = rhs.flingers.clone;
    }

    this(in GameState rhs)
    {
        assert (rhs, "don't copy-construct from a null GameState");
        assert (rhs.land, "don't copy-construct from GameState without land");
        version (tharsisprofiling)
            auto zone = Zone(profiler, "GameState.clone all");
        {
            version (tharsisprofiling)
                auto zone1 = Zone(profiler, "GameState.clone arrays");
            copyValuesArraysFrom(rhs);
        } {
            version (tharsisprofiling)
                auto zone2 = Zone(profiler, "GameState.clone land");
            land = new Torbit(rhs.land);
        } {
            version (tharsisprofiling)
                auto zone3 = Zone(profiler, "GameState.clone phymap");
            lookup = new Phymap(rhs.lookup);
        }
    }

    void copyFrom(in GameState rhs)
    {
        assert (rhs);
        assert (rhs.land);
        assert (this.land);
        assert (rhs.land.Topology.opEquals(this.land),
            "for fast copyFrom, we want to avoid newing Albits, we only blit");

        copyValuesArraysFrom(rhs);
        land  .copyFrom(rhs.land);
        lookup.copyFrom(rhs.lookup);
    }

    // currently unnused, shall be used by StateManager and Game's cs
    static void cloneOrCopyFrom(ref GameState lhs, in GameState rhs)
    {
        if (lhs is null)
            lhs = new GameState(rhs);
        else
            lhs.copyFrom(rhs);
    }

}
