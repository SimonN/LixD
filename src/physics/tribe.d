module physics.tribe;

/* A Tribe is a colored team. It can have multiple players, when a multiplayer
 * team game is played. Each tribe has a color, number of lixes, etc.
 * In singleplayer, there is one tribe with one master.
 *
 * Tribe (as physics in general) doesn't know about players.
 * If player info is needed, the game must fetch it from the replay.
 */

import std.algorithm;

import enumap;
import optional;

import basics.globals;
import basics.help;
import basics.rect;
import lix;
import level.level; // spawnintMax
import net.repdata;
import physics.score;

final class Tribe {
    immutable RuleSet rules;
    ValueFields valueFields;
    alias valueFields this;

    LixxieImpl[] lixvecImpl;

    struct RuleSet {
        enum MustNukeWhen : ubyte {
            normalOvertime,
            raceToFirstSave,
        }

        Style style;
        MustNukeWhen mustNukeWhen;
        int initialLixInHatchWithoutHandicap;
        int spawnInterval; // number of physics updates until next spawn
        Enumap!(Ac, int) initialSkillsWithoutHandicap; // may be skillInfinity
    }

    private static struct ValueFields {
    private:
        Optional!Phyu _updatePreviousSpawn = none;
        Phyu _firstScoring; // Phyu(0) if ! hasScored()
        Phyu _recentScoring; // Phyu(0) if ! hasScored()
        Phyu _finishedPlayingAt; // Phyu(0) if can make more decisions
        Phyu _nukePressedSince; // Phyu(0) if never pressed

        int _lixSpawned; // 0 at start
        int _lixOut;
        int _lixLeaving; // these have been scored, but keep game running
        int _lixSaved; // query with score()

    public:
        Enumap!(Ac, int) skillsUsed;
        int nextHatch; // Initialized by the state initalizer with the permu.
                       // We don't need the permu afterwards for spawns.
    }

    enum Phyu firstSpawnWithoutHandicap = Phyu(60);

public:
    this(in RuleSet r) { rules = r; }

    this(in Tribe rhs)
    {
        assert (rhs, "don't copy-construct from a null Tribe");
        valueFields = rhs.valueFields;
        lixvecImpl = rhs.lixvecImpl.clone; // only value types since 2017-09!
        rules = rhs.rules;
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

    const pure @safe @nogc {
        Style style() { return rules.style; }

        int lixlen() { return lixvecImpl.len; }

        bool outOfLix() { return _lixOut == 0 && lixInHatch == 0; }
        bool doneAnimating() { return outOfLix() && ! _lixLeaving; }

        int lixOut() { return _lixOut; }
        int lixInHatch() {
            return rules.initialLixInHatchWithoutHandicap - _lixSpawned;
        }

        Optional!Phyu phyuOfNextSpawn()
        {
            if (lixInHatch == 0) {
                return no!Phyu;
            }
            return some(_updatePreviousSpawn.match!(
                () => firstSpawnWithoutHandicap,
                (prev) => Phyu(prev + rules.spawnInterval),
            ));
        }

        bool canStillUse(in Ac ac)
        {
            return usesLeft(ac) > 0 || usesLeft(ac) == skillInfinity;
        }

        int usesLeft(in Ac ac)
        {
            return rules.initialSkillsWithoutHandicap[ac] == skillInfinity
                ? skillInfinity
                : rules.initialSkillsWithoutHandicap[ac] - skillsUsed[ac];
        }

        Score score()
        {
            Score ret;
            ret.style = style;
            ret.current = _lixSaved;
            ret.potential = _lixSaved + _lixOut + lixInHatch;
            ret.prefersGameToEnd = prefersGameToEnd;
            return ret;
        }

        bool hasScored() { return _lixSaved > 0; }

        Phyu firstScoring()
        in { assert (hasScored); }
        do { return _firstScoring; }

        Phyu recentScoring()
        in { assert (hasScored); }
        do { return _recentScoring; }

        Phyu finishedPlayingAt()
        in { assert (outOfLix); }
        do { return _finishedPlayingAt; }
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
        assert (this._finishedPlayingAt == this._finishedPlayingAt.init
            ||  this._finishedPlayingAt == now);
    }
    out {
        assert (this._lixOut >= 0 && this._lixLeaving >= 0);
    }
    do {
        --_lixOut;
        ++_lixLeaving;
        if (outOfLix)
            _finishedPlayingAt = now;
    }

    void recordLeaverDone()
    in { assert (this._lixLeaving > 0); }
    out { assert (this._lixOut >= 0 && this._lixLeaving >= 0); }
    do { --_lixLeaving; }

    void stopSpawningAnyMoreLixBecauseWeAreNuking()
    {
        _lixSpawned = rules.initialLixInHatchWithoutHandicap;
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
        if (! ow.state.hatches[this.nextHatch].hasTribe(this.style)) {
            import std.string;
            string msg = format("Style %s spawns from wrong hatch #%d.",
                this.style, this.nextHatch);
            foreach (const size_t i, hatch; ow.state.hatches) {
                msg ~= format("\nHatch #%d has styles:", i);
                foreach (Style st; hatch.tribes) {
                    msg ~= " " ~ styleToString(st);
                }
            }
            assert (false, msg);
        }
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
        _updatePreviousSpawn = ow.state.update;
        do {
            nextHatch = (nextHatch + 1) % ow.state.hatches.len;
        }
        while (! ow.state.hatches[nextHatch].hasTribe(this.style));
    }


    ///////////////////////////////////////////////////////////////////////////
    // Nuke
    ///////////////////////////////////////////////////////////////////////////

    void nukePressedSince(Phyu u) @nogc { _nukePressedSince = u; }

    const pure @safe @nogc {
        bool nukePressed() { return _nukePressedSince > Phyu(0); }

        bool prefersGameToEnd()
        {
            return nukePressed || outOfLix
                || (rules.mustNukeWhen == RuleSet.MustNukeWhen.raceToFirstSave
                    && hasScored);
        }

        Phyu prefersGameToEndSince()
        in { assert (prefersGameToEnd); }
        do {
            return min(
                nukePressed ? _nukePressedSince : Phyu(int.max),
                outOfLix ? finishedPlayingAt : Phyu(int.max),
                (rules.mustNukeWhen == RuleSet.MustNukeWhen.raceToFirstSave
                    && hasScored) ? firstScoring : Phyu(int.max));
        }

        bool triggersOvertime()
        {
            return prefersGameToEnd && hasScored;
        }

        Phyu triggersOvertimeSince()
        in { assert (triggersOvertime, "call only when we trigger overtime"); }
        out (ret) {
            assert (ret != Phyu(int.max), "At least one of the ?: in this "
                ~ "function should return a good value instead of int.max. "
                ~ "If all return int.max, we probably shouldn't "
                ~ "triggersOvertimeSince. Check its in contract.");
            assert (hasScored, "We can only trigger overtime after scoring.");
            assert (ret >= firstScoring, "If we nuke before saving a lix, "
                ~ "we should trigger overtime on first save. Such an earlier "
                ~ "nuke counts as prefersGameToEnd, not as triggersOvertime.");
        }
        do {
            return min(nukePressed ? max(_nukePressedSince, firstScoring)
                                   : Phyu(int.max),
                outOfLix ? max(finishedPlayingAt, firstScoring)
                         : Phyu(int.max),
                rules.mustNukeWhen == RuleSet.MustNukeWhen.raceToFirstSave
                    ? firstScoring : Phyu(int.max));
        }
    }
}
