module lix.tumbler;

import lix;

class Jumper : PerformedActivity {

    mixin(CloneByCopyFrom!"Jumper");

}

class Tumbler : PerformedActivity {

    mixin(CloneByCopyFrom!"Tumbler");

}

class Stunner : PerformedActivity {

    mixin(CloneByCopyFrom!"Stunner");

}
