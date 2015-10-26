module lix.acfunc;

import game.state;
import lix.enums;
import lix.lixxie;
import hardware.sound;

AcFunc[Ac.MAX] ac_func;

// static this() -- fills ac_func with the necessary data, see below

struct UpdateArgs {
    GameState st;
    int       id; // the lix's id, to pass to the effect manager

    this(GameState _st, in int _id = 0) { st = _st; id = _id; }

    // a function to counter compiler warnings in lixxie-updating functions
    // that take an UpdateArgs argument, but don't need it
    void suppress_unused_variable_warning() const { }
}



struct AcFunc {
    bool  pass_top;
    bool  leaving;
    bool  blockable;

    Sound soundAssign;
    Sound soundBecome;

    void function(Lixxie) assclk;
    void function(Lixxie) become;
    void function(Lixxie, in UpdateArgs) update;
}



static this()
{
    foreach (ref acf; ac_func) {
        acf.blockable = true;
        acf.soundAssign = Sound.ASSIGN;
    }

    // DTODO: Uncomment these as they get implemented, or assign them
    // to ac_func straight from the modules implementing them

    // ac_func[Ac.WALKER]    .assclk = assclk_walker;
    // ac_func[Ac.RUNNER]    .assclk = assclk_runner;
    // ac_func[Ac.CLIMBER]   .assclk = assclk_climber;
    // ac_func[Ac.FLOATER]   .assclk = assclk_floater;
    // ac_func[Ac.EXPLODER]  .assclk = assclk_exploder;
    // ac_func[Ac.EXPLODER2] .assclk = assclk_exploder2;
    // ac_func[Ac.BUILDER]   .assclk = assclk_builder;
    // ac_func[Ac.PLATFORMER].assclk = assclk_platformer;

    // ac_func[Ac.FALLER]    .become = become_faller;
    // ac_func[Ac.TUMBLER]   .become = become_tumbler;
    // ac_func[Ac.DROWNER]   .become = become_drowner;
    // ac_func[Ac.EXITER]    .become = become_exiter;
    // ac_func[Ac.WALKER]    .become = become_walker;
    // ac_func[Ac.CLIMBER]   .become = become_climber;
    // ac_func[Ac.ASCENDER]  .become = become_ascender;
    // ac_func[Ac.BUILDER]   .become = become_builder;
    // ac_func[Ac.CUBER]     .become = become_cuber;
    // ac_func[Ac.PLATFORMER].become = become_platformer;
    // ac_func[Ac.DIGGER]    .become = become_digger;
    // ac_func[Ac.JUMPER]    .become = become_jumper;

    // ac_func[Ac.FALLER]    .update = update_faller;
    // ac_func[Ac.TUMBLER]   .update = update_tumbler;
    // ac_func[Ac.STUNNER]   .update = update_stunner;
    // ac_func[Ac.LANDER]    .update = update_lander;
    // ac_func[Ac.SPLATTER]  .update = update_splatter;
    // ac_func[Ac.BURNER]    .update = update_burner;
    // ac_func[Ac.DROWNER]   .update = update_drowner;
    // ac_func[Ac.EXITER]    .update = update_exiter;
    // ac_func[Ac.WALKER]    .update = update_walker;
    // ac_func[Ac.RUNNER]    .update = update_runner;
    // ac_func[Ac.CLIMBER]   .update = update_climber;
    // ac_func[Ac.ASCENDER]  .update = update_ascender;
    // ac_func[Ac.FLOATER]   .update = update_floater;
    // ac_func[Ac.EXPLODER]  .update = update_exploder;
    // ac_func[Ac.BLOCKER]   .update = update_blocker;
    // ac_func[Ac.BUILDER]   .update = update_builder;
    // ac_func[Ac.SHRUGGER]  .update = update_shrugger;
    // ac_func[Ac.PLATFORMER].update = update_platformer;
    // ac_func[Ac.SHRUGGER2] .update = update_shrugger2;
    // ac_func[Ac.BASHER]    .update = update_basher;
    // ac_func[Ac.MINER]     .update = update_miner;
    // ac_func[Ac.DIGGER]    .update = update_digger;
    // ac_func[Ac.JUMPER]    .update = update_jumper;
    // ac_func[Ac.BATTER]    .update = update_batter;
    // ac_func[Ac.CUBER]     .update = update_cuber;

    ac_func[Ac.FALLER]    .pass_top =
    ac_func[Ac.TUMBLER]   .pass_top =
    ac_func[Ac.FLOATER]   .pass_top = true;

    ac_func[Ac.CLIMBER]   .blockable =
    ac_func[Ac.ASCENDER]  .blockable =
    ac_func[Ac.BLOCKER]   .blockable =
    ac_func[Ac.EXPLODER]  .blockable =
    ac_func[Ac.BATTER]    .blockable =
    ac_func[Ac.CUBER]     .blockable = false;

    ac_func[Ac.NOTHING]   .leaving =
    ac_func[Ac.SPLATTER]  .leaving =
    ac_func[Ac.BURNER]    .leaving =
    ac_func[Ac.DROWNER]   .leaving =
    ac_func[Ac.EXITER]    .leaving =
    ac_func[Ac.EXPLODER]  .leaving =
    ac_func[Ac.CUBER]     .leaving = true;

    ac_func[Ac.SPLATTER]  .soundBecome = Sound.SPLAT;
    ac_func[Ac.BURNER]    .soundBecome = Sound.FIRE;
    ac_func[Ac.DROWNER]   .soundBecome = Sound.WATER;
}
