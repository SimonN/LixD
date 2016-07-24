module lix.skill.floater;

import std.algorithm;

import basics.help;
import lix;

class Floater : Job {

    int speedX = 0;
    int speedY = 0;
    bool accelerateY = false; // if we come from a tumbler, accelerate still

    mixin(CloneByCopyFrom!"Floater");
    void copyFromAndBindToLix(in Floater rhs, Lixxie lixToBindTo)
    {
        super.copyFromAndBindToLix(rhs, lixToBindTo);
        speedX = rhs.speedX;
        speedY = rhs.speedY;
        accelerateY = rhs.accelerateY;
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
            accelerateY = true;
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
        // When the umbrella is open, all floaters behave the same.
        if (frame == 7)
            // final speed
            speedY = 4;
        else if (frame == 6)
            speedY = 2;
        else if (frame == 4) {
            speedX = 0;
            speedY = 0;
        }
        // Before frame 4:
        // We special-case heavily. The tumbler shall fly like the tumbler,
        // so we copy-paste the acceleration from tumbler.d and hope that
        // everything works out with Floater's move().
        // The floater-that-was-faller gets the old C++ behavior, so that
        // as few replays as possible break in July 2016.
        else if (frame < 4) {
            if (accelerateY) {
                // copypasta from tumbler.d, BallisticFlyer.perform()
                if      (speedY <= 12) speedY += 2;
                else if (speedY  < 32) speedY += 1;
            }
            else
                speedY = (frame == 1 ? 6 : frame == 3 ? 2 : speedY);
        }
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
