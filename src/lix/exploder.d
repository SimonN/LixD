module lix.exploder;

import lix;

class Exploder : Leaver {

    enum updatesForBomb = 75;

    mixin(CloneByCopyFrom!"Exploder");

    override @property bool blockable() const { return false; }

    static void handleUpdatesSinceBomb(Lixxie li)
    {
        assert (li.ac != Ac.exploder);
        assert (li.ac != Ac.exploder2);

        if (li.updatesSinceBomb == 0)
            return;

        if (cast (Leaver) li.performedActivity) {
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
