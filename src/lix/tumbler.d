module lix.tumbler;

import lix;

class Jumper : PerformedActivity {

    mixin(CloneByCopyFrom!"Jumper");

}

class Tumbler : PerformedActivity {

    mixin(CloneByCopyFrom!"Tumbler");

    override @property bool canPassTop() const { return true; }

}

class Stunner : PerformedActivity {

    mixin(CloneByCopyFrom!"Stunner");

}
