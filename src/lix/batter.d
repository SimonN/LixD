module lix.batter;

import lix;

class Batter : PerformedActivity {

    mixin(CloneByCopyFrom!"Batter");

    override @property bool blockable() const { return false; }

}
