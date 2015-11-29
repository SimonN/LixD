module lix.climber;

import lix;

class Climber : PerformedActivity {

    mixin(CloneByCopyFrom!"Climber");

    override @property bool callBecomeAfterAssignment() const { return false; }
    override @property bool blockable()                 const { return false; }

    override void onManualAssignment()
    {
        assert (! abilityToClimb);
        abilityToClimb = true;
    }

}
