module lix.tumbler;

import lix;

class Tumbler : PerformedActivity {

    mixin(CloneByCopyFrom);

    override @property bool canPassTop() const { return true; }

}
