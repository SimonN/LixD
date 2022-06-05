module physics.statinit;

import std.algorithm;
import std.array;
import std.conv;
import std.typecons;

import basics.alleg5;
import basics.globals;
import basics.help; // len
import file.option;
import graphic.gadget;
import graphic.torbit;
import file.replay;
import level.level;
import lix;
import net.permu;
import physics.state;
import physics.tribe;
import tile.phymap;
import tile.gadtile;

package:

GameState newZeroState(in Level level, in Style[] tribesToMake, in Permu permu)
in {
    assert (tribesToMake.len >= 1);
}
do {
    GameState s;
    s.refCountedStore.ensureInitialized();
    with (level) {
        s.land   = new Torbit(Torbit.Cfg(level.topology));
        s.lookup = new Phymap(level.topology);
        drawTerrainTo(s.land, s.lookup);
    }
    s.preparePlayers(level, tribesToMake, permu);
    s.prepareGadgets(level);
    s.assignTribesToGoals(permu);
    s.foreachGadget((Gadget g) {
        g.drawLookup(s.lookup);
    });
    s.update = s.multiplayer ? 0 : 45; // start quickly in 1-player
    s.overtimeAtStartInPhyus = s.multiplayer
        ? level.overtimeSeconds * phyusPerSecondAtNormalSpeed : 0;
    return s;
}

private:

void preparePlayers(GameState state, in Level level,
                    in Style[] tribesToMake, in Permu permu)
in {
    assert (state.tribes == null);
    assert (tribesToMake.len >= 1);
    assert (tribesToMake.isStrictlyMonotonic);
}
do {
    foreach (style; tribesToMake) {
        Tribe tr = new Tribe(
            tribesToMake.len > 1 && level.overtimeSeconds == 0
                ? Tribe.Rule.raceToFirstSave : Tribe.Rule.normalOvertime);
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

void assignTribesToGoals(GameState state, in Permu permu)
in {
    import std.format;
    assert (state.hatches.len, "we'll do modulo on the hatches, 0 is bad");
    assert (state.numTribes, "can't assign the goals to 0 players");
    assert (permu.len == state.numTribes,
        format!"permu length mismatch: permu len = %d, numTribes = %d"
            (permu.len, state.numTribes));
}
out {
    assert (state.hatches.all!(h => ! h.tribes.empty));
}
do { with (state)
{
    while (hatches.len % numTribes != 0 && numTribes % hatches.len != 0)
        hatches = hatches[0 .. $-1];
    assert (hatches.len);
    while (goals.len
        && goals.len % numTribes != 0 && numTribes % goals.len != 0)
        goals = goals[0 .. $-1];

    auto stylesInPlay = tribes.keys;
    stylesInPlay.sort();

    // Permu 0 3 1 2 for 2 goals and tribes red, orange, yellow, purple means:
    // -> Red & purple get goal 0 because their slots are 0 mod 2.
    // -> Orange & yellow get goal 1 because their slots are 1 mod 2.
    // Permu 0 2 1 for 6 goals and tribes red, orange, yellow means:
    // -> Red gets goal 0 & 3. Orange gets 2 & 5. Yellow gets 1 & 4.
    foreach (size_t i, style; stylesInPlay) {
        immutable int slot = permu[i.to!int];
        tribes[style].nextHatch = slot % hatches.len;
        for (int j = slot % hatches.len; j < hatches.len; j += numTribes)
            hatches[j].addTribe(style);
        if (goals.len == 0)
            continue;
        for (int j = slot % goals.len; j < goals.len; j += numTribes)
            goals[j].addTribe(style);
    }
}}
