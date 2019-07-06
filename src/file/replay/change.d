module file.replay.change;

/*
 * Implementation of replay-changing functions.
 * Everything is package or private here.
 * The public interface is in file.replay.replay.
 */

import core.stdc.string : memmove;
import std.algorithm;

import basics.help;
import file.replay.replay;

package:

/*
 * Returns phyu of first difference to old replay.
 * To recompute physics properly, the game must load a savestate
 * that was computed for a phyu strictly less than the returned phyu.
 *
 * The public function in file.replay.replay should guarantee for us
 * that (RepData what) can be found in the replay.
 */
Phyu changeImpl(
    Replay rep,
    in ChangeRequest rq,
) in {
    version (unittest) {
        import std.conv;
        assert (rep.indexOf(rq.what) >= 0,
            "file.replay.replay should guarantee that (what) exists in the data: "
            ~ rq.what.to!string);
    }
}
out {
    version (unittest) {
        import std.conv;
        import std.array;
        assert (rep._data.isSorted,
            "Missorted replay data after changeImpl:\n"
            ~ rep._data.map!(to!string).join("\n"));
    }
}
body {
    final switch (rq.how) {
        case ChangeVerb.moveThisLater:
            return rep.moveThisLaterImpl(rq);
        case ChangeVerb.moveThisEarlier:
            return rep.moveThisEarlierImpl(rq);
        case ChangeVerb.eraseThis:
            return rep.eraseThisImpl(rq);
        case ChangeVerb.moveTailBeginningWithThisLater:
        case ChangeVerb.moveTailBeginningWithPhyuEarlier:
            assert (false, "not yet implemented");
    }
}

inout(Ply)[] dataSliceBeforePhyu(
    inout(Replay) rep,
    in Phyu upd
) pure nothrow @nogc { with (rep)
{
    // The binary search algo works also for this case.
    // But we add mostly to the end of the data, so check here for speed.
    if (_data.length == 0 || _data[$-1].update < upd)
        return _data;

    int bot = 0;         // first too-large is at a higher position
    int top = _data.len; // first too-large is here or at a lower position

    while (top != bot) {
        int bisect = (top + bot) / 2;
        assert (bisect >= 0   && bisect < _data.len);
        assert (bisect >= bot && bisect < top);
        if (_data[bisect].update < upd)
            bot = bisect + 1;
        if (_data[bisect].update >= upd)
            top = bisect;
    }
    return _data[0 .. bot];
}}

// See file.replay.replay for add() with touching.
void addWithoutTouching(
    Replay rep,
    in Ply d
) {
    // Add after the latest record that's smaller than or equal to d
    // Equivalently, add before the earliest record that's greater than d.
    // dataSliceBeforePhyu doesn't do exactly that, it ignores players.
    // I believe the C++ version had a bug in the comparison. Fixed here.
    auto slice = rep.dataSliceBeforePhyu(Phyu(d.update + 1));
    while (slice.length && slice[$-1] > d)
        slice = slice[0 .. $-1];
    if (slice.length < rep._data.length) {
        rep._data.length += 1;
        memmove(
            &rep._data[slice.length + 1],
            &rep._data[slice.length],
            Ply.sizeof * (rep._data.length - slice.length - 1));
        rep._data[slice.length] = d;
    }
    else {
        rep._data ~= d;
    }
    assert (rep._data.isSorted);
}

///////////////////////////////////////////////////////////////////////////////
private: //////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

/*
 * All these functions are called from changeImpl, therefore (RepData what)
 * is guaranteed to be found in (rep._data).
 *
 * See file.replay.changerq for the spec.
 */

Phyu moveThisLaterImpl(
    Replay rep,
    in ChangeRequest rq
) {
    int id = rep.indexOf(rq.what);
    immutable oldPhyu = rq.what.update;
    immutable newPhyu = Phyu(rq.what.update + 1);
    rep._data[id].update = newPhyu;
    // Restore the sorting, and adhere to the rule of inserting as last,
    // as specced in file.replay.changerq.
    while (
        rep._data.len >= id + 2 // There is an entry after the changed entry
        && rep._data[id + 1] <= rep._data[id]
    ) {
        swap(rep._data[id], rep._data[id + 1]);
        ++id; // The changed entry sits at a higher position now. Check again.
    }
    return oldPhyu;
}

Phyu moveThisEarlierImpl(
    Replay rep,
    in ChangeRequest rq
) {
    int id = rep.indexOf(rq.what);
    immutable oldPhyu = rq.what.update;
    immutable newPhyu = Phyu(rq.what.update - 1);
    rep._data[id].update = newPhyu;
    while (id > 0 && rep._data[id - 1] > rep._data[id]) {
        swap(rep._data[id - 1], rep._data[id]);
        --id;
    }
    return newPhyu;
}

