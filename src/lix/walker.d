module lix.walker;

import lix;

class Walker : PerformedActivity {

    mixin(CloneByCopyFrom);

// DTODO: code copied out of faller, after becoming walker.
// This must be implented in Walker's onBecome.
/+
                else if (pixelsFallen <= 9 && frame < 1
                    ||   pixelsFallen == 0
                ) {
                    become(Ac.WALKER);
                    if (abilityToRun) l.set_frame(6);
                    else              l.set_frame(8);
                    return;
                }
                else if (l.get_frame() < 2) {
                    l.become(LixEn::WALKER);
                    l.set_frame(0);
                    return
                }
+/

    override void onManualAssignment()
    {
/+
        if (ac == Ac.WALKER
         || ac == Ac.RUNNER
         || ac == Ac.LANDER) {
            l.turn();
            // Da bei Walker -> Walker nicht --frame von evaluate_click() kommt,
            // setzen wir hier manuell das Frame auf -1, weil wir das 0. wollen.
            if (ac == Ac.WALKER) frame = -1;
            if (ac == Ac.RUNNER) frame = -1;
        }
        else if (ac == Ac.STUNNER
              || ac == Ac.ASCENDER) {
            // lix_ac.cpp only allows to get here when the frame is high enough
            l.become(Ac.WALKER);
            l.turn();
        }
        else if (ac == Ac.BLOCKER) {
            // Da assign haeufig beim Mausklick-Zuweisen aufgerufen wird, gilt
            // wieder die Konvention, dass --frame hinterher gemacht wird, also:
            if (frame < 20) frame = 21;
            else                    l.turn(); // turn a blocker->walker transistion
        }
        else if (ac == Ac.PLATFORMER && frame > 5) {
            l.set_ac(Ac.SHRUGGER2);
            frame = 9);
            // see also next else if. Clicking twice on the platformer shall turn
            // it around.
        }
        else if (ac == Ac.SHRUGGER || ac == Ac.SHRUGGER2) {
            l.become(Ac.WALKER);
            l.turn();
        }
        else {
            l.become(Ac.WALKER);
        }
+/
    }

    override void onBecome()
    {
    }

    override void performActivity(UpdateArgs)
    {
    }

}
