module lix.skill.tumbler;

import std.algorithm;
import std.format; // assert errors
import std.math; // abs

import basics.help;
import lix;

private enum PleaseDo : ubyte {
    nothing,         // nothing hit, keep moving
    stopMovement,    // hit something, stop, remain in place with state
    resetEncounters, // we un-glitched out of sth., so reset encounters
    resetPosition,   // we hit something, didn't un-glitch yet

    // we hit something, but must work around github LixD issue #231:
    // oscillating tumbler in thin wall. If our last single-pixel sub-frame
    // movement was horizontally, treat like PleaseDo.resetPosition. Otherwise,
    // treat line PleasDo.nothing.
    resetPositionIfMovedX,
}

abstract class BallisticFlyer : Job {

    int speedX; // should be >= 0. Is really speed ahead, not absolute x dir.
    int speedY;
    int pixelsFallen; // always >= 0. Upflinginging keeps 0. Resets on fling.

    mixin JobChild;

    enum speedYToFloat = 15;
    enum pixelsSafeToFall = {
       import lix.skill.faller; return Faller.pixelsSafeToFall;
    }();

    protected void copyFrom(in BallisticFlyer rhs)
    {
        assert (rhs, "can't copy from null job");
        speedX = rhs.speedX;
        speedY = rhs.speedY;
        pixelsFallen = rhs.pixelsFallen;
    }

    final override void perform()
    {
        assert (speedX >= 0, "Lix should only fly forwards. Turn first.");
        if (speedX % 2 != 0)
            ++speedX;
        if (moveSeveralTimes() == BecomeCalled.yes) {
            return;
        }
        speedY += accel(speedY);
        selectFrame();
        if (speedY >= speedYToFloat) {
            if      (abilityToFloat)  become(Ac.floater);
            else if (ac == Ac.jumper) become(Ac.tumbler);
        }
    }

protected:

    struct Collision {
        BecomeCalled becomeCalled;
        PleaseDo pleaseDo;
    }

    final bool wall  (in int y) { return isSolid(0, y); }
    final bool behind(in int y) { return wall(y) && isSolid(-2, y); }

    enum int biggestLargeAccelSpeedY = 12;
    final static int accel(int ysp) pure
    {
        return (ysp <= biggestLargeAccelSpeedY) ? 2 : (ysp < 32) ? 1 : 0;
    }

    bool splatUpsideDown() const { return false; }

    abstract Collision onHittingWall();
    abstract BecomeCalled onLandingWithoutSplatting();
    abstract void selectFrame();

private:

    final BecomeCalled landOnFloor()
    {
        if (pixelsFallen > pixelsSafeToFall && ! abilityToFloat) {
            immutable sud = this.splatUpsideDown();
            become(Ac.splatter);
            if (sud)
                lixxie.frame = 10;
            return BecomeCalled.yes;
        }
        else
            return onLandingWithoutSplatting();
    }

    // returns true iff weCalledBecome
    final BecomeCalled moveSeveralTimes()
    {
        immutable int ySgn = speedY >= 0 ? 1 : -1;
        immutable int yAbs = speedY.abs;

        // advance diagonally, examine collisions at each step.
        BREAK_MOTION:
        foreach(int step; 0 .. max(yAbs, speedX)) {
            immutable oldEx = ex;
            immutable oldEy = ey;
            immutable oldFallen = pixelsFallen;
            immutable oldEncFoot = footEncounters;

            void moveDownCounting(int by)
            {
                lixxie.moveDown(by);
                if (by >= 0)
                    pixelsFallen += by;
                else
                    pixelsFallen = 0;
            }

            if (yAbs >= speedX) {
                // move ahead occasionally only. / 2 * 2 to keep stuff even.
                immutable int halfX = (step + 1) * speedX / 2 / yAbs
                                    - (step)     * speedX / 2 / yAbs;
                assert (halfX == 0 || halfX == 1);
                moveAhead(2 * halfX);
                moveDownCounting(ySgn);
            }
            else {
                // move down occasionally only
                moveDownCounting(ySgn * ( (step + 1) * yAbs / speedX
                                        - (step)     * yAbs / speedX));
                moveAhead(2 * (step & 1));
            }

            Collision col = collision();
            if (col.pleaseDo == PleaseDo.nothing ||
                col.pleaseDo == PleaseDo.resetPositionIfMovedX && ex == oldEx)
                { }
            else if (col.pleaseDo == PleaseDo.stopMovement) {
                return col.becomeCalled;
            }
            else if (col.pleaseDo == PleaseDo.resetEncounters) {
                forceFootEncounters(oldEncFoot);
                ey = ey; // re-check encounters here
                return col.becomeCalled;
            }
            else if (col.pleaseDo == PleaseDo.resetPosition ||
                col.pleaseDo == PleaseDo.resetPositionIfMovedX && ex != oldEx
            ) {
                forceFootEncounters(oldEncFoot);
                ex = oldEx;
                ey = oldEy;
                pixelsFallen = oldFallen;
                if (isSolid(0, 1)) {
                    // completely immobilized
                    become(Ac.stunner);
                    return BecomeCalled.yes;
                }
                return col.becomeCalled;
            }
            else {
                assert (false);
            }
        }
        // end BREAK_MOTION: foreach
        return BecomeCalled.no;
    }

