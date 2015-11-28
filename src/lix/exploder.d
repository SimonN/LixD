module lix.exploder;

import lix;

/+
static this()
{
    acFunc[Ac.EXPLODER]  .leaving = true;
}
+/



class Exploder : PerformedActivity {

    enum updatesForBomb = 75;

    mixin(CloneByCopyFrom!"Exploder");

    override @property bool leaving() const { return true; }

    static void handleUpdatesSinceBomb(Lixxie li)
    {
        if (li.updatesSinceBomb == 0)
            return;

        if (li.performedActivity.leaving) {
            if (li.updatesSinceBomb > updatesForBomb)
                li.updatesSinceBomb = 0;
            else
                li.updatesSinceBomb = li.updatesSinceBomb + li.frame + 1;
        }
        else {
            ++li.updatesSinceBomb;
            // because 0 -> 1 -> 2 happens in the same frame, add +1 here:
            if (li.updatesSinceBomb == updatesForBomb + 1) {
                // explode
            }
        }
    }

}
