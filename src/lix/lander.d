module lix.lander;

import lix;

class Lander : PerformedActivity {

    mixin(CloneByCopyFrom!"Lander");

    override void onBecome() {
        if (lixxie.ac == Ac.FALLER) {
            auto oldAc = cast (const(Faller)) lixxie.performedActivity;
            assert (oldAc);
            if (oldAc.frame < 3)
                frame = 1;
            // otherwise, use the regular frame 0
        }
    }

    override void performActivity(UpdateArgs)
    {
        if (isLastFrame)
            become(Ac.WALKER);
        else
            advanceFrame();
    }

}
