module physics.job.climber;

import hardware.sound;
import physics.job;

class Climber : Job {
private:
    enum ceilingY = -16;

public:
    override bool blockable() const { return false; }

    override AfterAssignment onManualAssignment(Job old)
    {
        assert (! lixxie.abilityToClimb);
        lixxie.abilityToClimb = true;
        return AfterAssignment.doNotBecome;
    }

    override void onBecome(in Job old)
    {
        if (old.ac == Ac.jumper) {
            lixxie.playSound(Sound.CLIMBER);
        }
        else {
            frame = 3;
        }
        stickSpriteToWall();
        maybeBecomeAscenderImmediatelyOnBecome();
    }

    override void perform()
    {
        if (lixxie.isLastFrame) {
            frame = 4;
        }
        else {
            lixxie.advanceFrame();
        }
        foreach (unused; 0 .. upwardsMovementThisFrame) {
            if (lixxie.isSolid(0, ceilingY)) {
                lixxie.turn();
                lixxie.become(Ac.faller);
                return;
            }
            else if (ascendHoistableLedge) {
                return;
            }
            else {
                lixxie.moveUp(1);
            }
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
        spriteOffsetX = lixxie.dir
            * (lixxie.facingRight && ! lixxie.isSolidSingle(2, -6)
             || lixxie.facingLeft && ! lixxie.isSolidSingle(1, -6));
    }

    void maybeBecomeAscenderImmediatelyOnBecome()
    {
        for (int i = 8; i < 18; ++i) {
            if (lixxie.isSolid(0, -i)) {
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
            else if (i > 9 && ! lixxie.isSolid(2, -i)) {
                lixxie.moveAhead();
                lixxie.become(Ac.ascender);
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
        if (lixxie.isSolid(2, ceilingY)) {
            return false;
        }
        lixxie.moveAhead();
        lixxie.become(Ac.ascender);
        return true;
    }

    void stopAndBecomeWalker()
    {
        lixxie.turn();
        if (lixxie.isSolid()) {
            // This method can be called during become, then lixxie.ac might
            // still be walker or runner from before.
            // My OO model shows its weaknesses here. I should call a special
            // 'become' method to get a new walker; I shouldn't call a generic
            // walker method and then hack the new walker manually here.
            immutable int oldWalkerFrame =
                (lixxie.ac == Ac.walker || lixxie.ac == Ac.runner)
                ? lixxie.frame : -999;
            lixxie.become(Ac.walker);
            if (oldWalkerFrame >= 0)
                frame = oldWalkerFrame;
        }
        else {
            lixxie.become(Ac.faller);
        }
    }
}
