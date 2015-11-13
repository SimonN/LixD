module lix.builder;

import lix;

class Builder    : PerformedActivity { mixin(CloneByCopyFrom!"Builder"); }
class Platformer : PerformedActivity { mixin(CloneByCopyFrom!"Platformer"); }

// important to implement this in the shrugger's become,
// this comes from (become walker)
/+
        else if (lixxie.ac == Ac.PLATFORMER && frame > 5) {
            become(Ac.SHRUGGER2);
            frame = 9;
            // See also the next else-if.
            // Clicking twice on the platformer shall turn it around.
        }
        else if (lixxie.ac == Ac.SHRUGGER || lixxie.ac == Ac.SHRUGGER2) {
            become(Ac.WALKER);
            turn();
        }
+/

class Shrugger   : PerformedActivity { mixin(CloneByCopyFrom!"Shrugger"); }

