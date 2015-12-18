module lix.skill.floater;

import std.algorithm;

import basics.help;
import lix;

class Floater : PerformedActivity {

    int speedX = 0;
    int speedY = 0;

    mixin(CloneByCopyFrom!"Floater");
    void copyFromAndBindToLix(in Floater rhs, Lixxie lixToBindTo)
    {
        super.copyFromAndBindToLix(rhs, lixToBindTo);
        speedX = rhs.speedX;
        speedY = rhs.speedY;
    }

    override @property bool callBecomeAfterAssignment() const { return false; }

    override void onManualAssignment()
    {
        assert (! abilityToFloat);
        abilityToFloat = true;
    }



    override void onBecome()
    {
        if (lixxie.ac == Ac.faller) {
            auto fa = cast (const Faller) performedActivity;
            assert (fa);
            speedY = fa.ySpeed;
        }
        else if (lixxie.ac == Ac.jumper || lixxie.ac == Ac.tumbler) {
            auto bf = cast (const BallisticFlyer) performedActivity;
            assert (bf);
            speedX = bf.speedX;
            speedY = bf.speedY;
        }
    }



    override void performActivity()
    {
        if (isLastFrame) frame = 9;
        else             advanceFrame();

        enum int[] spd = [16, 10, 6, 2, 0, 0, 2, 4];
        speedY = (frame < 2)       ? min(speedY, spd[frame])
               : (frame < spd.len) ? spd[frame]
               : speedY;

        if (speedX > 0 && frame > 1)
            speedX = even(speedX - 2);

        // The following code is a little like BallisticFlyer.collision().
        // I don't dare to use that code for floaters too. It's already very
        // complicated and many of its corner cases don't apply to floaters.
        int  wallHitMovedDownY = 0;
        immutable maxSpeed = max(speedX, speedY);

        for (int i = 0; i < maxSpeed; ++i) {
            // move either 1 pixel down, 1 pixel ahead, or 1 pixel both. This
            // takes max(spx, spy) chess king moves to get to target square.
            immutable int x = even(speedX * i / maxSpeed);
            immutable int y =      speedY * i / maxSpeed;
            if (isSolid(x, y + 2)) {
                moveAhead(x);
                moveDown(y);
                become(Ac.lander);
                return;
            }
            else if (isSolid(x + 2, y) && speedX > 0) {
                wallHitMovedDownY = y;
                moveAhead(x); // DTODOSKILLS: test this, compare with C++
                moveDown(y);
                speedX = 0;
            }
        }
        assert (this is lixxie.performedActivity);
        moveAhead(speedX);
        moveDown (speedY - wallHitMovedDownY);
    }
    // end performActivity()
}
