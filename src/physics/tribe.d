module physics.tribe;

/* A Tribe is a colored team. It can have multiple players, when a multiplayer
 * team game is played. Each tribe has a color, number of lixes, etc.
 * In singleplayer, there is one tribe with one master.
 *
 * Tribe (as physics in general) doesn't know about players.
 * If player info is needed, the game must fetch it from the replay.
 */

import std.algorithm;

import core.stdc.string : memcpy; // To clone LixxieImpl structs.
// We want to treat LixxieImpl like a POD, but it holds pointers.

import enumap;
import optional;

import basics.globals;
import basics.help;
import basics.rect;
import net.ac;
import net.handicap;
import net.repdata;
import net.style;
import physics.fracint;
import physics.handimrg;
import physics.lixxie.fields;
import physics.lixxie.lixxie;
import physics.score;

final class Tribe {
private:
    int _lixSpawned; // 0 at start
    int _lixOut;
    int _lixLeaving; // these have been scored, but keep game running
    int _lixSaved; // query with score()

    Optional!Phyu _previousSpawn = none;
    Optional!Phyu _firstScoring = none;
    Optional!Phyu _recentScoring = none;
    Optional!Phyu _outOfLixSince = none;
    Optional!Phyu _nukePressedAt = none;

public:
    immutable RuleSet rules;

    LixxieImpl[] lixvecImpl;
    Enumap!(Ac, int) skillsUsed;
    int nextHatch; // Initialized by the state initalizer with the permu.
                   // We don't need the permu afterwards for spawns.

public:
    struct RuleSet {
        enum MustNukeWhen : ubyte {
            normalOvertime,
            raceToFirstSave,
        }

        Style style;
        int initialLixInHatchWithoutHandicap;
        int lixRequired; // Singleplayer save requirement. 0 in multiplayer.
        int spawnInterval; // Number of physics updates between two spawns.
        Enumap!(Ac, int) initialSkillsWithoutHandicap; // may be skillInfinity
        MustNukeWhen mustNukeWhen;
        MergedHandicap handicap;
    }

    enum Phyu firstSpawnWithoutHandicap = Phyu(60);

    this(in RuleSet r) { rules = r; }

    this(in Tribe rhs)
    {
        assert (rhs, "don't copy-construct from a null Tribe");
        _lixSpawned = rhs._lixSpawned;
        _lixOut = rhs._lixOut;
        _lixLeaving = rhs._lixLeaving;
        _lixSaved = rhs._lixSaved;
        _previousSpawn = rhs._previousSpawn;
        _firstScoring = rhs._firstScoring;
        _outOfLixSince = rhs._outOfLixSince;
        _nukePressedAt = rhs._nukePressedAt;
        rules = rhs.rules;
        skillsUsed = rhs.skillsUsed;
        nextHatch = rhs.nextHatch;

        lixvecImpl.length = rhs.lixvecImpl.length;
        if (lixvecImpl.length > 0) {
            memcpy(&lixvecImpl[0], &rhs.lixvecImpl[0],
                lixvecImpl.length * LixxieImpl.sizeof);
        }
    }

    Tribe clone() const { return new Tribe(this); }

    auto lixvec() @nogc // mutable. For const, see 5 lines below
    {
        Lixxie f(ref LixxieImpl value) { return &value; }
        return lixvecImpl.map!f;
    }

    auto lixvec() const @nogc
    {
        ConstLix f(ref const(LixxieImpl) value) { return &value; }
        return lixvecImpl[].map!f;
    }

    const pure nothrow @safe @nogc {
        Style style() { return rules.style; }

        int lixlen() { return lixvecImpl.len; }

        bool outOfLix() { return _lixOut == 0 && lixInHatch == 0; }
        bool doneAnimating() { return outOfLix() && ! _lixLeaving; }

        int lixOut() { return _lixOut; }
        int lixInHatch() {
            return rules.handicap.initialLix.scale(
                rules.initialLixInHatchWithoutHandicap) - _lixSpawned;
        }

        Phyu firstSpawnIncludingHandicap()
        {
            return Phyu(firstSpawnWithoutHandicap
                + rules.handicap.delayInPhyus);
        }

        Optional!Phyu phyuOfNextSpawn()
        {
            if (lixInHatch == 0) {
                return no!Phyu;
            }
            return some(_previousSpawn.match!(
                () => firstSpawnIncludingHandicap,
                (prev) => Phyu(prev + rules.spawnInterval),
            ));
        }

        bool canStillUse(in Ac ac)
        {
            immutable int left = usesLeft(ac);
            return left > 0 || left == skillInfinity;
        }

        int usesLeft(in Ac ac)
        {
            if (rules.initialSkillsWithoutHandicap[ac] == skillInfinity) {
                return skillInfinity;
            }
            immutable int atStart = rules.handicap.initialSkills.scale(
                rules.initialSkillsWithoutHandicap[ac])
                + rules.handicap.extraSkills;
            return atStart - skillsUsed[ac];
        }

        Score score()
        {
            Score ret;
            ret.style = style;
            ret.lixSaved = FracInt(_lixSaved, rules.handicap.score);
            ret.lixYetUnsavedRaw = _lixOut + lixInHatch;
            ret.prefersGameToEnd = prefersGameToEnd;
            return ret;
        }

        bool hasScored()
        {
            immutable ret = _lixSaved > 0;
            assert (ret != _firstScoring.empty);
            return ret;
        }

        bool hasSolvedThePuzzle()
        {
            assert (rules.handicap.score == Fraction(1, 1),
                "Handicap in singleplayer isn't well-defined.");
            return _lixSaved >= rules.lixRequired;
        }
    }