    // Horrible function. Copied out of C++ Lix almost unaltered.
    // We'd have to be really smart to make this simpler.
    // Comments within this function are taken from C++ Lix, too.
    final Collision collision()
    {
        int wall_count   = 0;
        int wall_count_t = 0; // for turning at a wall
        int swh          = 0; // solid wall height starting above (0, 2)
        int lowest_floor = -999; // a default value for "no floor here at all"
        int behind_count = 0;

        for (int i = 1; i > -16; --i)
            // i <= -1 is tested because the lowest floor check also starts
            // at -1 and goes further into the negatives. If we don't do that,
            // we might enter not the ascender check, but instead the climber
            // check while being sure that we can't ascend,
            // leading to the ascender in midair bug. (level: No more Clowns)
            if (wall(i)) {
                ++wall_count;
                if (i <= -1 && i > -11) ++wall_count_t;
            }

        // how high is a solid wall starting above (0, 2)?
        for (int i = 1; i > -16; --i) {
            if (wall(i)) ++swh;
            else break;
        }

        for (int i = -1; i > -9; --i)
            behind_count += behind(i);

        for (int i = -1; i > -15; --i)
            if (! wall(i-1) && wall(i)) {
                lowest_floor = i;
                break;
            }

        // We have already advanced to the current pixel.

        // floor
        immutable bool down = (speedY > 0);
        if (   (swh <= 2 && isSolid(0, 1) && (isSolid(2, 0) || down))
            || (swh <= 2 && isSolid(0, 2) && (isSolid(2, 1) || down))
        ) {
            while (isSolid(0, 1)) moveUp(1);
            auto bec = landOnFloor();
            return Collision(bec, PleaseDo.resetEncounters);
        }
        // Stepping up a step we jumped onto
        if (lowest_floor != -999
            && ac == Ac.jumper
            && (lowest_floor > -9
                || (abilityToClimb && ! behind(lowest_floor)))
        ) {
            become(Ac.ascender);
            return Collision(BecomeCalled.yes, PleaseDo.resetEncounters);
        }
        // bump head into ceilings
        if ((behind_count > 0 && speedY < 2)
            || (wall(-12) && ! wall_count_t && speedY < 0)
        ) {
            auto bec = BecomeCalled.no;
            if (ac != Ac.tumbler) {
                become(Ac.tumbler);
                bec = BecomeCalled.yes;
            }
            auto tumbling = cast (BallisticFlyer) lixxie.job;
            assert (tumbling);
            tumbling.speedY = 4;
            tumbling.speedX = this.speedX / 2;
            return Collision(bec, isSolid(0, 1) ? PleaseDo.resetPosition
                                                : PleaseDo.stopMovement);
        }
        // Jumping against a wall
        if (wall_count_t)
            return onHittingWall();
        return Collision(BecomeCalled.no, PleaseDo.nothing);
    }
    // end collision()
}



// ############################################################################
// ############################################################################
// ############################################################################



class Jumper : BallisticFlyer {
    mixin JobChild;

    override void onBecome(in Job old)
    {
        if (abilityToRun) {
            speedX =   8;
            speedY = -12;
            frame  =  13; // 1 will be deducted from this
        }
        else {
            speedX =  6;
            speedY = -8;
        }
        for (int i = -4; i > -16; --i)
            if (isSolid(0, i)) {
                become(Ac.stunner);
                return;
            }
    }

protected:

    override BecomeCalled onLandingWithoutSplatting()
    {
        immutable soft = speedY < 12;
        become(Ac.lander);
        if (soft)
            lixxie.advanceFrame(); // of the landing anim
        return BecomeCalled.yes;
    }

    override Collision onHittingWall()
    {
        if (abilityToClimb) {
            moveAhead(-2);
            become(Ac.climber);
            return Collision(BecomeCalled.yes, PleaseDo.stopMovement);
        }
        else {
            turn();
            return Collision(BecomeCalled.no, PleaseDo.resetPosition);
        }
    }

    override void selectFrame()
    {
        if (isLastFrame)
            frame = (abilityToRun ? 12 : frame - 1);
        else
            advanceFrame();
    }
}



// ############################################################################
// ############################################################################
// ############################################################################



class Tumbler : BallisticFlyer {
    mixin JobChild;

