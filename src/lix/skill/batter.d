module lix.skill.batter;

import std.math;

import hardware.sound;
import game.tribe;
import lix;

class Batter : Job {

    enum flingAfterFrame = 2;

    enum rectHalfXl = 12;
    enum rectHalfYl = 12;
    enum extraXRangeForBlockers = 4;

    enum flingSpeedX =  10;
    enum flingSpeedY = -12;

    mixin(CloneByCopyFrom!"Batter");

    override @property bool blockable() const { return false; }

    override UpdateOrder updateOrder() const
    {
        if (frame == flingAfterFrame) return UpdateOrder.flinger;
        else                          return UpdateOrder.peaceful;
    }



    override void perform()
    {
        // be consistent with the update order in game.core.physlix
        immutable bool batNow = (updateOrder == UpdateOrder.flinger);

        if      (! isSolid)   become(Ac.faller);
        else if (isLastFrame) become(Ac.walker);
        else                  advanceFrame();

        if (batNow) {
            bool hit = false;
            foreach (Tribe tribe; outsideWorld.state.tribes)
                foreach (Lixxie lix; tribe.lixvec)
                    if (flingIfCloseTo(lix, ex + 6 * dir, ey - 4))
                        hit = true;
            if (hit) playSound            (Sound.BATTER_HIT);
            else     playSoundIfTribeLocal(Sound.BATTER_MISS);
        }

    }



    private bool flingIfCloseTo(
        Lixxie target,
        in int cx, in int cy, // center of a rectangle
    ) {
        if (! healthy)
            return false;
        // do not allow the same player's batters to bat each other.
        // This is important for singleplayer: two lixes shall not be able
        // to travel together without any help, one shall always be left
        // behind.
        // Solution: If we already have a fling assignment, probably
        // from other batters, we cannot bat batters from our own tribe.

        immutable bool sameTribe =
            // DTODOSKILLS: i.outsideWorld may be null! We would like to
            // compare the two tribes with 'is', but that doesn't work due
            // to the null i.outsideWorld.
            // Hack! We use the style instead of (i.tribe is this.tribe).
            // This is undesirable because style shouldn't affect physics.
            (target.style == this.style);
            // End of hack.

        if (this.flingNew && sameTribe
            && target.ac == Ac.batter && target.frame == frame
        )
            return false;

        immutable bool blo = (target.ac == Ac.blocker);
        immutable int ch = (blo ? cx + extraXRangeForBlockers * dir : cx);
        immutable int dx = ground.distanceX(ch, target.ex).abs;
        immutable int dy = ground.distanceY(cy, target.ey).abs;
        immutable bool fling
            = (dx <= rectHalfXl + (blo ? extraXRangeForBlockers : 0)
            && dy <= rectHalfYl
            && target !is this);
        if (fling)
            target.addFling(flingSpeedX * dir, flingSpeedY, sameTribe);
        return fling;
    }

}
// end class Batter
