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

void useTrampos(Lixxie lixxie) { with (lixxie)
{
    int bounceBackY(in float pixelsFallen)
    {
        return (-0.5f - 2 * sqrt(1.0f + pixelsFallen)).floor.to!int;
    }

    if (! (bodyEncounters & Phybit.trampo)
        || ! healthy
        || ac != Ac.faller && ac != Ac.jumper && ac != Ac.tumbler
        // in particular, floaters pass through trampos unhindered
    )
        return;
    foreach (Trampo tp; outsideWorld.state.trampos) {
        if (! inTriggerArea(tp))
            continue;
        tp.feed(outsideWorld.state.update, outsideWorld.tribeID);
        enum minAccelY = -6;
        if (ac == Ac.faller) {
            Faller faller = cast (Faller) performedActivity;
            assert (faller);
            addFling(4 * dir, min(minAccelY, bounceBackY(faller.pixelsFallen)),
                false); // false == not from same tribe
            Tumbler.applyFlingXY(lixxie);
        }
        else {
            assert (ac == Ac.jumper || ac == Ac.tumbler);
            BallisticFlyer bf = cast (BallisticFlyer) performedActivity;
            assert (bf);
            if (bf.speedY <= 0)
                continue;
            bf.speedX = max(bf.speedX, 4);
            if (bf.speedY <= 12)
                bf.speedY = min(minAccelY, - bf.speedY - 1);
            else {
                int approxFallenDistance
                    // at more than speedY == 12, we accelerate slower
                    = ((bf.speedY-2) * (bf.speedY-1) - 37) / 2;
                assert (approxFallenDistance > 0);
                bf.speedY = bounceBackY(approxFallenDistance);
                assert (bf.speedY < minAccelY);
            }
            // DTODOSKILLS: choose frame, but not like so, that ignored runner:
            // if (l.get_ac() == LixEn::JUMPER) l.set_frame(5);
        }
    }
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
