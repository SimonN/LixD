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
    {   /*
         * This function performWalkingOrRunning() will be called far more
         * often than anything else. Let's keep it fast. Avoid reading the
         * same terrain more than once; instead, cache and reuse such reads.
         */
        int wall = void;
        bool floorIsSolid = void;

        if (frame == 0) {
            /*
             * The first frame is a short break taken after standing up or
             * falling onto this position. perform has already advanced
             * the frame, so we have to check frame 0, not frame -1.
             * Don't attempt forward motion here (only cache some terrain).
             */
            wall = lixxie.solidWallHeight(0, 0);
            floorIsSolid = canWeStandAt(0);
        }
        else {
            // Move forward or, if we can't, react to the wall that stops us.
            wall = lixxie.solidWallHeight(2, 0);
            floorIsSolid = canWeStandAt(2);
            if (! floorIsSolid || wall <= highestStepUp) {
                /*
                 * We are not in front of a tall wall.
                 * Move even without ground: This is airwalk. Bug or feature?
                 * See: https://www.lemmingsforums.net/index.php?topic=4005.0
                 */
                lixxie.moveAhead();
            }
            // In front of a tall wall, either climb or turn.
            else if (lixxie.abilityToClimb && hasSpaceToClimbHere()) {
                lixxie.become(Ac.climber);
                return;
            }
            else {
                lixxie.turn();
                wall = lixxie.solidWallHeight(0, 0);
                floorIsSolid = canWeStandAt(0);
            }
        }
        /*
         * Here, we're still a walker/runner.
         * We moved ahead, or turned, or stayed in place because frame == 0.
         * In all three cases, now (wall) is the wall height at our foot's x
         * and (floorIsSolid) is what canWeStandAt(0) would give.
         */
        if (! floorIsSolid) {
            stepDownOrStartFalling();
            return;
        }
        // We're still a walker/runner. Stepping up without turning/climbing.
        if (wall > highestStepUp) {
            // We're trapped inside solid terrain.
        }
        else if (wall >= 6) {
            lixxie.become(Ac.ascender);
        }
        else {
            lixxie.moveUp(wall);
        }
    }

    final void setFrameAfterShortFallTo(in Job old, int targetFrame)
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
    final bool canWeStandAt(in int xAhead)
    {
        return lixxie.isSolid(xAhead, 2) // Floor below foot.
            || lixxie.isSolid(xAhead, 1); // Floor above foot, for checkerboarding:
        // Don't fall through checkerboards; but ascend them.
    }

    final bool hasSpaceToClimbHere()
    {
        for (int i = 1; i <= highestStepUp; ++i)
            if (lixxie.isSolid(0, -i))
                return false;
        return true;
    }

    final void stepDownOrStartFalling() {
        assert (! canWeStandAt(0));
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
}



final class Runner : Walker {
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
        if (lixxie.ac == Ac.runner && oldDir == lixxie.dir) {
            performWalkingOrRunning();
        }
    }
}
