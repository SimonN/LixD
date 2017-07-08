module game.tribe;

/* A tribe is a team. It can have multiple masters, when a multiplayer
 * team game is played. Each tribe has a color, number of lixes, etc.
 * In singleplayer, there is one tribe with one master.
 *
 * Tribe doesn't know about masters; if that info is needed, the game must
 * fetch it from the replay.
 */

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
        Phyu _hasScoredSince; // Phyu(0) if ! hasScored()
        Phyu _updatePreviousSave; // ...within the time limit
        int  _lixSaved; // query with score()

    public:
        Style style;

        int  lixHatch;
        int  lixOut;       // change this only when killing/generating lixes.
        int  lixLeaving;   // these have been scored, but keep game running
        int  spawnint;
        Phyu wantsNukeSince; // Phyu(0) if doesn't want nuke

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

    @property int stillPlaying() const { return lixOut+lixLeaving+lixHatch; }

    @property Score score() const @nogc
    {
        Score ret;
        ret.style = style;
        ret.current = _lixSaved;
        ret.potential = _lixSaved + lixOut + lixHatch;
        return ret;
    }

    @property bool hasScored() const @nogc { return score.current > 0; }

    @property Phyu hasScoredSince() const @nogc
    in { assert (hasScored); }
    body { return _hasScoredSince; }

    @property Phyu updatePreviousSave() const @nogc
    {
        return _updatePreviousSave;
    }

    void addSaved(in Style fromWho, in Phyu now)
    {
        if (_lixSaved == 0)
            _hasScoredSince = now;
        ++_lixSaved;
        _updatePreviousSave = now;
    }

    @property bool wantsNuke() const @nogc { return wantsNukeSince > Phyu(0); }

    void returnSkills(in Ac ac, in int amount)
    {
        skillsUsed -= amount;
        if (skills[ac] != skillInfinity)
            skills[ac] += amount;
    }
}
