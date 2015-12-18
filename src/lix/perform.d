module lix.perform;

import std.algorithm; // find

import game.phymap;
import game.tribe;
import graphic.gadget.goal;
import hardware.sound;
import lix.enums;
import lix.lixxie;
import lix.skill.exiter;

// called from Lixxie.perform(OutsideWorld*)
package void performActivityUseGadgets(Lixxie l)
{
    l.addEncountersFromHere();

    l.performedActivity.performActivity();

    l.killOutOfBounds();
    l.useWater();
    l.useNonconstantTraps();
    l.useFlingers();
    l.useTrampos();
    l.useGoals();
}

private:

// DTODO: implement all of these remaining

void useWater           (Lixxie l) { /* and fire */ }
void useNonconstantTraps(Lixxie l) { }
void useFlingers        (Lixxie l) { }
void useTrampos         (Lixxie l) { }



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

    Exiter exiter = cast (Exiter) performedActivity;
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

    if (goal.hasTribe(outsideWorld.tribe))
        scoreForTribe(outsideWorld.tribe);
    else
        foreach (enemyTribe; outsideWorld.state.tribes)
            if (goal.hasTribe(enemyTribe))
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
