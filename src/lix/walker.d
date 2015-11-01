module lix.walker;

import lix;

private void
setFrameAfterShortFallTo(PerformedActivity newAc, int targetFrame)
{
    if (newAc.lixxie.ac == Ac.FALLER) {
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

    mixin (CloneByCopyFrom);

    override @property bool callBecomeAfterAssignment() const { return false; }

    override void onManualAssignment()
    {
        if (lixxie.ac == Ac.WALKER
         || lixxie.ac == Ac.RUNNER
         || lixxie.ac == Ac.LANDER) {
            turn();
            // frame should be set to -1 by the implementation
        }
        else if (lixxie.ac == Ac.STUNNER
              || lixxie.ac == Ac.ASCENDER) {
            // priority allows to get here only when the frame is high enough
            become(Ac.WALKER);
            turn();
        }
        else if (lixxie.ac == Ac.BLOCKER) {
            if (frame < 20)
                frame = 21;
                // frame should be set to 20 by the implementation
            else
                // during the blocker->walker transistion, allow turning
                // by a second walker assignment
                turn();
        }
        else if (lixxie.ac == Ac.PLATFORMER && frame > 5) {
            become(Ac.SHRUGGER2);
            frame = 9;
            // See also the next else-if.
            // Clicking twice on the platformer shall turn it around.
        }
        else if (lixxie.ac == Ac.SHRUGGER || lixxie.ac == Ac.SHRUGGER2) {
            become(Ac.WALKER);
            turn();
        }
        else {
            become(Ac.WALKER);
        }
    }



    override void onBecome()
    {
        if (abilityToRun)
            become(Ac.RUNNER);
        else
            this.setFrameAfterShortFallTo(8);
    }



    override void performActivity(UpdateArgs ua)
    {
        if (isLastFrame)
            frame = 3;
        else
            advanceFrame();

        performWalkingOrRunning(ua);
    }



    protected final void performWalkingOrRunning(UpdateArgs ua)
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

        bool turnAfterAll = handleWallOrPitHere();

        if (turnAfterAll) {
            // start climbing or turn, both happens at the old position
            ex = oldEx;
            ey = oldEy;
            forceBodyAndFootEncounters(oldEncBody, oldEncFoot);
            bool climbedAfterAll = false;

            /+
            if (l.get_climber()) {
                // Auf Landschaft über der derzeitigen Position prüfen
                bool enough_space = true;
                for (int i = 1; i < 13; ++i) {
                    if (l.is_solid(0, -i)) {
                        enough_space = false;
                        break;
                    }
                }
                if (enough_space) {
                    l.become(LixEn::CLIMBER);
                    climbed_after_all = true;
                }
            }
            if (! climbed_after_all) {
                l.turn();
                // this new check will take care of the bugs around 2012-02,
                // the lix didn't ascend or fall when caught in 2-pixel gaps.
                handleWallOrPitHere(l);
            }
            +/
        }
        // Ende der Umdrehen-Kontrolle
    }



    private final bool handleWallOrPitHere()
    {
        bool turnAfterAll = false;
/+
        // Pruefung auf Boden unter der neuen Position
        // Falls da nichts ist, gucken wir etwas darüber nach - vielleicht
        // handelt es sich um eine sehr dünne Aufwärts-Brücke, durch die
        // wir nicht hindurchfallen wollen?
        if (l.is_solid() || l.is_solid(0, 1)) {
            // do the wall check to turn or ascend
            int up_by = l.solid_wall_height(0);
            if      (up_by == 13) turnAfterAll = true;
            else if (up_by >=  6) l.become(LixEn::ASCENDER);
            else                  l.move_up(up_by);
        }
        // Ende von "Boden unter den Füßen"

        // Kein Boden? Dann hinunter gehen oder zu fallen beginnen
        else {
            int moved_down_by = 0;
            for (int i = 3; i < 11; ++i) {
                if (!l.is_solid()) {
                    l.move_down(1);
                    ++moved_down_by;
                }
                else break;
            }
            if (l.is_solid()) {
                // Bei zu starker Steigung umdrehen
                if (l.solid_wall_height(0) == 11) {
                    turnAfterAll = true;
                }
                // Don't move that far back up as the check about 10 lines further
                // down that reads very similar in its block
                else if (moved_down_by > 6) {
                    l.move_up(4);
                    l.become(LixEn::FALLER);
                    l.set_special_x(moved_down_by - 4);
                }
            }
            else {
                // Aber nicht direkt so weit nach unten zum Fallen bewegen
                l.move_up(6);
                l.become(LixEn::FALLER);
                l.set_special_x(2);
            }
        }
+/
        return turnAfterAll;
    }
    // end method handleWallOrPitHere()
}



class Runner : Walker {

    mixin (CloneByCopyFrom);

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

    override void performActivity(UpdateArgs ua)
    {
        if (isLastFrame)
            frame = 1;
        else
            advanceFrame();

        // A runner performs two walker cycles per frame, unless stuff happens.
        immutable oldDir = dir;
        performWalkingOrRunning(ua);
        if (lixxie.ac == Ac.RUNNER && oldDir == dir)
            performWalkingOrRunning(ua);
    }

}
