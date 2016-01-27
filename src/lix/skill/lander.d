module lix.skill.lander;

import lix;

class Lander : Job {

    mixin(CloneByCopyFrom!"Lander");

    override void onBecome() {
        if (lixxie.ac == Ac.faller) {
            auto oldAc = cast (const(Faller)) lixxie.job;
            assert (oldAc);
            if (oldAc.frame < 3)
                frame = 1;
            // otherwise, use the regular frame 0
        }
    }

    override void perform()
    {
        if (isLastFrame)
            become(Ac.walker);
        else
            advanceFrame();
    }

}
