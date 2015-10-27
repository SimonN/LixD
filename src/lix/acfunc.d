module lix.acfunc;

import game.state;
import lix;
import hardware.sound;

AcFunc[Ac.MAX] acFunc;

// static this() -- fills acFunc with the necessary data, see below

struct UpdateArgs {
    GameState st;
    int       id; // the lix's id, to pass to the effect manager

    this(GameState _st, in int _id = 0) { st = _st; id = _id; }

    // a function to counter compiler warnings in lixxie-updating functions
    // that take an UpdateArgs argument, but don't need it
    void suppress_unused_variable_warning() const { }
}



struct AcFunc {
    bool  passTop;
    bool  leaving;
    bool  blockable;

    Sound soundAssign;
    Sound soundBecome;

    void function(Lixxie) assclk;
    void function(Lixxie) become;
    void function(Lixxie, in UpdateArgs) update;
}



union SkillFields {
    mixin FallerFields;
}



static this()
{
    foreach (ref acf; acFunc) {
        acf.blockable = true;
        acf.soundAssign = Sound.ASSIGN;
    }

    // DTODO: Uncomment these as they get implemented, or assign them
    // to acFunc straight from the modules implementing them

    // acFunc[Ac.WALKER]    .assclk = assclk_walker;
    // acFunc[Ac.RUNNER]    .assclk = assclk_runner;
    // acFunc[Ac.CLIMBER]   .assclk = assclk_climber;
    // acFunc[Ac.FLOATER]   .assclk = assclk_floater;
    // acFunc[Ac.EXPLODER]  .assclk = assclk_exploder;
    // acFunc[Ac.EXPLODER2] .assclk = assclk_exploder2;
    // acFunc[Ac.BUILDER]   .assclk = assclk_builder;
    // acFunc[Ac.PLATFORMER].assclk = assclk_platformer;

    // acFunc[Ac.FALLER]    .become = become_faller;
    // acFunc[Ac.TUMBLER]   .become = become_tumbler;
    // acFunc[Ac.DROWNER]   .become = become_drowner;
    // acFunc[Ac.EXITER]    .become = become_exiter;
    // acFunc[Ac.WALKER]    .become = become_walker;
    // acFunc[Ac.CLIMBER]   .become = become_climber;
    // acFunc[Ac.ASCENDER]  .become = become_ascender;
    // acFunc[Ac.BUILDER]   .become = become_builder;
    // acFunc[Ac.CUBER]     .become = become_cuber;
    // acFunc[Ac.PLATFORMER].become = become_platformer;
    // acFunc[Ac.DIGGER]    .become = become_digger;
    // acFunc[Ac.JUMPER]    .become = become_jumper;

    // acFunc[Ac.FALLER]    .update = update_faller;
    // acFunc[Ac.TUMBLER]   .update = update_tumbler;
    // acFunc[Ac.STUNNER]   .update = update_stunner;
    // acFunc[Ac.LANDER]    .update = update_lander;
    // acFunc[Ac.SPLATTER]  .update = update_splatter;
    // acFunc[Ac.BURNER]    .update = update_burner;
    // acFunc[Ac.DROWNER]   .update = update_drowner;
    // acFunc[Ac.EXITER]    .update = update_exiter;
    // acFunc[Ac.WALKER]    .update = update_walker;
    // acFunc[Ac.RUNNER]    .update = update_runner;
    // acFunc[Ac.CLIMBER]   .update = update_climber;
    // acFunc[Ac.ASCENDER]  .update = update_ascender;
    // acFunc[Ac.FLOATER]   .update = update_floater;
    // acFunc[Ac.EXPLODER]  .update = update_exploder;
    // acFunc[Ac.BLOCKER]   .update = update_blocker;
    // acFunc[Ac.BUILDER]   .update = update_builder;
    // acFunc[Ac.SHRUGGER]  .update = update_shrugger;
    // acFunc[Ac.PLATFORMER].update = update_platformer;
    // acFunc[Ac.SHRUGGER2] .update = update_shrugger2;
    // acFunc[Ac.BASHER]    .update = update_basher;
    // acFunc[Ac.MINER]     .update = update_miner;
    // acFunc[Ac.DIGGER]    .update = update_digger;
    // acFunc[Ac.JUMPER]    .update = update_jumper;
    // acFunc[Ac.BATTER]    .update = update_batter;
    // acFunc[Ac.CUBER]     .update = update_cuber;

    acFunc[Ac.FALLER]    .passTop =
    acFunc[Ac.TUMBLER]   .passTop =
    acFunc[Ac.FLOATER]   .passTop = true;

    acFunc[Ac.CLIMBER]   .blockable =
    acFunc[Ac.ASCENDER]  .blockable =
    acFunc[Ac.BLOCKER]   .blockable =
    acFunc[Ac.EXPLODER]  .blockable =
    acFunc[Ac.BATTER]    .blockable =
    acFunc[Ac.CUBER]     .blockable = false;

    acFunc[Ac.NOTHING]   .leaving =
    acFunc[Ac.SPLATTER]  .leaving =
    acFunc[Ac.BURNER]    .leaving =
    acFunc[Ac.DROWNER]   .leaving =
    acFunc[Ac.EXITER]    .leaving =
    acFunc[Ac.EXPLODER]  .leaving =
    acFunc[Ac.CUBER]     .leaving = true;

    acFunc[Ac.SPLATTER]  .soundBecome = Sound.SPLAT;
    acFunc[Ac.BURNER]    .soundBecome = Sound.FIRE;
    acFunc[Ac.DROWNER]   .soundBecome = Sound.WATER;
}
