module game.core.init;

import std.conv;

import basics.alleg5;
import basics.globconf;
import file.filename;
import level.level;
import game.core;
import graphic.map;
import graphic.gadget;
import graphic.torbit;
import gui;
import level.tile;

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

    game.prepareLand();
    game.preparePlayers();
    game.prepareGadgets();
    game.assignTribesToGoals();

    game.cs.foreachGadget((in Gadget g) {
        g.drawLookup(game.cs.lookup);
    });

    game.stateManager.saveZero(game.cs);
}



package void
implGameDestructor(Game game)
{
    if (game.pan)
        gui.rmElder(game.pan);
    if (game.modalWindow)
        gui.rmFocus(game.modalWindow);
    if (game.replay)
        game.replay.saveAsAutoReplay(game.level, game.singlePlayerHasWon);
    if (game.physicsDrawer)
        // DTODO: find out whether we can call destroy here, or should merely
        // zero the Albit/Torbit references in physicsDrawer
        destroy(game.physicsDrawer);
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
        cs.lookup = new Phymap(sizeX, sizeY, torusX, torusY);
        drawTerrainTo(cs.land, cs.lookup);
    }

    physicsDrawer = new PhysicsDrawer(cs.land, cs.lookup);

    map = new Map(cs.land, Geom.screenXls.to!int,
                          (Geom.screenYls - Geom.panelYls).to!int);
}}



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
        tr.lixInitial   = level.initial;
        tr.lixRequired  = level.required;
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



private void
prepareGadgets(Game game)
{
    assert (game.map);
    assert (game.cs.lookup);
    void gadgetsFromPos(T)(ref T[] gadgetVec, TileType tileType)
    {
        foreach (ref pos; game.level.pos[tileType]) {
            gadgetVec ~= cast (T) Gadget.factory(game.map, pos);
            assert (gadgetVec[$-1], pos.toIoLine.toString);
            // don't draw to the lookup map yet, we may remove some goals first
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



private void assignTribesToGoals(Game game) {
    with (game.cs)
{
    assert (goals.len,  "can't assign 0 goals to the players");
    assert (tribes.len, "can't assign the goals to 0 players");
    while (goals.len % tribes.len != 0
        && tribes.len % goals.len != 0
    )
        goals = goals[0 .. $-1];

    assert (goals.len);
    assert (tribes.len);
    if (goals.len >= tribes.len)
        foreach (int i, goal; goals)
            goal.addTribe(i % tribes.len);
    else
        foreach (int i, tribe; tribes)
            goals[i % goals.len].addTribe(i);
}}
