module lix.skill.climber;

import hardware.sound;
import lix;

class Climber : Job {
private:
    enum ceilingY = -16;

public:
    mixin JobChild;

    override @property bool blockable() const { return false; }

    override AfterAssignment onManualAssignment(Job old)
    {
        assert (! abilityToClimb);
        abilityToClimb = true;
        return AfterAssignment.doNotBecome;
    }

    override void onBecome(in Job old)
    {
        if (old.ac == Ac.jumper)
            playSound(Sound.CLIMBER);
        else
            frame = 3;
        stickSpriteToWall();
        maybeBecomeAscenderImmediatelyOnBecome();
    }

    override void perform()
    {
        if (isLastFrame)
            frame = 4;
        else
            advanceFrame();
        foreach (unused; 0 .. upwardsMovementThisFrame) {
            if (isSolid(0, ceilingY)) {
                turn();
                become(Ac.faller);
                return;
            }
            else if (ascendHoistableLedge)
                return;
            else
                moveUp(1);
        }
        assert (this is lixxie.job);
        if (ascendHoistableLedge)
            return;
        else
            stickSpriteToWall();
    }

private:
    void stickSpriteToWall()
    {
        // The climber should appear snugly close to the wall.
        // Since physically, for a right-facing climber, a wall at ex+2 and
        // ex+3 are the same, move the sprite horizontally to match the wall.
        spriteOffsetX = dir * (facingRight && ! isSolidSingle(2, -6)
                            || facingLeft  && ! isSolidSingle(1, -6));
    }

    void maybeBecomeAscenderImmediatelyOnBecome()
    {
        for (int i = 8; i < 18; ++i) {
            if (isSolid(0, -i)) {
                stopAndBecomeWalker();
                break;
            }
            // Remedy ccexplore's bug:
            // Jumping against the lower corner of a square, still high enough
            // to stick to as a climber, but enough air at the bottom to
            // trigger this check without, caused the climber to immediately
            // ascend right in the midde of the wall.
            // Of course, it looks slightly unusual to stick to a wall that's
            // got this much air below, but we leave it like this for now.
            else if (i > 9 && ! isSolid(2, -i)) {
                moveAhead();
                become(Ac.ascender);
                break;
            }
        }
    }

    int upwardsMovementThisFrame() const
    {
        switch ((frame - 4) % 8) {
            case 5:  return 2;
            case 6:  return 4;
            case 7:  return 2;
            default: return 0;
        }
    }

    bool ascendHoistableLedge()
    {
        if (! isSolid(2, ceilingY)) {
            moveAhead();
            become(Ac.ascender);
            return true;
        }
        else
            return false;
    }

    void stopAndBecomeWalker()
    {
        turn();
        if (isSolid()) {
            // This method can be called during become, then lixxie.ac might
            // still be walker or runner from before.
            // My OO model shows its weaknesses here. I should call a special
            // 'become' method to get a new walker; I shouldn't call a generic
            // walker method and then hack the new walker manually here.
            immutable int oldWalkerFrame =
                (lixxie.ac == Ac.walker || lixxie.ac == Ac.runner)
                ? lixxie.frame : -999;
            become(Ac.walker);
            if (oldWalkerFrame >= 0)
                lixxie.frame = oldWalkerFrame;
        }
        else
            become(Ac.faller);
    }
}
