module game.model.init;

import std.conv;

import basics.alleg5;
import basics.globconf;
import basics.help;
import graphic.gadget;
import graphic.torbit;
import game.core.game;
import game.model.state;
import game.replay;
import game.effect;
import tile.phymap;
import game.tribe;
import level.level;
import tile.gadtile;
import lix;

package:

GameState newZeroState(in Level level)
{
    GameState s = new GameState();
    with (level) {
        s.land   = new Torbit(level.topology);
        s.lookup = new Phymap(level.topology);
        drawTerrainTo(s.land, s.lookup);
    }

    s.preparePlayers(level);
    s.prepareGadgets(level);
    s.assignTribesToGoals();

    s.foreachGadget((Gadget g) {
        g.drawLookup(s.lookup);
    });
    return s;
}

private:

void preparePlayers(GameState state, in Level level)
{
    assert (state);
    assert (state.tribes == null);

    // Make one singleplayer tribe. DTODONETWORK: Query the network to make
    // the correct number of tribes, with the correct masters in each.
    state.tribes ~= new Tribe();
    import basics.nettypes; // PlNr
    state.tribes[0].masters ~= Tribe.Master(PlNr(0), basics.globconf.userName);
    state.update = state.tribes.length == 1 ? 45 : 0; // start quickly in 1-pl
    foreach (tr; state.tribes) {
        tr.lixInitial   = level.initial;
        tr.lixRequired  = level.required;
        tr.lixHatch     = level.initial;
        tr.spawnint     = level.spawnint;
        tr.skills       = level.skills;
        tr.nukeSkill    = level.ploder;
    }
}

void prepareGadgets(GameState state, in Level level)
{
    assert (state.lookup);
    void instantiateGadgetsFromArray(T)(ref T[] gadgetVec, GadType tileType)
    {
        foreach (ref occ; level.gadgets[tileType]) {
            gadgetVec ~= cast (T) Gadget.factory(state.lookup, occ);
            assert (gadgetVec[$-1], occ.toIoLine.toString);
            // don't draw to the lookup map yet, we may remove some goals first
        }
    }
    instantiateGadgetsFromArray(state.hatches,  GadType.HATCH);
    instantiateGadgetsFromArray(state.goals,    GadType.GOAL);
    instantiateGadgetsFromArray(state.decos,    GadType.DECO);
    instantiateGadgetsFromArray(state.traps,    GadType.TRAP);
    instantiateGadgetsFromArray(state.waters,   GadType.WATER);
    instantiateGadgetsFromArray(state.flingers, GadType.FLING);
}

void assignTribesToGoals(GameState state) { with (state)
{
    assert (goals.len,  "can't assign 0 goals to the players");
    assert (tribes.len, "can't assign the goals to 0 players");
    while (goals.len % tribes.len != 0
        && tribes.len % goals.len != 0)
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
