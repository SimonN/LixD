module lix.fields;

import optional;

public import net.style;

import physics;

// Some tight coupling between lix and tribes are unavoidable, e.g., when
// blocking or batting other lixes, or returning extra builder assignments.
// Each lix has a pointer to a struct. Game must keep the struct up-to-date.
struct OutsideWorld {
    GameState state;
    PhysicsDrawer physicsDrawer;
    EffectSink effect;
    Passport passport;

    inout(Tribe) tribe() inout { return state.tribes[passport.style]; }
}

// Enough information to retrieve a specific lix from a given GameState.
// Lixes are value types and can't be identified by equality comparision.
struct Passport {
    Style style; // GameState has at most one Tribe per Style
    int id; // which entry entry of the tribe's vector of Lixxies

    int opCmp(ref const(typeof(this)) rhs) const
    {
        return style != rhs.style ? style - rhs.style
            : id - rhs.id;
    }
}
