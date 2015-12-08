module lix.walker;

import lix;

private void
setFrameAfterShortFallTo(PerformedActivity newAc, int targetFrame)
{
    if (newAc.lixxie.ac == Ac.faller) {
        auto oldAc = cast (const(Faller)) newAc.lixxie.performedActivity;
        assert (oldAc);
        if (   oldAc.pixelsFallen <= 9 && oldAc.frame < 1
            || oldAc.pixelsFallen == 0
        ) {
            newAc.frame = targetFrame;
        }
        else if (oldAc.frame < 2) {
            newAc.frame = 0;
        }
    }
}



class Walker : PerformedActivity {

    enum highestStepUp = 12;

    mixin (CloneByCopyFrom!"Walker");

    override @property bool callBecomeAfterAssignment() const { return false; }

    override void onManualAssignment()
    {
        if (lixxie.ac == Ac.walker
         || lixxie.ac == Ac.runner
         || lixxie.ac == Ac.lander) {
            turn();
            // frame should be set to -1 by the implementation
        }
        else if (lixxie.ac == Ac.stunner
              || lixxie.ac == Ac.ascender) {
            // priority allows to get here only when the frame is high enough
            become(Ac.walker);
            turn();
        }
        else if (lixxie.ac == Ac.blocker) {
            if (frame < 20)
                frame = 21;
                // frame should be set to 20 by the implementation
            else
                // during the blocker->walker transistion, allow turning
                // by a second walker assignment
                turn();
        }
        else if (lixxie.ac == Ac.platformer && frame > 5) {
            become(Ac.shrugger2);
            // See also the next else-if.
            // Clicking twice on the platformer shall turn it around.
        }
        else if (lixxie.ac == Ac.shrugger || lixxie.ac == Ac.shrugger2) {
            become(Ac.walker);
            turn();
        }
        else {
            become(Ac.walker);
        }
    }



    override void onBecome()
    {
        if (abilityToRun)
            become(Ac.runner);
        else
            this.setFrameAfterShortFallTo(8);
    }



    override void performActivity()
    {
        if (isLastFrame)
            frame = 3;
        else
            advanceFrame();

        performWalkingOrRunning();
    }



    protected final void performWalkingOrRunning()
    {
        immutable oldEx = ex;
        immutable oldEy = ey;
        immutable oldEncFoot = footEncounters;
        immutable oldEncBody = bodyEncounters;

        // The first frame is a short break taken after standing up or
        // falling onto this position. performActivity has already advanced
        // the frame, so we have to check frame 0, not frame -1.
        if (frame != 0)
            moveAhead();

        immutable bool turnAfterAll = handleWallOrPitHere();

        if (turnAfterAll) {
            // Start climbing or turn. Either happens at the old position, so
            // we have to reset position and encounters to where we started.
            ex = oldEx;
            ey = oldEy;
            forceBodyAndFootEncounters(oldEncBody, oldEncFoot);
            bool climbedAfterAll = false;

            if (abilityToClimb) {
                bool enoughSpaceToClimb = true;
                for (int i = 1; i <= highestStepUp; ++i)
                    if (isSolid(0, -i)) {
                        enoughSpaceToClimb = false;
                        break;
                    }
                if (enoughSpaceToClimb) {
                    become(Ac.climber);
                    return;
                }
            }
            turn();
            handleWallOrPitHere();
        }
    }



    // returns true if the lixxie shall turn or can start to climb
    private final bool handleWallOrPitHere()
    {
        // Check for floor at the new position. If there is none, check
        // slightly above -- we don't want to fall through checkerboards,
        // but we want to ascend them.
        if (isSolid() || isSolid(0, 1)) {
            // do the wall check to turn or ascend
            immutable int upBy = solidWallHeight(0);
            if (upBy > highestStepUp)
                return true;
            else if (upBy >= 6)
                become(Ac.ascender);
            else
                moveUp(upBy);
        }

        // No floor? Then step down or start falling
        else {
            assert (! isSolid(0, 1) && ! isSolid(0, 2));
            immutable spaceBelowForAnyFalling = 7;
            immutable spaceBelowForNormalFalling = 9;
            int       spaceBelow = 1; // because of the assertions
            while (spaceBelow < spaceBelowForNormalFalling
                && ! isSolid(0, spaceBelow + 2)
            ) {
                ++spaceBelow;
            }

            void becomeFallerAndFallPixels(in int fallY)
            {
                lixxie.moveDown(fallY);
                lixxie.become(Ac.faller);
                Faller perfFaller = cast (Faller) lixxie.performedActivity;
                assert (perfFaller);
                perfFaller.pixelsFallen = fallY;
            }

            if (spaceBelow >= spaceBelowForNormalFalling)
                becomeFallerAndFallPixels(2);
            else if (spaceBelow >= spaceBelowForAnyFalling)
                // Space 7 -> fall 3. Space 8 -> fall 4.
                // Space >= 9 -> fall 2, but that's handled by the 'if' above.
                becomeFallerAndFallPixels(spaceBelow - 4);
            else
                moveDown(spaceBelow);
        }
        return false;
    }
    // end method handleWallOrPitHere()
}



class Runner : Walker {

    mixin (CloneByCopyFrom!"Runner");

    override @property bool callBecomeAfterAssignment() const { return false; }

    override void onManualAssignment()
    {
        assert (! abilityToRun);
        abilityToRun = true;
    }

    override void onBecome()
    {
        assert (abilityToRun);
        this.setFrameAfterShortFallTo(6);
    }

    override void performActivity()
    {
        if (isLastFrame)
            frame = 1;
        else
            advanceFrame();

        // A runner performs two walker cycles per frame, unless stuff happens.
        immutable oldDir = dir;
        performWalkingOrRunning();
        if (lixxie.ac == Ac.runner && oldDir == dir)
            performWalkingOrRunning();
    }

}
