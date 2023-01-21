module lix.skill.batter;

import std.math;
import std.range;

import basics.rect;
import hardware.sound;
import lix;
import physics.tribe;

class Batter : Job {
    mixin JobChild;

    enum flingAfterFrame = 2;
    enum flingSpeedX =  10;
    enum flingSpeedY = -12;

    override @property bool blockable() const { return false; }

    override PhyuOrder updateOrder() const
    {
        if (frame == flingAfterFrame) return PhyuOrder.flinger;
        else                          return PhyuOrder.peaceful;
    }

    override void perform()
    {
        if (! isSolid) {
            become(Ac.faller);
            return;
        }
        else if (isLastFrame) {
            become(Ac.walker);
            return;
        }
        if (updateOrder == PhyuOrder.flinger)
            flingEverybody();
        advanceFrame();
    }

private:
    void flingEverybody()
    {
        bool hit = false;
        foreach (Tribe battedTribe; outsideWorld.state.tribes)
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
        if (! target.healthy)
            return false;

        Rect sweetZone = Rect(ex - 12 + 6 * dir, ey - 16, 26, 25);
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
            sweetZone.x -= facingRight ? extraBackward : extraForward;
            sweetZone.xl += extraBackward + extraForward;
        }
        return env.isPointInRectangle(Point(target.ex, target.ey), sweetZone)
            && lixxie !is target
            // Do not allow the same player's batters to bat each other.
            // This is important for singleplayer: two lixes shall not be able
            // to travel together without any help, one shall stay behind.
            // Solution: If we already have a fling assignment, probably
            // from other batters, we cannot bat batters from our own tribe.
            && ! (this.flingNew && target.style == this.style
                    && target.ac == Ac.batter && target.frame == frame);
    }

    void fling(Lixxie target, in int targetId)
    {
        target.addFling(flingSpeedX * dir, flingSpeedY, style == target.style);
        assert (outsideWorld);
        if (outsideWorld.effect)
            outsideWorld.effect.addSound(lixxie.outsideWorld.state.age,
                Passport(target.style, targetId), Sound.BATTER_HIT);
    }
}
