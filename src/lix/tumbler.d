module lix.tumbler;

import lix;

class Jumper : PerformedActivity {

    mixin(CloneByCopyFrom);

}

class Tumbler : PerformedActivity {

    mixin(CloneByCopyFrom);

    override @property bool canPassTop() const { return true; }

}

class Stunner : PerformedActivity {

    mixin(CloneByCopyFrom);

}
