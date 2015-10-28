module lix.floater;

import lix;

class Floater : PerformedActivity {

    private alias lixxie this;

    int ySpeed = 0;

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
