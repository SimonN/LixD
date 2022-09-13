module lix.skill.faller;

import std.algorithm; // min

import lix;
import tile.phymap;

class Faller : Job {
private:
    int _pixelsFallen = 0;

public:
    int ySpeed = 4;

    mixin JobChild;

    enum ySpeedTerminal = 8;
    enum pixelsSafeToFall = 126;
    enum pixelsFallenToBecomeFloater = 60;

    int pixelsFallen() const pure nothrow @safe @nogc { return _pixelsFallen; }

    static void becomeAndFallPixels(Lixxie lixxie, in int fallY)
    {
        lixxie.moveDown(fallY);
        becomeWithAlreadyFallenPixels(lixxie, fallY);
    }

    static void becomeWithAlreadyFallenPixels(Lixxie lixxie, int alreadyFallen)
    {
        lixxie.become(Ac.faller);
        Faller fa = cast (Faller) lixxie.job;
        assert (fa);
        fa._pixelsFallen = alreadyFallen;
    }

    override void
    perform()
    {
        int ySpeedThisFrame = 0;
        for ( ; ySpeedThisFrame <= ySpeed; ++ySpeedThisFrame) {
            if (isSolid(0, ySpeedThisFrame + 2)) {
                fallBy(ySpeedThisFrame);

                bool hasFallenVeryLittle()
                {
                    return pixelsFallen <= 9 && this.frame < 1
                        || pixelsFallen == 0
                        || this.frame   <  2; // on frame < 2, walker will
                }                             // select a different frame
                if (pixelsFallen > pixelsSafeToFall && ! abilityToFloat)
                    become(Ac.splatter);
                else if (hasFallenVeryLittle)
                    become(Ac.walker);
                else
                    become(Ac.lander);
                return;
            }
        }
        // On hitting ground, the above loop has already returned from
        // the function. If we continue here, we're in the air as a faller,
        // and we have not moved yet. We can move down by the entire ySpeed
        // and still be in the air.

        // Because of the loop condition, ySpeedThisFrame will be
        // 1 greater than ySpeed. Remedy that.
        ySpeedThisFrame = min(ySpeedThisFrame, ySpeed);
        fallBy(ySpeedThisFrame);

        if (ySpeed < ySpeedTerminal)
            ++ySpeed;

        if (isLastFrame)
            frame = frame - 1;
        else
            advanceFrame();

        if (abilityToFloat && pixelsFallen >= pixelsFallenToBecomeFloater)
            // it's important we have incremented ySpeed correctly for this
            become(Ac.floater);
    }
    // end void perform()

private:
    void fallBy(in int numPixelsY)
    {
        moveDown(numPixelsY);
        if (pixelsFallen > pixelsSafeToFall) {
            // This merely guards against int overflow of _pixelsFallen.
            return;
        }
        _pixelsFallen += numPixelsY;
    }
}
