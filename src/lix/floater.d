module lix.floater;

import lix;

class Floater : PerformedActivity {

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
            Faller perfCast = cast (Faller) performedActivity;
            assert (perfCast);
            speedY = perfCast.ySpeed;
        }
        else if (lixxie.ac == Ac.jumper || lixxie.ac == Ac.tumbler) {
            BallisticFlyer bf = cast (BallisticFlyer) performedActivity;
            assert (bf);
            speedX = bf.speedX;
            speedY = bf.speedY;
        }
    }

    override void performActivity()
    {
    }
}
