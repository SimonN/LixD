module lix.walker;

import lix;

class Walker : PerformedActivity {

    mixin(CloneByCopyFrom);

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
            // see also next else if. Clicking twice on the platformer shall turn
            // it around.
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
        if (lixxie.ac == Ac.FALLER) {
            auto oldAc = cast (const(Faller)) lixxie.performedActivity;
            assert (oldAc);
            if (   oldAc.pixelsFallen <= 9 && oldAc.frame < 1
                || oldAc.pixelsFallen == 0
            ) {
                if (abilityToRun) frame = 6; // runner frame
                else              frame = 8; // walker frame
            }
            else if (oldAc.frame < 2) {
                frame = 0;
            }
        }
    }



    override void performActivity(UpdateArgs)
    {
    }

}
