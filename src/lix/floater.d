module lix.floater;

import lix;

class Floater : PerformedActivity {

    int ySpeed = 0;

    mixin(CloneByCopyFrom!"Floater");
    void copyFromAndBindToLix(in Floater rhs, Lixxie lixToBindTo)
    {
        super.copyFromAndBindToLix(rhs, lixToBindTo);
        ySpeed = rhs.ySpeed;
    }

    override @property bool canPassTop() const { return true; }
    override @property bool callBecomeAfterAssignment() const { return false; }

    override void
    onBecome()
    {
        if (ac == Ac.FALLER) {
            Faller perfCast = cast (Faller) performedActivity;
            assert (perfCast);
            ySpeed = perfCast.ySpeed;
        }
    }

    override void
    performActivity(UpdateArgs ua)
    {
    }
}
