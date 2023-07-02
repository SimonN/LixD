module physics.job.faller;

import physics.job;

final class Faller : Job {
private:
    int _pixelsFallen = 0;

public:
    int ySpeed = 4;

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
            if (lixxie.isSolid(0, i + 2)) {
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
        lixxie.moveDown(numPixelsY);
        if (pixelsFallen > pixelsSafeToFall) {
            // Guard against int overflow of _pixelsFallen.
            return;
        }
        _pixelsFallen += numPixelsY;
    }

    void land()
    {
        if (pixelsFallen > pixelsSafeToFall && ! lixxie.abilityToFloat) {
            lixxie.become(Ac.splatter);
            return;
        }
        immutable bool hasFallenVeryLittle =
            pixelsFallen <= 9 && this.frame < 1
            || pixelsFallen == 0
            || this.frame < 2; // on frame < 2, walker will select other frame
        lixxie.become(hasFallenVeryLittle ? Ac.walker : Ac.lander);
    }

    void housekeepDuringFreeFall()
    {
        if (ySpeed < ySpeedTerminal) {
            ++ySpeed;
        }
        if (lixxie.isLastFrame) {
            frame = frame - 1;
        }
        else {
            lixxie.advanceFrame();
        }
        if (lixxie.abilityToFloat
            && pixelsFallen >= pixelsFallenToBecomeFloater
        ) {
            // it's important we have incremented ySpeed correctly for this
            lixxie.become(Ac.floater);
        }
    }
}

final class Lander : Job {
    override void onBecome(in Job old) {
        if (old.ac == Ac.faller) {
            auto faller = cast (const(Faller)) old;
            assert (faller);
            if (faller.frame < 3)
                frame = 1;
            // otherwise, use the regular frame 0
        }
    }

    override void perform()
    {
        if (lixxie.isLastFrame) {
            lixxie.become(Ac.walker);
        }
        else {
            lixxie.advanceFrame();
        }
    }
}
