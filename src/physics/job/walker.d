module physics.job.walker;

import physics.job;

class Walker : Job {
public:
    enum highestStepUp = 12;

    override AfterAssignment onManualAssignment(Job old)
    {
        // In general: Since we have callBecomeAfterAssignment == false,
        // if we decide to become walker after all, we have to set our frame
        // manually.
        if (old.ac == Ac.walker || old.ac == Ac.runner || old.ac == Ac.lander){
            lixxie.turn();
            old.frame = -1;
            return AfterAssignment.doNotBecome;
        }
        else if (old.ac == Ac.stunner || old.ac == Ac.ascender) {
            // priority allows to get here only when the frame is high enough
            lixxie.become(Ac.walker);
            lixxie.turn();
            frame = -1;
            return AfterAssignment.weAlreadyBecame;
        }
        else if (old.ac == Ac.blocker) {
            if (old.frame < 20) {
                // Setting the frame to 21 copies a bug from C++ Lix. There
                // is a frame in the spritesheet (1st of blocker->walker anim)
                // that is not shown at all. The fast resolution of the blocker
                // isn't problematic though. We'll keep it as in C++ for now.
                old.frame = 21;
            }
            else {
                // during the blocker->walker transistion, allow turning
                // by a second walker assignment
                lixxie.turn();
            }
            return AfterAssignment.doNotBecome;
        }
        else if (old.ac == Ac.platformer && old.frame > 5) {
            // Don't become walker immediately, instead go through the nice
            // animation of standing up from kneeling.
            Platformer.abortAndStandUp(lixxie);
            return AfterAssignment.weAlreadyBecame;
            // See also the next else-if.
            // Clicking twice on the platformer shall turn it around.
        }
        else if (old.ac == Ac.shrugger || old.ac == Ac.shrugger2) {
            lixxie.become(Ac.walker);
            lixxie.turn();
            frame = -1;
            return AfterAssignment.weAlreadyBecame;
        }
        else {
            lixxie.become(Ac.walker);
            frame = -1;
            return AfterAssignment.weAlreadyBecame;
        }
    }

    override void onBecome(in Job old)
    {
        if (lixxie.abilityToRun) {
            lixxie.become(Ac.runner);
        }
        else {
            this.setFrameAfterShortFallTo(old, 8);
        }
    }

    override void perform()
    {
        if (lixxie.isLastFrame) {
            frame = 3;
        }
        else {
            lixxie.advanceFrame();
        }
        performWalkingOrRunning();
    }

protected:
    final void performWalkingOrRunning()
    {
        immutable oldEx = lixxie.ex;
        immutable oldEy = lixxie.ey;
        immutable oldEncFoot = lixxie.footEncounters;

        // The first frame is a short break taken after standing up or
        // falling onto this position. perform has already advanced
        // the frame, so we have to check frame 0, not frame -1.
        if (frame != 0) {
            lixxie.moveAhead();
        }
        immutable bool turnAfterAll = handleWallOrPitHere();

        if (turnAfterAll) {
            // Start climbing or turn. Either happens at the old position, so
            // we have to reset position and encounters to where we started.
            lixxie.ex = oldEx;
            lixxie.ey = oldEy;
            lixxie.forceFootEncounters(oldEncFoot);
            bool climbedAfterAll = false;

            if (lixxie.abilityToClimb) {
                bool enoughSpaceToClimb = true;
                for (int i = 1; i <= highestStepUp; ++i)
                    if (lixxie.isSolid(0, -i)) {
                        enoughSpaceToClimb = false;
                        break;
                    }
                if (enoughSpaceToClimb) {
                    lixxie.become(Ac.climber);
                    return;
                }
            }
            lixxie.turn();
            handleWallOrPitHere();
        }
    }

    void setFrameAfterShortFallTo(in Job old, int targetFrame)
    {
        if (old.ac == Ac.faller) {
            auto faller = cast (const(Faller)) old;
            assert (faller);
            if (   faller.pixelsFallen <= 9 && faller.frame < 1
                || faller.pixelsFallen == 0
            ) {
                this.frame = targetFrame;
            }
            else if (old.frame < 2) {
                this.frame = 0;
            }
        }
    }

private:
    // returns true if the lixxie shall turn or can start to climb
    final bool handleWallOrPitHere()
    {
        // Check for floor at the new position. If there is none, check
        // slightly above -- we don't want to fall through checkerboards,
        // but we want to ascend them.
        if (lixxie.isSolid() || lixxie.isSolid(0, 1)) {
            // do the wall check to turn or ascend
            immutable int upBy = lixxie.solidWallHeight(0);
            if (upBy > highestStepUp)
                return true;
            else if (upBy >= 6)
                lixxie.become(Ac.ascender);
            else
                lixxie.moveUp(upBy);
        }

        // No floor? Then step down or start falling
        else {
            assert (! lixxie.isSolid(0, 1) && ! lixxie.isSolid(0, 2));
            immutable spaceBelowForAnyFalling = 7;
            immutable spaceBelowForNormalFalling = 9;
            int       spaceBelow = 1; // because of the assertions
            while (spaceBelow < spaceBelowForNormalFalling
                && ! lixxie.isSolid(0, spaceBelow + 2)
            ) {
                ++spaceBelow;
            }

            if (spaceBelow >= spaceBelowForNormalFalling)
                Faller.becomeAndFallPixels(lixxie, 2);
            else if (spaceBelow >= spaceBelowForAnyFalling)
                // Space 7 -> fall 3. Space 8 -> fall 4.
                // Space >= 9 -> fall 2, but that's handled by the 'if' above.
                Faller.becomeAndFallPixels(lixxie, spaceBelow - 4);
            else
                lixxie.moveDown(spaceBelow);
        }
        return false;
    }
    // end method handleWallOrPitHere()
}



class Runner : Walker {
public:
    override AfterAssignment onManualAssignment(Job old)
    {
        assert (! lixxie.abilityToRun);
        lixxie.abilityToRun = true;
        if (old.ac == Ac.walker) {
            lixxie.become(Ac.runner);
            frame = 2; // looks best, with a foot on the ground behind
            return AfterAssignment.weAlreadyBecame;
        }
        else
            return AfterAssignment.doNotBecome;
    }

    override void onBecome(in Job old)
    {
        assert (lixxie.abilityToRun);
        this.setFrameAfterShortFallTo(old, 6);
    }

    override void perform()
    {
        if (lixxie.isLastFrame) {
            frame = 1;
        }
        else {
            lixxie.advanceFrame();
        }

        // A runner performs two walker cycles per frame, unless stuff happens.
        immutable oldDir = lixxie.dir;
        performWalkingOrRunning();
        if (lixxie.ac == Ac.runner && oldDir == lixxie.dir)
            performWalkingOrRunning();
    }
}