    ///////////////////////////////////////////////////////////////////////////
    // Mutation
    ///////////////////////////////////////////////////////////////////////////

    void recordSpawnedFromHatch()
    in { assert (this.lixInHatch > 0); }
    out { assert (this.lixInHatch >= 0 && this._lixOut >= 0); }
    do {
        ++_lixSpawned;
        ++_lixOut;
    }

    void recordOutToLeaver(in Phyu now)
    in {
        assert (this._lixOut > 0);
        assert (this._outOfLixSince.empty);
    }
    out {
        assert (this._lixOut >= 0 && this._lixLeaving >= 0);
    }
    do {
        --_lixOut;
        ++_lixLeaving;
        if (outOfLix)
            _outOfLixSince = now;
    }

    void recordLeaverDone()
    in { assert (this._lixLeaving > 0); }
    out { assert (this._lixOut >= 0 && this._lixLeaving >= 0); }
    do { --_lixLeaving; }

    void stopSpawningAnyMoreLixBecauseWeAreNuking()
    {
        _lixSpawned = rules.handicap.initialLix.scale(
            rules.initialLixInHatchWithoutHandicap);
    }

    void addSaved(in Style fromWho, in Phyu now)
    {
        _recentScoring = now;
        if (_lixSaved == 0)
            _firstScoring = now;
        ++_lixSaved;
    }

    void returnSkills(in Ac ac, in int amount)
    {
        skillsUsed[ac] -= amount;
    }

    void spawnLixxie(OutsideWorld* ow)
    in {
        import std.string;
        assert (ow.state.hatches[this.nextHatch].hasOwner(this.style),
            format("Style %s spawns from wrong hatch #%d.",
                this.style, this.nextHatch));
    }
    do {
        const hatch = ow.state.hatches[nextHatch];
        LixxieImpl newLix = LixxieImpl(ow, Point(
            hatch.loc.x + hatch.tile.trigger.x - 2 * hatch.spawnFacingLeft,
            hatch.loc.y + hatch.tile.trigger.y));
        if (hatch.spawnFacingLeft)
            newLix.turn();
        lixvecImpl ~= newLix;
        recordSpawnedFromHatch();
        _previousSpawn = ow.state.age;
        do {
            nextHatch = (nextHatch + 1) % ow.state.hatches.len;
        }
        while (! ow.state.hatches[nextHatch].hasOwner(this.style));
    }


    ///////////////////////////////////////////////////////////////////////////
    // Nuke
    ///////////////////////////////////////////////////////////////////////////

    void recordNukePressedAt(Phyu u) @nogc { _nukePressedAt = u; }

    const pure nothrow @safe @nogc {
        bool hasNuked() { return ! _nukePressedAt.empty; }
        bool prefersGameToEnd() { return ! prefersGameToEndSince.empty; }
        bool triggersOvertime()
        {
            immutable ret = prefersGameToEnd && hasScored;
            assert (ret == ! triggersOvertimeSince.empty);
            return ret;
        }

        private Optional!Phyu finishedRaceAt()
        {
            return rules.mustNukeWhen == RuleSet.MustNukeWhen.raceToFirstSave
                ? _firstScoring : no!Phyu;
        }

        Optional!Phyu prefersGameToEndSince()
        {
            return optmin(_nukePressedAt, _outOfLixSince, finishedRaceAt);
        }

        Optional!Phyu triggersOvertimeSince()
        out (ret) {
            assert (ret.empty != (prefersGameToEnd && hasScored));
        }
        do {
            if (! hasScored) {
                return no!Phyu;
            }
            return optmin(
                hasNuked ? optmax(_nukePressedAt, _firstScoring) : no!Phyu,
                outOfLix ? optmax(_outOfLixSince, _firstScoring) : no!Phyu,
                finishedRaceAt);
        }
    }
}

private:

/*
 * optmin(x, y) == the usual min(x, y).
 * optmin(x, none) == x: We discard (none) before applying min to the rest.
 * optmin(none, none) == none.
 */
Optional!Phyu optreduce(alias pairingFunc)(Optional!Phyu[] nrs...)
    pure nothrow @safe @nogc
{
    auto usefuls = nrs[].joiner; // Range of Phyus: all nonempty optionals.
    if (usefuls.empty) {
        return no!Phyu;
    }
    Phyu accum = usefuls.front; // Avoid std.algorithm.reduce, it throws.
    usefuls.popFront();
    while (! usefuls.empty) {
        accum = pairingFunc(accum, usefuls.front);
        usefuls.popFront;
    }
    return accum.some;
}

alias optmin = optreduce!min;
alias optmax = optreduce!max;

unittest {
    immutable x = Optional!Phyu(Phyu(8));
    immutable y = Optional!Phyu(Phyu(7));
    immutable z = no!Phyu;
    assert (optmin(x, y) == y);
    assert (optmin(y, z) == y);
    assert (optmin(x, z) == x);
    assert (optmin(z, y, z) == y);
    assert (optmin(z, z, z) == no!Phyu);
    assert (optmin() == no!Phyu);
}
