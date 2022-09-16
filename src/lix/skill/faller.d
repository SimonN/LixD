module lix.skill.faller;

import lix;
import tile.phymap;

final class Faller : Job {
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
        for (int i = 0; i <= ySpeed; ++i) {
            if (isSolid(0, i + 2)) {
                fallBy(i);
                land();
                return;
            }
        }
        fallBy(ySpeed);
        housekeepDuringFreeFall();
    }

private:
    void fallBy(in int numPixelsY)
    {
        moveDown(numPixelsY);
        if (pixelsFallen > pixelsSafeToFall) {
            // Guard against int overflow of _pixelsFallen.
            return;
        }
        _pixelsFallen += numPixelsY;
    }

    void land()
    {
        if (pixelsFallen > pixelsSafeToFall && ! abilityToFloat) {
            become(Ac.splatter);
            return;
        }
        immutable bool hasFallenVeryLittle =
            pixelsFallen <= 9 && this.frame < 1
            || pixelsFallen == 0
            || this.frame < 2; // on frame < 2, walker will select other frame
        become(hasFallenVeryLittle ? Ac.walker : Ac.lander);
    }

    void housekeepDuringFreeFall()
    {
        if (ySpeed < ySpeedTerminal) {
            ++ySpeed;
        }
        if (isLastFrame) {
            frame = frame - 1;
        } else {
            advanceFrame();
        }
        if (abilityToFloat && pixelsFallen >= pixelsFallenToBecomeFloater) {
            // it's important we have incremented ySpeed correctly for this
            become(Ac.floater);
        }
    }
}
