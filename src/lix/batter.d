module lix.batter;

import lix;

class Batter : PerformedActivity {

    enum flingingFrame = 3;

    mixin(CloneByCopyFrom!"Batter");

    override @property bool blockable() const { return false; }

    override UpdateOrder updateOrder() const
    {
        if (frame == flingingFrame - 1) return UpdateOrder.flinger;
        else                            return UpdateOrder.peaceful;
    }

}
