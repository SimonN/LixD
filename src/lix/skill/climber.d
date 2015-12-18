module lix.skill.climber;

import hardware.sound;
import lix;

class Climber : PerformedActivity {

    mixin(CloneByCopyFrom!"Climber");

    override @property bool callBecomeAfterAssignment() const { return false; }
    override @property bool blockable()                 const { return false; }

    override void onManualAssignment()
    {
        assert (! abilityToClimb);
        abilityToClimb = true;
    }

    private void stickSpriteToWall()
    {
        // The climber should appear snugly close to the wall.
        // Since physically, for a right-facing climber, a wall at ex+2 and
        // ex+3 are the same, move the sprite horizontally to match the wall.
        if (   (facingRight && ! isSolidSingle(2, -6))
            || (facingLeft  && ! isSolidSingle(1, -6))
        )
            spriteOffsetX = dir;
    }



    override void onBecome()
    {
        if (cast (Jumper) lixxie.performedActivity)
            playSound(Sound.CLIMBER);
        else
            frame = 3;

        stickSpriteToWall();

        // become ascender immediately?
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
        // end for
    }
    // end onBecome()



    private void stopAndBecomeWalker()
    {
        turn();
        if (isSolid()) {
            // This method can be called during become, then lixxie.ac might
            // still be walker or runner from before.
            immutable int oldWalkerFrame =
                (lixxie.ac == Ac.walker || lixxie.ac == Ac.runner)
                ? lixxie.frame : -999;
            become(Ac.walker);
            if (oldWalkerFrame >= 0)
                lixxie.frame = oldWalkerFrame;
        }
        else {
            become(Ac.faller);
        }
    }



    private enum ceilingY        = -17;
    private enum hoistableLedgeY = ceilingY + 1;

    override void performActivity()
    {
        if (isLastFrame) frame = 4;
        else             advanceFrame();

        int upBy = 0;
        switch ((frame - 4) % 8) {
            case 5: upBy = 2; break;
            case 6: upBy = 4; break;
            case 7: upBy = 2; break;
            default:          break;
        }

        foreach (unused; 0 .. upBy) {
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

        assert (this is lixxie.performedActivity);
        if (ascendHoistableLedge)
            return;
        else
            stickSpriteToWall();
    }
    // end performActivity



    private bool ascendHoistableLedge()
    {
        if (! isSolid(2, hoistableLedgeY)) {
            moveAhead();
            become(Ac.ascender);
            return true;
        }
        else
            return false;
    }


}
// end class Climber
