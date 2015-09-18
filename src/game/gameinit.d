module game.gameinit;

import std.conv;

import basics.alleg5;
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
    assert (game !is null);
    assert (lv !is null);
    assert (lv.good);

    scope (exit)
        game.altick_last_update = al_get_timer_count(basics.alleg5.timer);

    // prepare the land, without players or gadgets yet
    with (game) {
        level          = lv;
        level_filename = fn;
        replay         = rp;

        effect = new EffectManager;
        pan    = new Panel;
        gui.add_elder(pan);

        cs = new GameState();
        cs.land   = new Torbit(lv.size_x, lv.size_y, lv.torus_x, lv.torus_y);
        cs.lookup = new Lookup(lv.size_x, lv.size_y, lv.torus_x, lv.torus_y);
        lv.draw_terrain_to(cs.land, cs.lookup);

        map = new Map(cs.land, Geom.screen_xls.to!int, Geom.screen_yls.to!int
            * (Geom.panel_yl_divisor - 1) / Geom.panel_yl_divisor);
    }

    //prepare_players(game);
    prepare_gadgets(game);
}



package void
impl_game_destructor(Game game)
{
    if (game.pan)
        gui.rm_elder(game.pan);
}



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
