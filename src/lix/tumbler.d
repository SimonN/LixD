module lix.tumbler;

import lix;

class Tumbler : PerformedActivity {

    mixin(CloneByCopyFrom);
    private alias lixxie this;

    override @property bool canPassTop() const { return true; }

}
