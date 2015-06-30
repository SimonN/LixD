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

class GameState {

    int  update;
    int  clock;
    bool clock_running;

    private bool _goals_locked; // in singleplayer, when time has run out

    Tribe[] tribes;

    Hatch[] hatches;
    Goal[] goals;
    Gadget[] decos;
    Water[] waters;
    TrapTrig[] traps;
    GadgetCanBeOpen[] flingers;
    Trampoline[] trampolines;

    Torbit land;
    Lookup lookup;

    this() { }

/*  this(Gamestate)               -- copy constructor
 *  void foreach_gadget(function) -- apply to each gadget in drawing order
 */
    this(GameState rhs)
    {
        update        = rhs.update;
        clock         = rhs.clock;
        clock_running = rhs.clock_running;
        _goals_locked = rhs._goals_locked;

        tribes      = tribes     .clone;

        hatches     = hatches    .clone;
        goals       = goals      .clone;
        decos       = decos      .clone;
        waters      = waters     .clone;
        traps       = traps      .clone;
        flingers    = flingers   .clone;
        trampolines = trampolines.clone;

        land   = new Torbit(land);
        lookup = new Lookup(lookup);
    }

    @property bool goals_locked() const { return _goals_locked; }
    @property bool goals_locked(in bool b)
    {
        _goals_locked = b;
        foreach (goal; goals)
            goal.draw_with_no_sign = _goals_locked;
        return _goals_locked;
    }

    void foreach_gadget(void function(Gadget) func)
    {
        foreach (g; hatches)     func(g);
        foreach (g; goals)       func(g);
        foreach (g; decos)       func(g);
        foreach (g; waters)      func(g);
        foreach (g; traps)       func(g);
        foreach (g; flingers)    func(g);
        foreach (g; trampolines) func(g);
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
