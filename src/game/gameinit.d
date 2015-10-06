module game.gameinit;

import std.conv;

import basics.alleg5;
import basics.globconf;
import file.filename;
import level.level;
import game;
import graphic.map;
import graphic.gadget;
import graphic.torbit;
import gui;
import level.tile;

package void
impl_game_constructor(Game game, Level lv, Filename fn, Replay rp)
{
    assert (game);
    assert (lv);
    assert (lv.good);

    scope (exit)
        game.altick_last_update = al_get_timer_count(basics.alleg5.timer);

    game.level          = lv;
    game.level_filename = fn;
    game.replay         = rp;

    prepare_land   (game);
    prepare_players(game);
    prepare_gadgets(game);
}



package void
impl_game_destructor(Game game)
{
    if (game.pan)
        gui.rm_elder(game.pan);
}



// ############################################################################
// ############################################################################
// ############################################################################



private void
prepare_land(Game game) { with (game)
{
    assert (effect is null);
    assert (pan    is null);

    effect = new EffectManager;
    pan    = new Panel;
    gui.add_elder(pan);

    cs = new GameState();
    with (level) {
        cs.land   = new Torbit(size_x, size_y, torus_x, torus_y);
        cs.lookup = new Lookup(size_x, size_y, torus_x, torus_y);
        draw_terrain_to(cs.land, cs.lookup);
    }

    map = new Map(cs.land, Geom.screen_xls.to!int, Geom.screen_yls.to!int
        * (Geom.panel_yl_divisor - 1) / Geom.panel_yl_divisor);
}}



// ############################################################################
// ############################################################################
// ############################################################################



private void
prepare_players(Game game) { with (game)
{
    assert (cs.tribes == null);

    // Make one singleplayer tribe. DTODONETWORK: Query the network to make
    // the correct number of tribes, with the correct masters in each.
    cs.tribes ~= new Tribe();
    cs.tribes[0].masters ~= Tribe.Master(0, basics.globconf.user_name);
    trlo = cs.tribes[0];
    malo = trlo.masters[0];

    foreach (tr; cs.tribes) {
        tr.initial       = level.initial;
        tr.required      = level.required;
        tr.lix_hatch     = level.initial;
        tr.spawnint_slow = level.spawnint_slow;
        tr.spawnint_fast = level.spawnint_fast;
        tr.spawnint      = level.spawnint_slow;
        tr.skills        = level.skills;
    }

    assert (pan);
    pan.set_like_tribe(trlo);
}}



// ############################################################################
// ############################################################################
// ############################################################################



private void
prepare_gadgets(Game game)
{
    void gadgets_from_pos(T)(ref T[] gadget_vec, TileType tile_type)
    {
        foreach (ref pos; game.level.pos[tile_type]) {
            gadget_vec ~= cast (T) Gadget.factory(game.map, pos);
            assert (gadget_vec[$-1]);
        }
    }

    gadgets_from_pos(game.cs.hatches,     TileType.HATCH);
    gadgets_from_pos(game.cs.goals,       TileType.GOAL);
    gadgets_from_pos(game.cs.decos,       TileType.DECO);
    gadgets_from_pos(game.cs.traps,       TileType.TRAP);
    gadgets_from_pos(game.cs.waters,      TileType.WATER);
    gadgets_from_pos(game.cs.flingers,    TileType.FLING);
    gadgets_from_pos(game.cs.trampolines, TileType.TRAMPOLINE);

}
// end function prepare gadgets()