    static applyFlingXY(Lixxie lix)
    {
        if (! lix.flingNew)
            return;
        immutable wantFlingX = lix.flingX;
        immutable wantFlingY = lix.flingY;
        lix.resetFlingNew();

        assert (lix.outsideWorld);
        if (wantFlingX != 0)
            lix.dir = wantFlingX;
        lix.become(Ac.tumbler);
        if (lix.ac == Ac.tumbler) {
            Tumbler tumbling = cast (Tumbler) lix.job;
            assert (tumbling);
            tumbling.speedX = wantFlingX.abs;
            tumbling.speedY = wantFlingY;
            tumbling.initPixelsFallen();
            tumbling.selectFrame();
        }
        else
            assert (lix.ac == Ac.stunner, "should be the only possibility");
    }

    override void onBecome(in Job old)
    {
        if (isSolid(0, 1) && old.ac == Ac.ascender)
            // unglitch out of wall, but only back and up
            for (int dist = 1; dist <= Walker.highestStepUp; ++dist) {
                if (! isSolid(0, 1 - dist)) {
                    moveUp(dist);
                    break;
                }
                else if (! isSolid(- even(dist), 1)) {
                    moveAhead(- even(dist));
                    break;
                }
            }

        if (isSolid(0, 1)) {
            become(Ac.stunner);
        }
        else if (old.ac == Ac.jumper) {
            this.copyFrom(cast (Jumper) old);
            this.frame = 3;
        }
        else
            selectFrame();
    }

protected:

    override bool splatUpsideDown() const { return this.frame >= 9; }

    override BecomeCalled onLandingWithoutSplatting()
    {
        become(Ac.stunner);
        return BecomeCalled.yes;
    }

    override Collision onHittingWall()
    {
        if (wall(1) || (wall( 0) && ! behind( 0))
            || (wall(-1) && ! behind(-1))
            || (wall(-2) && ! behind(-2))
        ) {
            turn();
            return Collision(BecomeCalled.no, PleaseDo.resetPositionIfMovedX);
        }
        return Collision(BecomeCalled.no, PleaseDo.nothing);
    }

    override void selectFrame()
    {
        assert (speedX >= 0);
        immutable int tan = speedY * 12 / max(2, speedX);

        struct Result { int targetFrame; bool anim; }
        Result res =
              tan >  18 ? Result(13, true) // true = animate between 2 fames
            : tan >   9 ? Result(11, true)
            : tan >   3 ? Result( 9, true)
            : tan >   1 ? Result( 8)
            : tan >  -1 ? Result( 7)
            : tan >  -4 ? Result( 6)
            : tan > -10 ? Result( 5)
            : tan > -15 ? Result( 4)
            : tan > -30 ? Result( 3)
            : tan > -42 ? Result( 2)
            :             Result( 0, true);
        // unless we haven't yet selected frame from the midst of motion
        if (frame > 0)
            // ...never go forward through the anim too fast
            res.targetFrame = min(res.targetFrame, frame + (res.anim ? 2 : 1));

        frame = res.targetFrame
            + ((res.targetFrame == frame && res.anim) ? 1 : 0);
    }

private:
    void initPixelsFallen()
    {
        pixelsFallen = 0;
        if (speedY < 0)
            return;
        // In the check, ysp < speedY is correct, not ysp <= speedY.
        // Even if we begin with speedY == 2, we have fallen 0 pixels!
        // This is because we initialize with a speed, then use that speed
        // on the next physics update, only then increase the speed.
        // Thus, if we initialize speed with 2, we will fly 2 pixels down
        // on the next update and set speed to 4. Compared to speedY == 0,
        // we didn't fall more pixels before reaching speed 4, we merely
        // reached it sooner: The (speed == 0)-tumbler waited before falling.
        for (int ysp = speedY <= biggestLargeAccelSpeedY + 1 ? speedY % 2 : 0;
            ysp < speedY && accel(ysp) > 0;
            ysp += accel(ysp)
        ) {
            pixelsFallen += ysp;
        }
    }
}

unittest {
    auto t = new Tumbler();
    int wouldHaveFallen(int speed)
    {
        t.speedY = speed;
        t.initPixelsFallen();
        return t.pixelsFallen;
    }
    assert (wouldHaveFallen(0) == 0);
    assert (wouldHaveFallen(2) == 0);
    assert (wouldHaveFallen(4) == 2);
    assert (wouldHaveFallen(6) == 6);
    assert (wouldHaveFallen(8) == 12);
    assert (wouldHaveFallen(10) == 20);
    assert (wouldHaveFallen(12) == 30); // 12 is biggest speedY with accel == 2
    assert (wouldHaveFallen(14) == 42);
    assert (wouldHaveFallen(15) == 56);
    assert (wouldHaveFallen(16) == 71);
    assert (wouldHaveFallen(31) != wouldHaveFallen(32));
    assert (wouldHaveFallen(32) == wouldHaveFallen(33));
    assert (wouldHaveFallen(60) == wouldHaveFallen(80));

    assert (wouldHaveFallen(1) == 0);
    assert (wouldHaveFallen(3) == 1);
    assert (wouldHaveFallen(13) == 36); // in between values for 12 and 14

    for (int speed = 2; speed < 32; ++speed)
        assert (wouldHaveFallen(speed) < wouldHaveFallen(speed + 1));
}
