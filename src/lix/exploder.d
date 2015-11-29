module lix.exploder;

import lix;

class Exploder : PerformedActivity {

    enum updatesForBomb = 75;

    mixin(CloneByCopyFrom!"Exploder");

    override @property bool leaving()   const { return true;  }
    override @property bool blockable() const { return false; }

    static void handleUpdatesSinceBomb(Lixxie li)
    {
        assert (li.ac != Ac.EXPLODER);
        assert (li.ac != Ac.EXPLODER2);

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
