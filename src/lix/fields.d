module lix.fields;

import optional;

import game.model.state;
import game.effect;
import game.tribe;
import game.physdraw;

// Some tight coupling between lix and tribes are unavoidable, e.g., when
// blocking or batting other lixes, or returning extra builder assignments.
// Each lix has a pointer to a struct. Game must keep the struct up-to-date.
struct OutsideWorld {
    GameState state;
    PhysicsDrawer physicsDrawer;
    Optional!EffectManager effect;
    Tribe tribe;
    int lixID;
}
