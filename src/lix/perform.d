module lix.perform;

import std.algorithm; // find
import std.conv;
import std.math; // sqrt
import std.range;

import tile.phymap;
import graphic.gadget;
import hardware.sound;
import lix;
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

    assert (l.outsideWorld);
    if (! l.outsideWorld.state.nuking)
        l.useGoals();
}

private:

void useWater(Lixxie lixxie) { with (lixxie)
{
    if (! healthy)
        return;
    else if (bodyEncounters & Phybit.fire)
        become(Ac.burner);
    else if (footEncounters & Phybit.water)
        become(Ac.drowner);
}}

void useNonconstantTraps(Lixxie lixxie) { with (lixxie)
{
    if (! (footEncounters & Phybit.trap) || ! healthy)
        return;
    foreach (TrapTrig trap; outsideWorld.state.traps) {
        if (! inTriggerArea(trap)
            || ! trap.isOpenFor(outsideWorld.state.update, style))
            continue;
        trap.feed(outsideWorld.state.update, style);
        playSound(trap.tile.sound);
        become(Ac.nothing);
        return;
    }
}}



void useFlingers(Lixxie lixxie) { with (lixxie) with (outsideWorld.state)
{
    if (! (bodyEncounters & Phybit.fling) || ! healthy)
        return;
    auto encounteredOpenFlingers = chain(flingTrigs
            .filter!(fl => inTriggerArea(fl) && fl.isOpenFor(update, style))
            .tee!(fl => fl.feed(update, style)),
        outsideWorld.state.flingPerms.filter!(fl => inTriggerArea(fl)));
    foreach (Gadget fl; encounteredOpenFlingers) {
        assert (fl.tile);
        addFling(fl.tile.subtype & 1 ? fl.tile.specialX // force direction
                                     : fl.tile.specialX * lixxie.dir,
            fl.tile.specialY, false); // false == not from same tribe
    }
    // call this function once more; it may have been called by the game's
    // update-all-lixes function, but we don't want to wait until next turn
    Tumbler.applyFlingXY(lixxie);
}}



void useGoals(Lixxie lixxie) { with (lixxie)
{
    if (! (footEncounters & Phybit.goal)
        || priorityForNewAc(Ac.exiter) <= 1
    )
        return;
    const(Tribe)[] alreadyScoredFor;
    foreach (goal; outsideWorld.state.goals)
        if (inTriggerArea(goal))
            lixxie.useGoal(goal, alreadyScoredFor);
}}

void useGoal(Lixxie li, in Goal goal, ref const(Tribe)[] alreadyScoredFor) {
    with (li)
{
    // We may or may not be exiter already, by colliding with stacked goals
    if (ac != Ac.exiter)
        become(Ac.exiter);

    Exiter exiter = cast (Exiter) job;
    assert (exiter, "exiters shouldn't become anything else upon becoming");

    exiter.determineSidewaysMotion(goal);
    exiter.playSound(goal);

    void scoreForTribe(Tribe tribe)
    {
        if (alreadyScoredFor.find(tribe) != null)
            return;
        alreadyScoredFor ~= tribe;
        exiter.scoreForTribe(tribe);
    }

    if (goal.hasTribe(style))
        scoreForTribe(outsideWorld.tribe);
    else
        foreach (enemyTribe; outsideWorld.state.tribes)
            if (goal.hasTribe(enemyTribe.style))
                scoreForTribe(enemyTribe);
}}



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
