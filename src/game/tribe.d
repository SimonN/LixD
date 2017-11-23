module game.tribe;

/* A tribe is a team. It can have multiple masters, when a multiplayer
 * team game is played. Each tribe has a color, number of lixes, etc.
 * In singleplayer, there is one tribe with one master.
 *
 * Tribe doesn't know about masters; if that info is needed, the game must
 * fetch it from the replay.
 */

import std.algorithm;

import enumap;

import basics.globals;
import basics.help;
import basics.rect;
import game.score;
import net.repdata;
import lix;
import level.level; // spawnintMax

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
    {
        const hatch = ow.state.hatches[nextHatch];
        LixxieImpl newLix = LixxieImpl(ow, Point(
            hatch.x + hatch.tile.trigger.x - 2 * hatch.spawnFacingLeft,
            hatch.y + hatch.tile.trigger.y));
        if (hatch.spawnFacingLeft)
            newLix.turn();
        lixvecImpl ~= newLix;
        recordSpawnedFromHatch();
        updatePreviousSpawn = ow.state.update;
        nextHatch += ow.state.numTribes;
        nextHatch %= ow.state.hatches.len;
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
        in { assert (triggersOvertime); }
        out (ret) { assert (ret >= firstScoring); }
        body {
            return min(nukePressed ? max(_nukePressedSince, firstScoring)
                                   : Phyu(int.max),
                outOfLix ? finishedPlayingAt : Phyu(int.max),
                rule == rule.raceToFirstSave ? firstScoring : Phyu(int.max));
        }
    }
}
