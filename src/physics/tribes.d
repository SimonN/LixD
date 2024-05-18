module physics.tribes;

import enumap;
import std.algorithm;
import std.range;

import net.style;
import physics.tribe;

struct Tribes {
private:
    /*
     * _tribes can contain null. But the public interface won't offer null:
     * playerTribes(), allTribesEvenNeutral() iterate over non-null only.
     */
    Enumap!(Style, Tribe) _tribes;

public:
    void add(in Tribe.RuleSet newRules)
    in {
        import std.conv : text;
        assert (_tribes[newRules.style] is null,
            text("You've already added ", newRules.style, "."));
    }
    do {
        _tribes[newRules.style] = new Tribe(newRules);
    }

    Tribes clone() const
    {
        Tribes ret;
        foreach (tribe; allTribesEvenNeutral) {
            ret._tribes[tribe.style] = tribe.clone();
        }
        return ret;
    }

pure nothrow @safe @nogc:
    auto playerTribes()
    {
        return allTribesEvenNeutral.filter!(tr => tr.style != Style.neutral);
    }

    auto playerTribes() const
    {
        return allTribesEvenNeutral.filter!(tr => tr.style != Style.neutral);
    }

    auto allTribesEvenNeutral()
    {
        return _tribes.byValue.filter!(tr => tr !is null);
    }

    auto allTribesEvenNeutral() const
    {
        return _tribes.byValue.filter!(tr => tr !is null);
    }

    int numPlayerTribes() const { return playerTribes.walkLength & 0xFFFF; }

    Tribe theSingleTribe()
        in { assert (isPuzzle, "We're not in singleplayer."); }
        do { return playerTribes.front; }

    const(Tribe) theSingleTribe() const
        in { assert (isPuzzle, "We're not in singleplayer."); }
        do { return playerTribes.front; }

    bool contains(in Style st) const { return _tribes[st] !is null; }

    inout(Tribe) opIndex(in Style st) inout
        in { assert (contains(st), "Accessing an un-added tribe."); }
        do { return _tribes[st]; }

package:
    // Most others should ask these through RawGameState's methods.
    bool isBattle() const { return ! isPuzzle; }
    bool isPuzzle() const
        in { assert (numPlayerTribes > 0, "Add some tribes first."); }
        do { return numPlayerTribes == 1; }

    bool isSolvedPuzzle(in int lixRequired) const
    {
        return isPuzzle && theSingleTribe.score.lixSaved >= lixRequired;
    }
}



unittest {
    Tribes mutTrs;
    const(Tribes*) constTrs = &mutTrs;

    Tribe gettingTheTribeIsNogc() @nogc {
        foreach (a; mutTrs.playerTribes) {
            return a;
        }
        assert (false);
    }
    mutTrs.add(Tribe.RuleSet(Style.neutral));
    mutTrs.add(Tribe.RuleSet(Style.red));
    assert (gettingTheTribeIsNogc() is constTrs._tribes[Style.red]);
    assert (gettingTheTribeIsNogc().style == Style.red);
    assert (constTrs.numPlayerTribes == 1);
    assert (constTrs.isPuzzle);
    assert (! constTrs.isBattle);
    assert (constTrs.theSingleTribe.style == Style.red);

    mutTrs.add(Tribe.RuleSet(Style.green));
    assert (! constTrs.isPuzzle);
    assert (constTrs.isBattle);

    foreach (tr; constTrs.allTribesEvenNeutral) {
        assert (tr !is null);
    }
}
