module lix.skill.tumbler;

import std.algorithm;
import std.format; // assert errors
import std.math; // abs

import basics.help;
import game.phymap; // trampoline phybit
import lix;

abstract class BallisticFlyer : PerformedActivity {

    enum speedYToSplat = 19;
    enum speedYToFloat = 15;

    int speedX;
    int speedY;

    alias lixxie this;
    alias copyFromAndBindToLix = super.copyFromAndBindToLix;
    protected void copyFromAndBindToLix(in BallisticFlyer rhs, Lixxie li)
    {
        super.copyFromAndBindToLix(rhs, li);
        speedX = rhs.speedX;
        speedY = rhs.speedY;
    }

    final override void performActivity()
    {
        assert (speedX >= 0, "Lix should only fly forwards. Turn first.");
        if (speedX % 2 != 0)
            ++speedX;

        moveSeveralTimes();

        if (this !is lixxie.performedActivity)
            return;

        if      (speedY <= 12) speedY += 2;
        else if (speedY  < 32) speedY += 1;

        selectFrame();

        if (speedY >= speedYToFloat) {
            if      (abilityToFloat)  become(Ac.floater);
            else if (ac == Ac.jumper) become(Ac.tumbler);
        }
    }

protected:

    final bool wall  (in int y) { return isSolid(0, y); }
    final bool behind(in int y) { return wall(y) && isSolid(-2, y); }

    bool splatUpsideDown() const { return false; }

    abstract Collision onHittingWall();
    abstract void onLandingWithoutSplatting();
    abstract void selectFrame();

    enum Collision {
        nothing,         // nothing hit, keep moving
        stopMovement,    // hit something, stop, but remain in place with state
        resetEncounters, // we un-glitched out of sth., so reset encounters
        resetPosition    // we hit something, didn't handle un-glitching yet
    }

private:

    final void landOnFloor()
    {
        if (speedY >= speedYToSplat && ! abilityToFloat) {
            become(Ac.splatter);
            if (this.splatUpsideDown)
                lixxie.frame = 10;
        }
        else
            onLandingWithoutSplatting();
    }

    final void moveSeveralTimes()
    {
        immutable int ySgn = speedY >= 0 ? 1 : -1;
        immutable int yAbs = speedY.abs;

        // advance diagonally, examine collisions at each step.
        BREAK_MOTION:
        foreach(int step; 0 .. max(yAbs, speedX)) {
            immutable oldEx = ex;
            immutable oldEy = ey;
            immutable oldEncBody = bodyEncounters;
            immutable oldEncFoot = footEncounters;

            if (yAbs >= speedX) {
                // move ahead occasionally only. / 2 * 2 to keep stuff even.
                immutable int halfX = (step + 1) * speedX / 2 / yAbs
                                    - (step)     * speedX / 2 / yAbs;
                assert (halfX == 0 || halfX == 1);
                moveAhead(2 * halfX);
                moveDown(ySgn);
            }
            else {
                // move down occasionally only
                moveDown(ySgn * ( (step + 1) * yAbs / speedX
                                - (step)     * yAbs / speedX));
                moveAhead(2 * (step & 1));
            }

            final switch (collision) {
            case Collision.nothing:
                break;
            case Collision.stopMovement:
                break BREAK_MOTION;
            case Collision.resetEncounters:
                forceBodyAndFootEncounters(oldEncBody, oldEncFoot);
                ey = ey; // re-check encounters here
                break BREAK_MOTION;
            case Collision.resetPosition:
                forceBodyAndFootEncounters(oldEncBody, oldEncFoot);
                ex = oldEx;
                ey = oldEy;
                if (isSolid(0, 1))
                    // completely immobilized
                    become(Ac.stunner);
                break BREAK_MOTION;
            }
        }
        // end BREAK_MOTION: foreach
    }

    // Horrible function. Copied out of C++ Lix almost unaltered.
    // The problem is that this function's semantics have already been
    // debugged to no end, C++ Lix had lots of bugs with tumblers over
    // the years. We'd have to be really smart to make this simpler.
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
            landOnFloor();
            return Collision.resetEncounters;
        }

        // Stepping up a step we jumped onto
        if (lowest_floor != -999
            && ac == Ac.jumper
            && (lowest_floor > -9
                || (abilityToClimb && ! behind(lowest_floor)))
        ) {
            become(Ac.ascender);
            return Collision.resetEncounters;
        }

        // bump head into ceilings
        if ((behind_count > 0 && speedY < 2)
            || (wall(-12) && ! wall_count_t && speedY < 0)
        ) {
            if (ac != Ac.tumbler)
                become(Ac.tumbler);

            auto tumbling = cast (BallisticFlyer) lixxie.performedActivity;
            assert (tumbling);
            tumbling.speedY = 4;
            tumbling.speedX = this.speedX / 2;

            if (isSolid(0, 1)) return Collision.resetPosition;
            else               return Collision.stopMovement;
        }

        // Jumping against a wall
        if (wall_count_t)
            return onHittingWall();

        if (speedY > 0 && (footEncounters & Phybit.trampo))
            // Trampolines stop motion, a bit kludgy
            return Collision.stopMovement;
        return Collision.nothing;
    }
    // end collision()

}



// ############################################################################
// ############################################################################
// ############################################################################



class Jumper : BallisticFlyer {

    mixin(CloneByCopyFrom!"Jumper");

    override void onBecome()
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

    override void onLandingWithoutSplatting()
    {
        become(Ac.lander);
        if (speedY < 12)
            lixxie.advanceFrame(); // of the landing anim
    }

    override Collision onHittingWall()
    {
        if (abilityToClimb) {
            moveAhead(-2);
            become(Ac.climber);
            return Collision.stopMovement;
        }
        else {
            turn();
            return Collision.resetPosition;
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

    mixin(CloneByCopyFrom!"Tumbler");

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
            Tumbler tumbling = cast (Tumbler) lix.performedActivity;
            assert (tumbling);
            tumbling.speedX = wantFlingX.abs;
            tumbling.speedY = wantFlingY;
            tumbling.selectFrame();
        }
        else
            assert (lix.ac == Ac.stunner, "should be the only possibility");
    }

    override void onBecome()
    {
        if (isSolid(0, 1) && lixxie.ac == Ac.ascender)
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
        else if (lixxie.ac == Ac.jumper) {
            Jumper jumping = cast (Jumper) lixxie.performedActivity;
            assert (jumping);
            this.speedX = jumping.speedX;
            this.speedY = jumping.speedY;
            this.frame  = 3;
        }
        else
            selectFrame();
    }

protected:

    override bool splatUpsideDown() const { return this.frame >= 9; }

    override void onLandingWithoutSplatting() { become(Ac.stunner); }

    override Collision onHittingWall()
    {
        if (wall(1) || (wall( 0) && ! behind( 0))
            || (wall(-1) && ! behind(-1))
            || (wall(-2) && ! behind(-2))
        ) {
            turn();
            return Collision.resetPosition;
        }
        return Collision.nothing;
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

}
