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

import basics.globals;
import basics.help;
import basics.rect;
import lix;
import level.level; // spawnintMax
import net.repdata;
import physics.score;

final class Tribe {
    private static struct ValueFields {
    private:
        Phyu _firstScoring; // Phyu(0) if ! hasScored()
        Phyu _recentScoring; // Phyu(0) if ! hasScored()
        Phyu _finishedPlayingAt; // Phyu(0) if can maken more decisions
        Phyu _nukePressedSince; // Phyu(0) if never pressed

        int  _lixOut;
        int  _lixLeaving; // these have been scored, but keep game running
        int  _lixSaved; // query with score()

    public:
        Style style;
        int spawnint;
        int lixHatch;

        Phyu updatePreviousSpawn = Phyu(-Level.spawnintMax); // => at once
        int nextHatch; // Initialized by the state initalizer with the permu.
                       // We don't need the permu afterwards for spawns.
        int skillsUsed;
    }

    ValueFields valueFields;
    alias valueFields this;

    Enumap!(Ac, int) skills;
    LixxieImpl[] lixvecImpl;
    immutable(Rule) rule; // affects how the tribe judges whether he nukes

    enum Rule {
        normalOvertime,
        raceToFirstSave,
    }

    this(in Rule aRule) { rule = aRule; }

    this(in Tribe rhs)
    {
        assert (rhs, "don't copy-construct from a null Tribe");
        valueFields = rhs.valueFields;
        skills = rhs.skills;
        lixvecImpl = rhs.lixvecImpl.clone; // only value types since 2017-09!
        rule = rhs.rule;
    }

    Tribe clone() const { return new Tribe(this); }

    @property lixvec() @nogc // mutable. For const, see 5 lines below
    {
        Lixxie f(ref LixxieImpl value) { return &value; }
        return lixvecImpl.map!f;
    }

    @property const @nogc {
        auto lixvec()
        {
            ConstLix f(ref const(LixxieImpl) value) { return &value; }
            return lixvecImpl[].map!f;
        }

        int lixlen() { return lixvecImpl.len; }

        bool outOfLix() { return _lixOut == 0 && lixHatch == 0; }
        bool doneAnimating() { return outOfLix() && ! _lixLeaving; }

        int lixOut() { return _lixOut; }
        Score score()
        {
            Score ret;
            ret.style = style;
            ret.current = _lixSaved;
            ret.potential = _lixSaved + _lixOut + lixHatch;
            ret.prefersGameToEnd = prefersGameToEnd;
            return ret;
        }

        bool hasScored() { return _lixSaved > 0; }

        Phyu firstScoring()
        in { assert (hasScored); }
        body { return _firstScoring; }

        Phyu recentScoring()
        in { assert (hasScored); }
        body { return _recentScoring; }

        Phyu finishedPlayingAt()
        in { assert (outOfLix); }
        body{ return _finishedPlayingAt; }
    }

    ///////////////////////////////////////////////////////////////////////////
    // Mutation
    ///////////////////////////////////////////////////////////////////////////

    void recordSpawnedFromHatch()
    in { assert (this.lixHatch > 0); }
    out { assert (this.lixHatch >= 0 && this._lixOut >= 0); }
    body{
        --lixHatch;
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
    body{
        --_lixOut;
        ++_lixLeaving;
        if (outOfLix)
            _finishedPlayingAt = now;
    }

    void recordLeaverDone()
    in { assert (this._lixLeaving > 0); }
    out { assert (this._lixOut >= 0 && this._lixLeaving >= 0); }
    body{ --_lixLeaving; }

    void addSaved(in Style fromWho, in Phyu now)
    {
        _recentScoring = now;
        if (_lixSaved == 0)
            _firstScoring = now;
        ++_lixSaved;
    }

    void returnSkills(in Ac ac, in int amount)
    {
        skillsUsed -= amount;
        if (skills[ac] != skillInfinity)
            skills[ac] += amount;
    }

    void spawnLixxie(OutsideWorld* ow)
    in {
        if (! ow.state.hatches[this.nextHatch].hasTribe(this.style)) {
            import std.string;
            string msg = format("Style %s spawns from wrong hatch #%d.",
                this.style, this.nextHatch);
            foreach (int i, hatch; ow.state.hatches) {
                msg ~= format("\nHatch #%d has styles:", i);
                foreach (Style st; hatch.tribes) {
                    msg ~= " " ~ styleToString(st);
                }
            }
            assert (false, msg);
        }
    }
    body {
        const hatch = ow.state.hatches[nextHatch];
        LixxieImpl newLix = LixxieImpl(ow, Point(
            hatch.loc.x + hatch.tile.trigger.x - 2 * hatch.spawnFacingLeft,
            hatch.loc.y + hatch.tile.trigger.y));
        if (hatch.spawnFacingLeft)
            newLix.turn();
        lixvecImpl ~= newLix;
        recordSpawnedFromHatch();
        updatePreviousSpawn = ow.state.update;
        do {
            nextHatch = (nextHatch + 1) % ow.state.hatches.len;
        }
        while (! ow.state.hatches[nextHatch].hasTribe(this.style));
    }


    ///////////////////////////////////////////////////////////////////////////
    // Nuke
    ///////////////////////////////////////////////////////////////////////////

    @property void nukePressedSince(Phyu u) @nogc { _nukePressedSince = u; }

    @property const @nogc {
        bool nukePressed() { return _nukePressedSince > Phyu(0); }

        bool prefersGameToEnd()
        {
            return nukePressed || outOfLix
                || rule == rule.raceToFirstSave && hasScored;
        }

        Phyu prefersGameToEndSince()
        in { assert (prefersGameToEnd); }
        body {
            return min(
                nukePressed ? _nukePressedSince : Phyu(int.max),
                outOfLix ? finishedPlayingAt : Phyu(int.max),
                rule == rule.raceToFirstSave && hasScored
                    ? firstScoring : Phyu(int.max));
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
        body {
            return min(nukePressed ? max(_nukePressedSince, firstScoring)
                                   : Phyu(int.max),
                outOfLix ? max(finishedPlayingAt, firstScoring)
                         : Phyu(int.max),
                rule == rule.raceToFirstSave ? firstScoring : Phyu(int.max));
        }
    }
}
