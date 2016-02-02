module lix.skill.floater;

import std.algorithm;

import basics.help;
import lix;

class Floater : Job {

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
            auto fa = cast (const Faller) job;
            assert (fa);
            speedY = fa.ySpeed;
        }
        else if (lixxie.ac == Ac.jumper || lixxie.ac == Ac.tumbler) {
            auto bf = cast (const BallisticFlyer) job;
            assert (bf);
            speedX = bf.speedX;
            speedY = bf.speedY;
        }
    }

    override void perform()
    {
        adjustFrame();
        adjustSpeed();
        move();
    }

private:

    void adjustFrame()
    {
        if (isLastFrame)
            frame = 9;
        else
            advanceFrame();
    }

    void adjustSpeed()
    {
        switch (frame) {
            case 0: break;
            case 1: speedY = speedY > 10 ? 10 : 6; break;
            case 2: speedY = 6; break;
            case 3: speedY = 2; break;
            case 4:
            case 5: speedY = 0; break;
            case 6: speedY = 2; break;
            default: speedY = 4; break;
        }
        if (speedX > 0 && frame > 1)
            speedX = even(speedX - 2);
    }

    void move()
    {
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
        assert (this is lixxie.job);
        moveAhead(speedX);
        moveDown (speedY - wallHitMovedDownY);
    }
}
