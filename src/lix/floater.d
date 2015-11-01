module lix.floater;

import lix;

class Floater : PerformedActivity {

    int ySpeed = 0;

    mixin(CloneByCopyFrom);
    void copyFrom(Floater rhs)
    {
        super.copyFrom(rhs);
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
