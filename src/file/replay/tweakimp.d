module file.replay.tweakimp;

/*
 * Implementation of replay-tweaking functions.
 * Replay tweaking means to change the replay via the replay tweaker UI:
 * To move or delete plies deep in the replay, even if other plies follow.
 *
 * Everything is package or private here.
 * The public interface is in file.replay.replay.
 */

import core.stdc.string : memmove;
import std.algorithm;
import std.conv;

import basics.help;
import file.replay.replay;

package:

/*
 * See file.replay.tweakrq for spec of return struct.
 * Among that spec, we see that tweakImpl returns
 * the phyu of first difference to old replay.
 * To recompute physics properly, the game must load a savestate
 * that was computed for a phyu strictly earlier than that first difference.
 * Therefore, callers should probably deduct 1 phyu from that first difference.
 *
 * The public function in file.replay.replay should guarantee for us
 * that (RepData what) can be found in the replay.
 */
TweakResult tweakImpl(
    Replay rep,
    in ChangeRequest rq,
) in {
    assert (rq.how == ChangeVerb.cutFutureOfOneLix
        || rep.indexOf(rq.what) >= 0,
        "Most ChangeVerbs should refer to an existant Ply. "
        ~ rq.what.to!string);
}
out {
    version (unittest) {
        import std.array;
        assert (rep._plies.isSorted,
            "Missorted replay data after tweakImpl:\n"
            ~ rep._plies.map!(to!string).join("\n"));
    }
}
do {
    final switch (rq.how) {
        case ChangeVerb.moveThisLater:
            return rep.moveThisLaterImpl(rq);
        case ChangeVerb.moveThisEarlier:
            return rep.moveThisEarlierImpl(rq);
        case ChangeVerb.cutFutureOfOneLix:
            return rep.cutFutureOfOneLixImpl(rq);
    }
}

inout(Ply)[] plySliceBefore(
    inout(Replay) rep,
    in Phyu upd
) pure nothrow @safe @nogc { with (rep)
{
    // The binary search algo works also for this case.
    // But we add mostly to the end of the data, so check here for speed.
    if (_plies.length == 0 || _plies[$-1].when < upd)
        return _plies;

    int bot = 0;         // first too-large is at a higher position
    int top = _plies.len; // first too-large is here or at a lower position

    while (top != bot) {
        int bisect = (top + bot) / 2;
        assert (bisect >= 0   && bisect < _plies.len);
        assert (bisect >= bot && bisect < top);
        if (_plies[bisect].when < upd)
            bot = bisect + 1;
        if (_plies[bisect].when >= upd)
            top = bisect;
    }
    return _plies[0 .. bot];
}}

// See file.replay.replay for add() with touching.
void addWithoutTouching(
    Replay rep,
    in Ply d
) {
    // Add after the latest record that's smaller than or equal to d
    // Equivalently, add before the earliest record that's greater than d.
    // plySliceBefore doesn't do exactly that, it ignores.bys.
    // I believe the C++ version had a bug in the comparison. Fixed here.
    auto slice = rep.plySliceBefore(Phyu(d.when + 1));
    while (slice.length && slice[$-1] > d)
        slice = slice[0 .. $-1];
    if (slice.length < rep._plies.length) {
        rep._plies.length += 1;
        memmove(
            &rep._plies[slice.length + 1],
            &rep._plies[slice.length],
            Ply.sizeof * (rep._plies.length - slice.length - 1));
        rep._plies[slice.length] = d;
    }
    else {
        rep._plies ~= d;
    }
    assert (rep._plies.isSorted);
}

///////////////////////////////////////////////////////////////////////////////
private: //////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

/*
 * All these functions are called from tweakImpl, therefore (RepData what)
 * is guaranteed to be found in (rep._plies).
 *
 * See file.replay.changerq for the spec.
 */

TweakResult moveThisLaterImpl(
    Replay rep,
    in ChangeRequest rq
) {
    int id = rep.indexOf(rq.what);
    immutable oldPhyu = rq.what.when;
    immutable newPhyu = Phyu(rq.what.when + 1);
    rep._plies[id].when = newPhyu;
    // Restore the sorting, and adhere to the rule of inserting as last,
    // as specced in file.replay.changerq.
    while (
        rep._plies.len >= id + 2 // There is an entry after the changed entry
        && rep._plies[id + 1] <= rep._plies[id]
    ) {
        swap(rep._plies[id], rep._plies[id + 1]);
        ++id; // The changed entry sits at a higher position now. Check again.
    }
    TweakResult ret;
    ret.somethingChanged = true;
    ret.firstDifference = oldPhyu;
    ret.goodPhyuToView = newPhyu;
    return ret;
}

TweakResult moveThisEarlierImpl(
    Replay rep,
    in ChangeRequest rq
) {
    int id = rep.indexOf(rq.what);
    immutable oldPhyu = rq.what.when;
    immutable newPhyu = Phyu(rq.what.when - 1);
    rep._plies[id].when = newPhyu;
    while (id > 0 && rep._plies[id - 1] > rep._plies[id]) {
        swap(rep._plies[id - 1], rep._plies[id]);
        --id;
    }
    TweakResult ret;
    ret.somethingChanged = true;
    ret.firstDifference = newPhyu;
    ret.goodPhyuToView = newPhyu; // Yes, same as firstDifference
    return ret;
}

