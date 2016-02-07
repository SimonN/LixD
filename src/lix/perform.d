module lix.perform;

import std.algorithm; // find
import std.conv;
import std.math; // sqrt

import game.phymap;
import game.tribe;
import graphic.gadget;
import hardware.sound;
import lix.enums;
import lix.lixxie;
import lix.skill.exiter;
import lix.skill.faller;
import lix.skill.tumbler;

// called from Lixxie.perform(OutsideWorld*)
package void performUseGadgets(Lixxie l)
{
    l.addEncountersFromHere();
    l.job.perform();
    l.killOutOfBounds();
    l.useWater();
    l.useNonconstantTraps();
    l.useFlingers();
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
        if (! inTriggerArea(trap) ||
            ! trap.isOpenFor(outsideWorld.state.update, outsideWorld.tribeID))
            continue;
        trap.feed(outsideWorld.state.update, outsideWorld.tribeID);
        playSound(trap.tile.sound);
        become(Ac.nothing);
        return;
    }
}}



void useFlingers(Lixxie lixxie) { with (lixxie)
{
    if (! (bodyEncounters & Phybit.fling) || ! healthy)
        return;
    foreach (Flinger fl; outsideWorld.state.flingers) {
        if (! inTriggerArea(fl) ||
            ! fl.isOpenFor(outsideWorld.state.update, outsideWorld.tribeID))
            continue;
        fl.feed(outsideWorld.state.update, outsideWorld.tribeID);
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
        || priorityForNewAc(Ac.exiter, false) <= 1
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

    if (goal.hasTribe(outsideWorld.state, outsideWorld.tribe))
        scoreForTribe(outsideWorld.tribe);
    else
        foreach (enemyTribe; outsideWorld.state.tribes)
            if (goal.hasTribe(outsideWorld.state, enemyTribe))
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
        || ex >= phymap.xl +  4
        || ex <= -4
    ) {
        playSound(Sound.OBLIVION);
        become(Ac.nothing);
    }
}}
