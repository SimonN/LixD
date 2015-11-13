module lix.blocker;

import lix;

// we don't have the 'blockable' field anymore. Realize this in the blocker
// physics directly.

/+
    acFunc[Ac.CLIMBER]   .blockable =
    acFunc[Ac.ASCENDER]  .blockable =
    acFunc[Ac.BLOCKER]   .blockable =
    acFunc[Ac.EXPLODER]  .blockable =
    acFunc[Ac.BATTER]    .blockable =
    acFunc[Ac.CUBER]     .blockable = false;
+/

class Blocker : PerformedActivity {

    mixin(CloneByCopyFrom!"Blocker");

}
