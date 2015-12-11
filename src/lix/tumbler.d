module lix.tumbler;

import std.algorithm;
import std.math; // abs

import basics.help;
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

        immutable int ySgn  = speedY >= 0 ? 1 : -1;
        immutable int yAbs  = speedY.abs;

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

        if (this !is lixxie.performedActivity)
            return;

        if      (speedY <= 12) speedY += 2;
        else if (speedY  < 64) speedY += 1;

        selectFrame();

        if (speedY >= speedYToFloat) {
            if (abilityToFloat)
                become(Ac.floater);
            else if (ac == Ac.jumper)
                // DTODO: should this if be refactored with a virtual method?
                become(Ac.tumbler);
        }
    }

protected:

    bool splatUpsideDown() const { return false; }

    abstract void selectFrame();
    abstract void onLandingWithoutSplatting();

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

    enum Collision {
        nothing,
        stopMovement,
        resetEncounters,
        resetPosition
    }

    Collision collision()
    {
        return Collision.nothing;
    }

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

    static becomeIfFlung(Lixxie lix)
    {
        if (! lix.flingNew || ! lix.healthy)
            return;

        lix.become(Ac.tumbler);
        if (lix.flingX != 0)
            lix.dir = lix.flingX;
        Tumbler tumbling = cast (Tumbler) lix.performedActivity;
        assert (tumbling);
        tumbling.speedX = lix.flingX.abs;
        tumbling.speedY = lix.flingY;
        tumbling.selectFrame();
        lix.resetFlingNew();
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

    override void selectFrame()
    {
        immutable int y   = speedY;
        immutable int x   = max(2, speedX.abs);
        immutable int tan = y * 12 / x;

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
            res.targetFrame = min(res.targetFrame, frame + res.anim ? 2 : 1);

        frame = res.targetFrame
            + ((res.targetFrame == frame && res.anim) ? 1 : 0);
    }

}
