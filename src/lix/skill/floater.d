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
        assert (speedX >= 0);
        assert (speedX % 2 == 0);
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
        // How far have we moved during this frame already? move() is 1 frame.
        int flownAhead = 0;
        int flownDown = 0;
        assert (speedX >= 0);

        while (flownAhead < speedX || flownDown < speedY) {
            // Collide with the terrain before moving
            if (this.isSolid(0, 2)) {
                this.become(Ac.lander);
                return;
            }
            else if (this.isSolid(2, 0)) {
                speedX = 0;
                flownAhead = 0;
                if (flownDown >= speedY)
                    break;
            }
            // Path is now clear in both directions. We don't check again
            // after moving, to keep physics equality with 0.6.x for floaters
            // moving straight down.
            immutable ahead
                = flownAhead >= speedX ? false // only y left
                : flownDown >= speedY ? true // only x left
                : flownAhead == 0 && flownDown == 0 ? speedX >= speedY
                : speedX * flownDown >= flownAhead * speedY;
            // In 0.6.0 and C++ Lix, we moved like the chess king.
            // Now, we move orthogonally only, and check in between.
            // That should prevent https://github.com/SimonN/LixD/issues/129.
            if (ahead) {
                moveAhead();
                flownAhead += 2;
            }
            else {
                moveDown(1);
                flownDown += 1;
            }
        }
    }
}
