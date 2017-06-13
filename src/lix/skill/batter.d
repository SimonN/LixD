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

    override PhyuOrder updateOrder() const
    {
        if (frame == flingAfterFrame) return PhyuOrder.flinger;
        else                          return PhyuOrder.peaceful;
    }

    override void perform()
    {
        // be consistent with the update order in game.core.physlix
        immutable bool batNow = (updateOrder == PhyuOrder.flinger);

        if      (! isSolid)   become(Ac.faller);
        else if (isLastFrame) become(Ac.walker);
        else                  advanceFrame();

        if (batNow) {
            bool hit = false;
            foreach (Tribe battedTribe; outsideWorld.state.tribes)
                foreach (int battedID, Lixxie battedLix; battedTribe.lixvec)
                    if (flingIfCloseTo(battedLix, lixxie.ex + 6 * lixxie.dir,
                                                  lixxie.ey - 4)) {
                        hit = true;
                        if (lixxie.outsideWorld.effect)
                            lixxie.outsideWorld.effect.addSound(
                            lixxie.outsideWorld.state.update, battedLix.style,
                            battedID, Sound.BATTER_HIT);
                    }
            // Both the hitter and the target will play the hit sound.
            // This hitting sound isn't played even quietly if an enemy lix
            // hits an enemy lix, but we want the sound if we're involved.
            lixxie.playSound(hit ? Sound.BATTER_HIT : Sound.BATTER_MISS);
        }

    }

private:
    // cx, cy: Specify the center of a rectangle
    // Returns whether the target lix has been flung by us.
    bool flingIfCloseTo(Lixxie target, in int cx, in int cy)
    {
        if (! healthy)
            return false;
        // Do not allow the same player's batters to bat each other.
        // This is important for singleplayer: two lixes shall not be able
        // to travel together without any help, one shall always be left
        // behind.
        // Solution: If we already have a fling assignment, probably
        // from other batters, we cannot bat batters from our own tribe.

        immutable bool sameTribe = (target.style == this.style);
        if (this.flingNew && sameTribe
                          && target.ac == Ac.batter && target.frame == frame)
            return false;

        immutable bool blo = (target.ac == Ac.blocker);
        immutable int ch = (blo ? cx + extraXRangeForBlockers * dir : cx);
        immutable int dx = env.distanceX(ch, target.ex).abs;
        immutable int dy = env.distanceY(cy, target.ey).abs;
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
