module physics.job.exiter;

import basics.styleset;
import graphic.gadget.goal;
import hardware.sound;
import physics.job;
import physics.tribe;

class Exiter : Leaver {
private:
    // Do this much sideways motion during exiting, because the goal was
    // endered closer to the side than to the center of the trigger area
    int xOffsetFromGoal;

    /*
     * Theoretically, you can encounter multiple exits during one physics
     * update. We don't want multiple scorings for the same team, but,
     * for sheer consistency, we allow to score for different teams.
     * (stylesThatAlreadyScored) remembers which teams have already
     * received a point for this particular exiter.
     */
    StyleSet _stylesThatAlreadyScored;

public:
    /*
     * Call enterGoal() only when you're sure that you want to enter that goal.
     * For exiting eligibility tests (e.g., how Lix prevents direct drop),
     * and for how the lix finds goals, see physics/lixxie/perform.d.
     */
    static void enterGoal(
        Lixxie li,
        in Goal goal,
    ) {
        // With stacked goals, it's possible that we are already an exiter.
        if (li.ac != Ac.exiter) {
            li.become(Ac.exiter);
        }
        Exiter exiter = cast (Exiter) li.job;
        assert (exiter, "Exiters should never become anything else");
        exiter.determineSidewaysMotion(goal);
        exiter.scoreForGoalOwners(goal);
    }

    override void perform()
    {
        int change = (xOffsetFromGoal < 0 ? 1 : xOffsetFromGoal > 0 ? -1 : 0);
        spriteOffsetX = spriteOffsetX + change;
        xOffsetFromGoal += change;

        advanceFrameAndLeave();
    }

private:
    void determineSidewaysMotion(in Goal goal)
    {
        xOffsetFromGoal = lixxie.env.distanceX(goal.loc.x + goal.tile.trigger.x
            + goal.tile.triggerXl / 2, lixxie.ex);
        if (xOffsetFromGoal % 2 == 0)
            // From C++ Lix: The +1 is necessary because this counts
            // pixel-wise, but the physics skip ahead 2 pixels at a time,
            // so the lixes enter the right part further to the left.
            xOffsetFromGoal += 1;
    }

    void scoreForGoalOwners(in Goal goal)
    {
        if (goal.hasOwner(lixxie.style)) {
            // Lix A in exit ABC scores only for A, never for B nor C.
            scoreForTribe(lixxie.outsideWorld.tribe);
            return;
        }
        // But Lix A in exit DEF scores for all of D, E, F each.
        lixxie.playSound(Sound.GOAL_BAD);
        foreach (enemy; lixxie.outsideWorld.state.tribes.allTribesEvenNeutral)
            if (goal.hasOwner(enemy.style))
                scoreForTribe(enemy);
    }

    void scoreForTribe(Tribe beneficiary)
    {
        if (_stylesThatAlreadyScored.contains(beneficiary.style)) {
            return;
        }
        _stylesThatAlreadyScored.insert(beneficiary.style);
        beneficiary.addSaved(lixxie.style, lixxie.outsideWorld.state.age);

        if (beneficiary.style == lixxie.style) {
            lixxie.playSound(Sound.GOAL);
            return;
        }
        lixxie.outsideWorld.effect.addSound(
            lixxie.outsideWorld.state.age,
            // arbitrary ID because not same tribe
            Passport(beneficiary.style, lixxie.outsideWorld.passport.id),
            Sound.GOAL);
    }
}
