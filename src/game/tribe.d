module game.tribe;

/* A tribe is a team. It can have multiple (Tribe.Master)s, when a multiplayer
 * team game is played. Each tribe has a color, number of lixes, etc.
 * In singleplayer, there is one tribe with one master.
 */

import enumap;

import basics.globals;
import basics.help;
import basics.nettypes;
import lix.enums;
import lix.lixxie;

class Tribe {

    struct Skill {
        Ac  ac;
        int nr;
    }

    struct Master {
        PlNr   number;
        string name;
    }

    private static struct PublicValueFields {
        Style style;

        int  initial;
        int  required;
        int  lixHatch;
        int  lixSaved;
        int  lixSavedLate; // after the goals have been locked
        int  lixOut;       // change this only when killing/generating lixes.
        int  lixExiting;   // these have been scored, but keep game running
        int  spawnintSlow = 32;
        int  spawnintFast =  4;
        int  spawnint     = 32;
        bool nuke;

        int update_hatch;
        int update_saved; // last lix saved within timelimit
        int hatch_next;

        int skillsUsed;
    }

    PublicValueFields valueFields;
    alias valueFields this;

    Enumap!(Ac, int) skills;
    Master[] masters;
    Lixxie[] lixvec;

    this() { }

    this(Tribe rhs)
    {
        valueFields = rhs.valueFields;
        skills      = rhs.skills;
        masters     = rhs.masters.dup;
        lixvec      = rhs.lixvec .clone;
    }

    Tribe clone() { return new Tribe(this); }

    @property {
        int stillPlaying()  const { return lixOut + lixExiting + lixHatch;}
        int score()         const { return lixSaved; }
        int scoreExpected() const { return lixSaved + lixOut + lixHatch; }
    }

    @property string name() const
    {
        string ret;
        foreach (int i, master; masters) {
            ret ~= master.name;
            if (i + 1 != masters.length)
                ret ~= ", ";
        }
        return ret;
    }

    void returnSkills(in Ac ac, in int amount)
    {
        if (skills[ac] != skillInfinity) {
            skills[ac] += amount;
            skillsUsed -= amount;
        }
    }

    inout(Master)* getMasterWithNumber(in PlNr number) inout
    {
        foreach (ref master; masters)
            if (master.number == number)
                return &master;
        return null;
    }

}
