module lix.skill.lander;

import lix;

class Lander : Job {
    override void onBecome(in Job old) {
        if (old.ac == Ac.faller) {
            auto faller = cast (const(Faller)) old;
            assert (faller);
            if (faller.frame < 3)
                frame = 1;
            // otherwise, use the regular frame 0
        }
    }

    override void perform()
    {
        if (lixxie.isLastFrame) {
            lixxie.become(Ac.walker);
        }
        else {
            lixxie.advanceFrame();
        }
    }
}
