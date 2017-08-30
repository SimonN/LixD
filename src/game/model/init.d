module game.model.init;

import std.algorithm;
import std.array;
import std.conv;
import std.typecons;

import basics.alleg5;
import basics.help; // len
import basics.globconf;
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
import net.permu;

package:

GameState newZeroState(in Level level, in Style[] tribesToMake,
                       in Permu permu, in Style makeHatchesBlink
) {
    GameState s;
    s.refCountedStore.ensureInitialized();
    with (level) {
        s.land   = new Torbit(Torbit.Cfg(level.topology));
        s.lookup = new Phymap(level.topology);
        drawTerrainTo(s.land, s.lookup);
    }
    s.preparePlayers(level, tribesToMake, permu);
    s.prepareGadgets(level);
    s.assignTribesToGoals(tribesToMake, permu, makeHatchesBlink);
    s.foreachGadget((Gadget g) {
        g.drawLookup(s.lookup);
    });
    s.update = s.multiplayer ? 0 : 45; // start quickly in 1-player
    s.overtimeAtStartInPhyus =
        s.multiplayer ? level.overtimeSeconds * Game.phyusPerSecond : 0;
    return s;
}

private:

void preparePlayers(GameState state, in Level level,
                    in Style[] tribesToMake, in Permu permu)
{
    assert (state.tribes == null);
    assert (tribesToMake.len >= 1);
    assert (tribesToMake.isStrictlyMonotonic);
    foreach (int i, style; tribesToMake) {
        Tribe tr = new Tribe();
        tr.style        = style;
        tr.lixHatch     = level.initial;
        tr.spawnint     = level.spawnint;
        tr.skills       = level.skills;
        state.tribes[style] = tr;
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
    instantiateGadgetsFromArray(state.traps,    GadType.TRAP);
    instantiateGadgetsFromArray(state.waters,   GadType.WATER);
    instantiateGadgetsFromArray(state.flingPerms, GadType.FLINGPERM);
    instantiateGadgetsFromArray(state.flingTrigs, GadType.FLINGTRIG);
}

void assignTribesToGoals(GameState state,
    in Style[] stylesInPlay, in Permu permu, in Style makeHatchesBlink
) { with (state)
{
    assert (hatches.len, "we'll do modulo on the hatches, 0 is bad");
    assert (goals.len, "can't assign 0 goals to the players");
    assert (numTribes, "can't assign the goals to 0 players");
    while (hatches.len % numTribes != 0 && numTribes % hatches.len != 0)
        hatches = hatches[0 .. $-1];
    while (goals.len % numTribes != 0 && numTribes % goals.len != 0)
        goals = goals[0 .. $-1];
    assert (hatches.len);
    assert (goals.len);

    // Hatches: Distribute to players, make certain hatches blink
    foreach (int i, style; stylesInPlay) {
        immutable ha = permu[i] % hatches.len;
        tribes[style].nextHatch = ha;
        if (style == makeHatchesBlink)
            for (int j = ha; j < hatches.len; j += numTribes)
                hatches[j].blinkStyle = makeHatchesBlink;
    }
    // Goals: Distribute to players
    foreach (int i, style; stylesInPlay) {
        // Permu 0 3 1 2 for tribes red, orange, yellow, green means:
        // Red & green get goal 0. -- Orange & yellow get goal 1.
        // Permu 0 2 1 for tribes red, orange, yellow means:
        // Red gets goal 0 & 3. Orange gets 2 & 5. Yellow gets 1 & 4.
        for (int j = permu[i] % goals.len; j < goals.len; j += numTribes)
            goals[j].addTribe(style);
    }
}}