TweakResult cutFutureOfOneLixImpl(
    Replay rep,
    in ChangeRequest rq,
) pure nothrow @safe @nogc
{
    /*
     * This doesn't guard against different tribes or PlNrs.
     * This assumes we'll always cut in singleplayer, where assignable
     * lixes can be identified already by rq.what.toWhichLix alone.
     */
    bool toCut(in Ply p) pure nothrow @safe @nogc
    {
        if (p.when <= rq.what.when) {
            return false;
        }
        return p.isNuke
            || p.isAssignment && p.toWhichLix == rq.what.toWhichLix;
    }
    assert (! toCut(rq.what), "We cut after rq.what, not including rq.what.");
    if (! rep._plies.canFind!toCut) {
        return TweakResult(false);
    }
    rep._plies = rep._plies.remove!(ply => toCut(ply));
    TweakResult ret;
    ret.somethingChanged = true;
    ret.firstDifference = rq.what.when;
    ret.goodPhyuToView = Phyu(0); // Don't jump weirdly into the future.
    // Reason: We erased the future, we didn't put something exciting there.
    return ret;
}

/*
 * Find (what)'s index in rep._plies.
 * Assume that rep._plies is sorted..
 * If duplicates of (what) are in rep._plies, return the first of them.
 */
int indexOf(
    in Replay rep,
    in Ply what
) nothrow
{
    // Slow impl, consider bisecting
    for (int id = 0; id < rep._plies.len; ++id) {
        if (rep._plies[id] == what) {
            return id;
        }
    }
    assert (false, "Ply not in replay: " ~ what.to!string);
}

version (unittest) {
    import file.date;

    /*
     * Quick func to avoid specifying too many Ply constructor args.
     */
    Ply rd(Ac ac, Phyu phyu)
    {
        Ply ret;
        ret.by = 0;
        ret.isDirectionallyForced = true;
        ret.lixShouldFace = Ply.LixShouldFace.left;
        ret.skill = ac;
        ret.when = phyu;
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
    assert (rep._plies[1].skill == Ac.builder);
    assert (rep._plies[1].when == 101);
    rep.tweakImpl(ChangeRequest(rep._plies[1], ChangeVerb.moveThisLater));
    assert (rep._plies[1].skill == Ac.builder);
    assert (rep._plies[1].when == 102);
    rep.tweakImpl(ChangeRequest(rep._plies[1], ChangeVerb.moveThisLater));
    assert (rep._plies[1].skill == Ac.basher);
    assert (rep._plies[2].skill == Ac.builder);
    assert (rep._plies[1].when == 103);
    rep.tweakImpl(ChangeRequest(rep._plies[2], ChangeVerb.moveThisLater));
    assert (rep._plies[2].when == 104);

    /*
     * Move the builder assignment back, and even more.
     * Again adhere to the rule of inserting last.
     * This means that (moving later, then moving earlier) is not always nop.
     */
    rep.tweakImpl(ChangeRequest(rep._plies[2], ChangeVerb.moveThisEarlier));
    assert (rep._plies[1].skill == Ac.basher);
    assert (rep._plies[2].skill == Ac.builder);
    assert (rep._plies[2].when == 103);
    rep.tweakImpl(ChangeRequest(rep._plies[2], ChangeVerb.moveThisEarlier));
    assert (rep._plies[1].skill == Ac.builder);
    assert (rep._plies[2].skill == Ac.basher);
    rep.tweakImpl(ChangeRequest(rep._plies[1], ChangeVerb.moveThisEarlier));
    assert (rep._plies[1].skill == Ac.builder);
    rep.tweakImpl(ChangeRequest(rep._plies[1], ChangeVerb.moveThisEarlier));
    assert (rep._plies[0].skill == Ac.blocker);
    assert (rep._plies[1].skill == Ac.builder);
    assert (rep._plies[0].when == rep._plies[1].when);
    rep.tweakImpl(ChangeRequest(rep._plies[1], ChangeVerb.moveThisEarlier));
    assert (rep._plies[0].skill == Ac.builder);
    assert (rep._plies[1].skill == Ac.blocker);
}

unittest {
    Replay rep = Replay.newNoLevelFilename(Date.now());
    immutable Ply a = rd(Ac.blocker, Phyu(100));
    immutable Ply b = rd(Ac.builder, Phyu(101));
    immutable Ply c = rd(Ac.basher, Phyu(103));
    rep.add(a);
    rep.add(b);
    rep.add(c);

    rep.tweakImpl(ChangeRequest(b, ChangeVerb.cutFutureOfOneLix));
    assert (rep._plies.length == 2);
    assert (rep._plies[0] == a);
    assert (rep._plies[1] == b);

    rep.tweakImpl(ChangeRequest(a, ChangeVerb.cutFutureOfOneLix));
    assert (rep._plies.length == 1);
    assert (rep._plies[0] == a);
}

unittest {
    Replay a = Replay.newNoLevelFilename(Date.now());
    for (int x = 100; x < 200; x += 10) {
        Ply ply;
        ply.isDirectionallyForced = true;
        ply.lixShouldFace = x % 20 == 10
            ? Ply.LixShouldFace.left : Ply.LixShouldFace.right;
        ply.skill = x % 40 < 20 ? Ac.digger : Ac.climber;
        ply.toWhichLix = 3;
        ply.when = Phyu(x);
        a.add(ply);
    }
    assert (a.allPlies.length == 10);
    a.cutFutureOfOneLixImpl(ChangeRequest(
        Ply(PlNr(0), Phyu(150), false, Ac.nothing, 3),
        ChangeVerb.cutFutureOfOneLix));
    assert (a.allPlies.length == 6); // 100, 110, 120, 130, 140, 150
    assert (a.allPlies[$-1].when == Phyu(150));
}
