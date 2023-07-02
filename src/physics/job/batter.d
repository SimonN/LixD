module physics.job.batter;

import std.math;
import std.range;

import basics.rect;
import hardware.sound;
import physics.job;
import physics.lixxie.lixxie;
import physics.tribe;

class Batter : Job {
    enum flingAfterFrame = 2;
    enum flingSpeedX =  10;
    enum flingSpeedY = -12;

    override bool blockable() const { return false; }

    override PhyuOrder updateOrder() const
    {
        if (frame == flingAfterFrame) return PhyuOrder.flinger;
        else                          return PhyuOrder.peaceful;
    }

    override void perform()
    {
        if (! lixxie.isSolid) {
            lixxie.become(Ac.faller);
            return;
        }
        else if (lixxie.isLastFrame) {
            lixxie.become(Ac.walker);
            return;
        }
        if (updateOrder == PhyuOrder.flinger)
            flingEverybody();
        lixxie.advanceFrame();
    }

private:
    void flingEverybody()
    {
        bool hit = false;
        foreach (Tribe battedTribe; lixxie.outsideWorld.state.tribes)
            foreach (id, Lixxie target; battedTribe.lixvec.enumerate!int) {
                if (! shouldWeFling(target))
                    continue;
                hit = true;
                fling(target, id);
            }
        // Both the hitter and the target will play the hit sound.
        // This hitting sound isn't played even quietly if an enemy lix
        // hits an enemy lix, but we want the sound if we're involved.
        lixxie.playSound(hit ? Sound.BATTER_HIT : Sound.BATTER_MISS);
    }

    bool shouldWeFling(in Lixxie target)
    {
        if (! target.healthy) {
            return false;
        }
        Rect sweetZone = Rect(
            lixxie.ex - 12 + 6 * lixxie.dir,
            lixxie.ey - 16,
            26, 25);
        if (target.ac == Ac.blocker) {
            /*
             * Extend the backwards range as far as possible so that this:
             *      1. Faller falls onto a blocker.
             *      2. Blocker turns faller away during faller's fall.
             *      3. Assign batter to the lander.
             * ... bats the blocker, but that this:
             *      1. Walker walks towards a blocker.
             *      2. Blocker turns walker.
             *      3. Assign batter to walker immediately after turning.
             * ...still misses the blocker.
             */
            enum extraBackward = Blocker.forceFieldXlEachSide - 8;
            enum extraForward = 8; // Keep 0.9 behavior, even though it's a lot
            static assert (extraBackward > 0);
            sweetZone.x -= lixxie.facingRight ? extraBackward : extraForward;
            sweetZone.xl += extraBackward + extraForward;
        }
        return lixxie.env.isPointInRectangle(Point(target.ex, target.ey),
            sweetZone) && lixxie !is target
            // Do not allow the same player's batters to bat each other.
            // This is important for singleplayer: two lixes shall not be able
            // to travel together without any help, one shall stay behind.
            // Solution: If we already have a fling assignment, probably
            // from other batters, we cannot bat batters from our own tribe.
            && ! (lixxie.flingNew && target.style == lixxie.style
                    && target.ac == Ac.batter && target.frame == frame);
    }

    void fling(Lixxie target, in int targetId)
    {
        target.addFling(flingSpeedX * lixxie.dir, flingSpeedY,
            lixxie.style == target.style);
        assert (lixxie.outsideWorld);
        lixxie.outsideWorld.effect.addSound(lixxie.outsideWorld.state.age,
            Passport(target.style, targetId), Sound.BATTER_HIT);
    }
}
