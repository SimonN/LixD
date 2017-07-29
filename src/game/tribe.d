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
import game.score;
import net.repdata;
import lix;
import level.level; // spawnintMax

class Tribe {
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
    Lixxie[] lixvec;

    this() { }

    this(in Tribe rhs)
    {
        assert (rhs, "don't copy-construct from a null Tribe");
        valueFields = rhs.valueFields;
        skills      = rhs.skills;
        lixvec      = rhs.lixvec .clone;
    }

    Tribe clone() const { return new Tribe(this); }

    @property const @nogc {
        bool doneDeciding()  { return _lixOut == 0 && lixHatch == 0; }
        bool doneAnimating() { return doneDeciding() && ! _lixLeaving; }

        int lixOut() { return _lixOut; }
        Score score()
        {
            Score ret;
            ret.style = style;
            ret.current = _lixSaved;
            ret.potential = _lixSaved + _lixOut + lixHatch;
            return ret;
        }

        bool hasScored() { return score.current > 0; }
        Phyu firstScoring() { return _firstScoring; }
        Phyu recentScoring() { return _recentScoring; }

        Phyu finishedPlayingAt()
        in { assert (doneDeciding); }
        do { return _finishedPlayingAt; }
    }

    ///////////////////////////////////////////////////////////////////////////
    // Mutation
    ///////////////////////////////////////////////////////////////////////////

    void recordSpawnedFromHatch()
    in { assert (this.lixHatch > 0); }
    out { assert (this.lixHatch >= 0 && this._lixOut >= 0); }
    do {
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
    do {
        --_lixOut;
        ++_lixLeaving;
        if (doneDeciding)
            _finishedPlayingAt = now;
    }

    void recordLeaverDone()
    in { assert (this._lixLeaving > 0); }
    out { assert (this._lixOut >= 0 && this._lixLeaving >= 0); }
    do { --_lixLeaving; }

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

    ///////////////////////////////////////////////////////////////////////////
    // Nuke
    ///////////////////////////////////////////////////////////////////////////

    @property void nukePressedSince(Phyu u) @nogc { _nukePressedSince = u; }

    @property const @nogc {
        bool nukePressed()
        {
            return _nukePressedSince > Phyu(0);
        }

        bool triggersOvertime()
        {
            return hasScored && (nukePressed || doneDeciding);
        }

        Phyu triggersOvertimeSince()
        in { assert (triggersOvertime); }
        do {
            if (nukePressed && doneDeciding)
                return min(finishedPlayingAt,
                            max(_nukePressedSince, firstScoring));
            else if (nukePressed)
                return max(_nukePressedSince, firstScoring);
            else
                return finishedPlayingAt;
        }

        bool wantsAbortiveTie()
        {
            return ! hasScored && (nukePressed || doneDeciding);
        }

        Phyu wantsAbortiveTieSince()
        in { assert (wantsAbortiveTie); }
        do {
            if (nukePressed && doneDeciding)
                return min(_nukePressedSince, finishedPlayingAt);
            else if (nukePressed)
                return _nukePressedSince;
            else
                return finishedPlayingAt;
        }
    }
}
