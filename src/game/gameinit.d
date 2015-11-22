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
import lix.lixxie; // setStaticMaps

package void
implGameConstructor(Game game, Level lv, Filename fn, Replay rp)
{
    assert (game);
    assert (lv);
    assert (lv.good);

    scope (exit)
        game.altickLastUpdate = al_get_timer_count(basics.alleg5.timer);

    game.level         = lv;
    game.levelFilename = fn;
    game.replay        = rp;

    if (rp is null) {
        game.replay = new Replay();
        game.replay.levelFilename = fn;
    }

    game.stateManager = new StateManager();

    prepareLand   (game);
    preparePlayers(game);
    prepareGadgets(game);

    game.stateManager.saveZero(game.cs);
}



package void
implGameDestructor(Game game)
{
    if (game.pan)
        gui.rmElder(game.pan);
    if (game.replay)
        game.replay.saveAsAutoReplay(game.level, game.singlePlayerHasWon);
}



// ############################################################################
// ############################################################################
// ############################################################################



private void
prepareLand(Game game) { with (game)
{
    assert (pan is null);
    pan = new Panel;
    gui.addElder(pan);

    cs = new GameState();
    with (level) {
        cs.land   = new Torbit(sizeX, sizeY, torusX, torusY);
        cs.lookup = new Lookup(sizeX, sizeY, torusX, torusY);
        drawTerrainTo(cs.land, cs.lookup);
    }

    map = new Map(cs.land, Geom.screenXls.to!int,
                          (Geom.screenYls - Geom.panelYls).to!int);

    Lixxie.setStaticMaps(&cs.land, &cs.lookup, map);
}}



// ############################################################################
// ############################################################################
// ############################################################################



private void
preparePlayers(Game game) { with (game)
{
    assert (cs);
    assert (cs.tribes == null);
    assert (effect is null);

    effect = new EffectManager;

    // Make one singleplayer tribe. DTODONETWORK: Query the network to make
    // the correct number of tribes, with the correct masters in each.
    cs.tribes ~= new Tribe();
    cs.tribes[0].masters ~= Tribe.Master(0, basics.globconf.userName);
    _indexTribeLocal  = 0;
    _indexMasterLocal = 0;
    effect.tribeLocal = 0;

    foreach (tr; cs.tribes) {
        tr.initial      = level.initial;
        tr.required     = level.required;
        tr.lixHatch     = level.initial;
        tr.spawnintSlow = level.spawnintSlow;
        tr.spawnintFast = level.spawnintFast;
        tr.spawnint     = level.spawnintSlow;
        tr.skills       = level.skills;
    }

    assert (replay);
    foreach (tr; cs.tribes)
        foreach (ma; tr.masters)
            // DTODONETWORK: Findout what numbers to put in here. ma.number?
            replay.addPlayer(ma.number, tr.style, ma.name);

    assert (pan);
    pan.setLikeTribe(tribeLocal);
    pan.highlightFirstSkill();
}}



// ############################################################################
// ############################################################################
// ############################################################################



private void
prepareGadgets(Game game)
{
    assert (game.map);
    void gadgetsFromPos(T)(ref T[] gadgetVec, TileType tileType)
    {
        foreach (ref pos; game.level.pos[tileType]) {
            gadgetVec ~= cast (T) Gadget.factory(game.map, pos);
            assert (gadgetVec[$-1], pos.toIoLine.toString);
        }
    }

    gadgetsFromPos(game.cs.hatches,     TileType.HATCH);
    gadgetsFromPos(game.cs.goals,       TileType.GOAL);
    gadgetsFromPos(game.cs.decos,       TileType.DECO);
    gadgetsFromPos(game.cs.traps,       TileType.TRAP);
    gadgetsFromPos(game.cs.waters,      TileType.WATER);
    gadgetsFromPos(game.cs.flingers,    TileType.FLING);
    gadgetsFromPos(game.cs.trampolines, TileType.TRAMPOLINE);

}
// end function prepare gadgets()
