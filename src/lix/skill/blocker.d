module lix.skill.blocker;

import std.math; // abs

import lix;
import physics.tribe;

class Blocker : Job {
    mixin JobChild;

    // blockers have a 1-lo-res pixel (= 2 hi-res pixel) dead zone in their
    // center, then turn lems if (blocker's x - other lem's x).abs is strictly
    // less than forceFieldXlEachSide.
    enum forceFieldXlEachSide = 14;
    enum forceFieldYlAbove = 16;
    enum forceFieldYlBelow = 8;

    override @property bool blockable() const { return false; }
    override PhyuOrder updateOrder() const { return PhyuOrder.blocker; }

    override void perform()
    {
        if (! isSolid()) {
            become(Ac.faller);
            return;
        }
        else if (frame == 19) {
            frame = 4;
        }
        else if (isLastFrame) {
            // assignment (blocker -> walker): we remain blocker for a while,
            // and become a walker only at this point in time
            become(Ac.walker);
            return;
        }
        else {
            advanceFrame();
        }
        assert (lixxie.ac == Ac.blocker);
        blockOtherLix();
    }

    private final void blockOtherLix()
    {
        foreach (Tribe tribe; outsideWorld.state.tribes)
            foreach (Lixxie li; tribe.lixvec)
                if (li.job.blockable)
                    blockSingleLix(li);
    }

    private final void blockSingleLix(Lixxie li)
    {
        immutable int dx = env.distanceX(li.ex, this.ex);
        immutable int dy = env.distanceY(li.ey, this.ey);

        // li is inside the rectangular blocker force field?
        if (abs(dx) < forceFieldXlEachSide
            && dy > - forceFieldYlBelow
            && dy <   forceFieldYlAbove
        ) {
            immutable inR2LField = dx > 0; // li is in a field that turns r->l
            immutable inL2RField = dx < 0; // li is on the right side of us
            if (inR2LField && li.facingRight || inL2RField && li.facingLeft) {
                if (! li.turnedByBlocker)
                    li.turn;
                li.turnedByBlocker = true;
            }
            li.inBlockerFieldLeft  = li.inBlockerFieldLeft  || inR2LField;
            li.inBlockerFieldRight = li.inBlockerFieldRight || inL2RField;
        }
    }
}
// end class Blocker
