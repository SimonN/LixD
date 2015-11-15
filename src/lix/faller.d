module lix.faller;

import game.lookup;
import lix;

class Faller : PerformedActivity {

    int ySpeed = 4;
    int pixelsFallen = 0;

    enum ySpeedTerminal = 8;
    enum pixelsSafeToFall = 126;
    enum pixelsFallenToBecomeFloater = 60;

    mixin(CloneByCopyFrom!"Faller");
    protected void copyFromAndBindToLix(in Faller rhs, Lixxie lixToBindTo)
    {
        super.copyFromAndBindToLix(rhs, lixToBindTo);
        ySpeed       = rhs.ySpeed;
        pixelsFallen = rhs.pixelsFallen;
    }

    override @property bool canPassTop() const { return true; }

    override void
    performActivity(UpdateArgs)
    {
        int ySpeedThisFrame = 0;

        for ( ; ySpeedThisFrame <= ySpeed; ++ySpeedThisFrame) {
            if (footEncounters & Lookup.bitTrampoline) {
                // Stop falling, so the trampoline can be used.
                // It's a bit kludgy, we can't do such a thing for gadgets
                // that fling, since the gadget might be nonconstant.
                break;
            }
            else if (isSolid(0, ySpeedThisFrame + 2)) {
                moveDown(ySpeedThisFrame);
                pixelsFallen += ySpeedThisFrame;

                bool hasFallenVeryLittle()
                {
                    return pixelsFallen <= 9 && this.frame < 1
                        || pixelsFallen == 0
                        || this.frame   <  2; // on frame < 2, walker will
                }                             // select a different frame

                if (pixelsFallen > pixelsSafeToFall && ! abilityToFloat)
                    become(Ac.SPLATTER);
                else if (hasFallenVeryLittle)
                    become(Ac.WALKER);
                else
                    become(Ac.LANDER);
                return;
            }
        }

        // On hitting ground, the above loop has already returned from
        // the function. If we continue here, we're in the air as a faller,
        // and we have not moved yet. We can move down by the entire ySpeed
        // and still be in the air.
        static if (cPlusPlusPhysicsBugs)
            // Doing it like in C++ might interfere with the trampoline kludge
            ySpeedThisFrame = ySpeed;
        else
            // Because of the loop condition, ySpeedThisFrame will be
            // 1 greater than ySpeed in the non-trampoline cases. Remedy that.
            ySpeedThisFrame = min(ySpeedThisFrame, ySpeed);

        moveDown(ySpeedThisFrame);
        pixelsFallen += ySpeedThisFrame;

        if (ySpeed < ySpeedTerminal)
            ++ySpeed;

        if (isLastFrame)
            frame = frame - 1;
        else
            advanceFrame();

        if (abilityToFloat && pixelsFallen >= pixelsFallenToBecomeFloater)
            // it's important we have incremented ySpeed correctly for this
            become(Ac.FLOATER);
    }
    // end void performActivity()
}
// end class
