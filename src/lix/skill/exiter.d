module lix.skill.exiter;

import game.tribe;
import graphic.gadget.goal;
import hardware.sound;
import lix;

class Exiter : Leaver {
private:
    // Do this much sideways motion during exiting, because the goal was
    // endered closer to the side than to the center of the trigger area
    int xOffsetFromGoal;

public:
    mixin JobChild;

    void scoreForTribe(Tribe tribe)
    {
        tribe.addSaved(this.style, outsideWorld.state.update);
    }

    void determineSidewaysMotion(in Goal goal)
    {
        xOffsetFromGoal = env.distanceX(
            goal.x + goal.tile.trigger.x + goal.tile.triggerXl / 2, lixxie.ex);
        if (xOffsetFromGoal % 2 == 0)
            // From C++ Lix: The +1 is necessary because this counts
            // pixel-wise, but the physics skip ahead 2 pixels at a time,
            // so the lixes enter the right part further to the left.
            xOffsetFromGoal += 1;
    }

    void playSound(in Goal goal)
    {
        if (goal.hasTribe(style)) {
            lixxie.playSound(Sound.GOAL);
        }
        else {
            lixxie.playSound(Sound.GOAL_BAD);
            foreach (tr; goal.tribes)
                outsideWorld.effect.addSound(outsideWorld.state.update, tr,
                    outsideWorld.lixID, // arbitrary ID because not same tribe
                    Sound.GOAL);
        }
    }

    override void perform()
    {
        int change = (xOffsetFromGoal < 0 ? 1 : xOffsetFromGoal > 0 ? -1 : 0);
        spriteOffsetX = spriteOffsetX + change;
        xOffsetFromGoal += change;

        advanceFrameAndLeave();
    }
}
