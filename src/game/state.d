module game.state;

/* A gamestate. It saves everything about the current position, but not
 * how we got here. The class Replay saves everything about the history,
 * so you can reconstruct the current state from the beginning gamestate and
 * a replay.
 */

// DTODOLANG: Translate this comment
/*
 * gameplay/state.h
 *
 * Statesaves-Manager: Hier werden alle vollwertigen Spielstaende verwaltet,
 * die unterweges so anfallen. Das angeforderte Speichern im Einspielermodus
 * zaehlt dazu, aber auch das automatische Speichern im Netzwerkmodus.
 * In diesen Faellen wird bei verspaetet eintreffenden Paketen ab einem
 * geeingeten Spielstand neu gerechnet.
 *
 * For the user-triggered save, it also remembers the replay that was active
 * then. This is important since the user could otherwise restart, do something
 * deviating, and then load the user state that supposes the old, differing
 * replay.
 *
 * void calc_save_auto(unsigned long, std::vector <Player>&, BITMAP*)
 *
 *   Schaut sich die uebergebene Update-Zahl an und entscheidet, wie mit den
 *   weiteren uebergebenen Daten zu verfahren ist: Speichern oder nichts tun.
 *   In dieser Funktion werden, je nach Bedarf, auch die bisher angesammelten
 *   automatischen Staende per Zeigervertausch umgelegt.
 *
 * const State& load_user()
 * const State& load_auto(unsigned long)
 *
 *   Diese laden einen zuvor gespeicherten Spielstand: Entweder den per
 *   Klick auf die Speichertaste angelegten Stand oder den juengsten Stand,
 *   der mindestens so alt ist wie die angegebene Spielzeit in Updates.
 *
 *   Die letztere Funktion wird die Gameplay-Klasse moeglicherweise dazu
 *   bringen, vieles neu auszurechnen und dabei auch haeufig neue calc()-
 *   -Anforderungen zu stellen. Neuere automatisch gespeicherte Staende als
 *   der von load_auto() zurueckgegebene werden dadurch beim Neurechnen
 *   ebenfalls aktualisiert.
 *
 */

import basics.help; // deep_copy for arrays
import game.lookup;
import game.tribe;
import graphic.torbit;
import graphic.gadget;

// DTODO: import the correct classes. These are only mockups.
class Triggerable {
    this(in Triggerable rhs) { }
}

class GameState {

    int  update;
    int  clock;
    bool clock_running;
    bool goals_locked; // in singleplayer, when time has run out

    Tribe[] tribes;
    Hatch[] hatches;
    Gadget[] goals;
    Gadget[] decos;
    Triggerable[] traps;
    Triggerable[] flingers;
    Triggerable[] trampolines;

    Torbit land;
    Lookup lookup;

    this() { }

    this(GameState rhs)
    {
        update        = rhs.update;
        clock         = rhs.clock;
        clock_running = rhs.clock_running;
        goals_locked  = rhs.goals_locked;

        tribes      = tribes     .deep_copy;
        hatches     = hatches    .deep_copy;
        goals       = goals      .deep_copy;
        decos       = decos      .deep_copy;
        traps       = traps      .deep_copy;
        flingers    = flingers   .deep_copy;
        trampolines = trampolines.deep_copy;

        land   = new Torbit(land);
        lookup = new Lookup(lookup);
    }
}


/*
class StateManager {

private:

    immutable updates_sml =  10;
    immutable updates_med =  50;
    immutable updates_big = 200;

    GameState
        zero,  user,
        sml_1, sml_2,
        med_1, med_2,
        big_1, big_2;

    Replay userrep;

public:

    skvoid  save_zero(const GameState& s) { zero = s; }
    skvoid  save_user(const GameState& s,
                           const Replay& r)    { user = s; userrep = r; }

    skconst GameState& get_zero()        { return zero;    }
    skconst GameState& get_user()        { return user;    }
    skconst Replay&    get_user_replay() { return userrep; }

    const        GameState& get_auto(Ulng);
    void                    calc_save_auto(const GameState&);

};
*/
