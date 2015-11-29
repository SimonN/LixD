module lix.blocker;

import lix;

class Blocker : PerformedActivity {

    mixin(CloneByCopyFrom!"Blocker");

    override @property bool blockable() const { return false; }

}