Phyu eraseThisImpl(
    Replay rep,
    in ChangeRequest rq
) {
    int id = rep.indexOf(rq.what);
    assert (id < rep._data.len);
    memmove(
        &rep._data[id],
        &rep._data[id] + 1, // if outside array, then 0 bytes will be copied...
        Ply.sizeof * (rep._data.len - id - 1)); // ...because of this number.
    rep._data.length -= 1;
    return rq.what.update;
}

/*
 * Find (what)'s index in rep._data.
 * Assume that rep._data is sorted..
 * If duplicates of (what) are in rep._data, return the first of them.
 * Returns -1 if (Ply what) cannot be found.
 */
int indexOf(
    in Replay rep,
    in Ply what
) nothrow @nogc
{
    // Slow impl, consider bisecting
    for (int id = 0; id < rep._data.len; ++id) {
        if (rep._data[id] == what) {
            return id;
        }
    }
    return -1;
}

version (unittest) {
    import file.date;

    /*
     * Quick func to avoid specifying too many Ply constructor args.
     */
    Ply rd(Ac ac, Phyu phyu)
    {
        Ply ret;
        ret.player = 0;
        ret.action = RepAc.ASSIGN_LEFT;
        ret.skill = ac;
        ret.update = phyu;
        ret.toWhichLix = 3;
        return ret;
    }
}

unittest {
    Replay rep = Replay.newNoLevelFilename(Date.now());
    rep.add(rd(Ac.blocker, Phyu(100)));
    rep.add(rd(Ac.builder, Phyu(101)));
    rep.add(rd(Ac.basher, Phyu(103)));

    /*
     * Task: Move the builder assignment later 3 times. After one move,
     * it's still the assignment with index 1. After the second move,
     * the rule of inserting as last applies and forces to swap builder/basher.
     */
    assert (rep._data[1].skill == Ac.builder);
    assert (rep._data[1].update == 101);
    rep.changeImpl(ChangeRequest(rep._data[1], ChangeVerb.moveThisLater));
    assert (rep._data[1].skill == Ac.builder);
    assert (rep._data[1].update == 102);
    rep.changeImpl(ChangeRequest(rep._data[1], ChangeVerb.moveThisLater));
    assert (rep._data[1].skill == Ac.basher);
    assert (rep._data[2].skill == Ac.builder);
    assert (rep._data[1].update == 103);
    rep.changeImpl(ChangeRequest(rep._data[2], ChangeVerb.moveThisLater));
    assert (rep._data[2].update == 104);

    /*
     * Move the builder assignment back, and even more.
     * Again adhere to the rule of inserting last.
     * This means that (moving later, then moving earlier) is not always nop.
     */
    rep.changeImpl(ChangeRequest(rep._data[2], ChangeVerb.moveThisEarlier));
    assert (rep._data[1].skill == Ac.basher);
    assert (rep._data[2].skill == Ac.builder);
    assert (rep._data[2].update == 103);
    rep.changeImpl(ChangeRequest(rep._data[2], ChangeVerb.moveThisEarlier));
    assert (rep._data[1].skill == Ac.builder);
    assert (rep._data[2].skill == Ac.basher);
    rep.changeImpl(ChangeRequest(rep._data[1], ChangeVerb.moveThisEarlier));
    assert (rep._data[1].skill == Ac.builder);
    rep.changeImpl(ChangeRequest(rep._data[1], ChangeVerb.moveThisEarlier));
    assert (rep._data[0].skill == Ac.blocker);
    assert (rep._data[1].skill == Ac.builder);
    assert (rep._data[0].update == rep._data[1].update);
    rep.changeImpl(ChangeRequest(rep._data[1], ChangeVerb.moveThisEarlier));
    assert (rep._data[0].skill == Ac.builder);
    assert (rep._data[1].skill == Ac.blocker);
}

unittest {
    Replay rep = Replay.newNoLevelFilename(Date.now());
    immutable Ply a = rd(Ac.blocker, Phyu(100));
    immutable Ply b = rd(Ac.builder, Phyu(101));
    immutable Ply c = rd(Ac.basher, Phyu(103));
    rep.add(a);
    rep.add(b);
    rep.add(c);

    rep.changeImpl(ChangeRequest(b, ChangeVerb.eraseThis));
    assert (rep._data.length == 2);
    assert (rep._data[0] == a);
    assert (rep._data[1] == c);

    rep.changeImpl(ChangeRequest(c, ChangeVerb.eraseThis));
    assert (rep._data.length == 1);
    assert (rep._data[0] == a);

    rep.changeImpl(ChangeRequest(a, ChangeVerb.eraseThis));
    assert (rep._data.length == 0);
}
