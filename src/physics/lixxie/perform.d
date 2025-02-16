module physics.lixxie.perform;

import std.algorithm; // find
import std.conv;
import std.math; // sqrt
import std.range;

import tile.phymap;
import physics.gadget;
import hardware.sound;
import physics.job;
import physics.lixxie.lixxie;
import physics.tribe;

// called from Lixxie.perform(OutsideWorld*)
package void performUseGadgets(Lixxie l)
{
    l.addEncountersFromHere();
    l.job.perform();
    l.killOutOfBounds();
    l.useWater();
    l.useNonconstantTraps();
    l.useFlingers();
    l.maybeEnterGoals();
}

private:

void useWater(Lixxie lixxie) { with (lixxie)
{
    if (! healthy)
        return;
    else if (footEncounters & Phybit.fire)
        become(Ac.burner);
    else if (footEncounters & Phybit.water)
        become(Ac.drowner);
}}

void useNonconstantTraps(Lixxie lixxie) { with (lixxie)
{
    if (! (footEncounters & Phybit.muncher) || ! healthy)
        return;
    foreach (Muncher trap; outsideWorld.state.munchers) {
        if (! inTriggerArea(trap)
            || ! trap.isOpenFor(outsideWorld.state.age, style))
            continue;
        trap.feed(outsideWorld.state.age, style);
        playSound(Sound.SPLAT);
        become(Ac.nothing);
        return;
    }
}}

void useFlingers(Lixxie lixxie) { with (lixxie) with (outsideWorld.state)
{
    enum anyFlingBit = Phybit.steam | Phybit.catapult;
    if (! (footEncounters & anyFlingBit) || ! healthy)
        return;
    auto encounteredOpenFlingers = chain(catapults
            .filter!(fl => inTriggerArea(fl) && fl.isOpenFor(age, style))
            .tee!(fl => fl.feed(age, style)),
        outsideWorld.state.steams.filter!(fl => inTriggerArea(fl)));
    foreach (const(Gadget) fl; encounteredOpenFlingers) {
        assert (fl.tile);
        addFling(fl.tile.flingForward
            ? fl.tile.specialX * lixxie.dir // fling forward
            : fl.tile.specialX, // always fling in the tile's fixed direction
            fl.tile.specialY, false); // false == not from same tribe
    }
    // call this function once more; it may have been called by the game's
    // update-all-lixes function, but we don't want to wait until next turn
    Tumbler.applyFlingXY(lixxie);
}}

void maybeEnterGoals(Lixxie lixxie)
{
    assert (lixxie.outsideWorld !is null);
    if ((lixxie.footEncounters & Phybit.goal)
        && lixxie.priorityForNewAc(Ac.exiter).isAssignable // No direct drop.
        && lixxie.outsideWorld.state.lixMayUseGoals
    ) {
        foreach (goal; lixxie.outsideWorld.state.goals) {
            if (lixxie.inTriggerArea(goal)) {
                Exiter.enterGoal(lixxie, goal);
            }
        }
    }
}

void killOutOfBounds(Lixxie lixxie) {
    with (lixxie)
{
    if (! healthy)
        return;
    const phymap = outsideWorld.state.lookup;
    if (   ey >= phymap.yl + 23
        || ey >= phymap.yl + 15 && ac != Ac.floater
        || ey <= -2 // top edge kills unconditionally, it did not in C++
        || ex >= phymap.xl +  4
        || ex <= -4
    ) {
        playSound(Sound.OBLIVION);
        become(Ac.nothing);
    }
}}
