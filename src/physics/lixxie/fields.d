module physics.lixxie.fields;

import optional;

public import net.style;

import physics;

// Some tight coupling between lix and tribes are unavoidable, e.g., when
// blocking or batting other lixes, or returning extra builder assignments.
// Each lix has a pointer to a struct. Game must keep the struct up-to-date.
struct OutsideWorld {
    World state;
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

    int opCmp(ref const(typeof(this)) rhs) const pure nothrow @safe @nogc
    {
        return style != rhs.style ? style - rhs.style
            : id - rhs.id;
    }
}

struct Priority {
private:
    short _realPrio;

public:
    enum Priority unassignableWithClosedCursor = Priority();
    enum Priority unassignableWithOpenCursor = makeUnassWithOpen();

    this(in int assignableValue) pure nothrow @safe @nogc
    in {
        assert (assignableValue <= 0x7FFF);
        assert (assignableValue >= 2, "0 or 1 means: Unassignable lix."
        ~ " For those, choose the predefined"
        ~ " Priority.unassignableWithClosedCursor"
        ~ " or Priority.unassignableWithOpenCursor.");
    }
    do {
        _realPrio = assignableValue & 0x7FFF;
    }

    const pure nothrow @safe @nogc:

    bool cursorOpens() { return _realPrio >= 1; }
    bool isAssignable() { return _realPrio >= 2; }

    bool opEquals(in typeof(this) rhs) { return _realPrio == rhs._realPrio; }
    int opCmp(in typeof(this) rhs) { return _realPrio - rhs._realPrio; }

    Priority opBinary(string op)(in int rhs)
        if (op == "+")
    in {
        assert(isAssignable, "Don't add to an unassignable Priority.");
        assert(rhs >= 0, "Only add, don't subtract, from any Priority.");
    }
    do {
        return Priority(_realPrio + rhs);
    }

private:
    static Priority makeUnassWithOpen()
    {
        auto ret = Priority();
        ret._realPrio = 1;
        return ret;
    }
}

unittest {
    assert (Priority.unassignableWithClosedCursor
        < Priority.unassignableWithOpenCursor);
    assert (Priority.unassignableWithOpenCursor < Priority(2));
}
