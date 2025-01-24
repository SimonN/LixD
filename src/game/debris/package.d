module game.debris;

/*
 * Struct hierarchy.
 * Debris is the public struct that can be any debris.
 * DebrisBase is the private struct that all other private Debris structs
 * will C-style-inherit.
 *
 * Debris can be an arrow to show assignments during replays/network games,
 * but it can also be a flying tool, an explosion, or explosion particles.
 * Sound is not handled via debris.
 *
 * The EffectManager remembers, by a list of Effect, whether new Debris has to
 * be produced for past events, or not. Debris is supervised by EffectManager,
 * too, and means the actual flying pieces.
 *
 * x, y, speed are measured in map coordinates, not screen coordinates.
 * Stuff moves 2x as fast over the screen if map zoom is 2x.
 */

public import game.debris.base;
public import game.debris.derived;
public import game.debris.union_;
public import game.debris.derived :
    Arrow,
    ExplosionCenter,
    ImplosionCenter,
    ImplosionParticle,
    FlyingTool
    ;
