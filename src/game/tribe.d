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
        int  lix_hatch;
        int  lix_saved;
        int  lix_saved_late; // after the goals have been locked
        int  lix_out;        // change this only when killing/generating lixes.
        int  lix_exiting;    // these have been scored, but keep game running
        int  spawnint_slow = 32;
        int  spawnint_fast =  4;
        int  spawnint      = 32;
        bool nuke;

        int update_hatch;
        int update_saved; // last lix saved within timelimit
        int hatch_next;

        int skills_used;
    }

    PublicValueFields value_fields;
    alias value_fields this;

    Enumap!(Ac, int) skills;
    Master[] masters;
    Lixxie[] lixvec;

    this() { }

    this(Tribe rhs)
    {
        value_fields = rhs.value_fields;
        skills       = rhs.skills;
        masters      = rhs.masters.dup;
        lixvec       = rhs.lixvec .clone;
    }

    Tribe clone() { return new Tribe(this); }

    @property {
        int still_playing()  const { return lix_out + lix_exiting + lix_hatch;}
        int score()          const { return lix_saved; }
        int score_expected() const { return lix_saved + lix_out + lix_hatch; }
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

    void return_skills(in Ac ac, in int amount)
    {
        if (skills[ac] != skill_infinity) {
            skills[ac] += amount;
            skills_used -= amount;
        }
    }

}
