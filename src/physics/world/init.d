module physics.world.init;

import std.algorithm;
import std.array;
import std.conv;

import basics.alleg5;
import basics.globals;
import basics.help; // len
import file.option;
import graphic.gadget;
import graphic.torbit;
import file.replay;
import level.level;
import net.permu;
import physics.world.world;
import physics.tribe;
import physics.handimrg;
import tile.phymap;
import tile.gadtile;

public:

struct GameStateInitCfg {
    Level level;
    MergedHandicap[Style] tribes;
    Permu permu;
}

WorldAsStruct newZeroState(in GameStateInitCfg cfg)
in {
    assert (cfg.tribes.length >= 1);
}
out (ret) {
    assert (ret.isValid, "newZeroState must be valid at least here");
}
do {
    typeof(return) ret;
    ret.land   = new Torbit(Torbit.Cfg(cfg.level.topology));
    ret.lookup = new Phymap(cfg.level.topology);
    cfg.level.drawTerrainTo(ret.land, ret.lookup);

    (&ret).preparePlayers(cfg);
    (&ret).prepareGadgets(cfg.level);
    (&ret).assignTribesToGoals(cfg.permu);
    (&ret).foreachConstGadget((const(Gadget) g) {
        g.drawLookup(ret.lookup);
    });
    ret.age = ret.isBattle ? Phyu(0) : Phyu(45); // start quickly in 1-player

    ret.immutableHalf.overtimeAtStartInPhyus = ret.isBattle
        ? cfg.level.overtimeSeconds * phyusPerSecondAtNormalSpeed : 0;

    return ret;
}

private:

void preparePlayers(World state, in GameStateInitCfg cfg)
in {
    assert (state.tribes.numPlayerTribes == 0);
    assert (cfg.tribes.length >= 1);
}
do {
    const nukeRule = cfg.tribes.length > 1 && cfg.level.overtimeSeconds == 0
        ? Tribe.RuleSet.MustNukeWhen.raceToFirstSave
        : Tribe.RuleSet.MustNukeWhen.normalOvertime;
    foreach (style, mergedHandicap; cfg.tribes) {
        state.tribes.add(Tribe.RuleSet(
            style,
            cfg.level.initial,
            cfg.level.spawnint,
            cfg.level.skills,
            nukeRule,
            mergedHandicap,
        ));
    }
}

void prepareGadgets(World state, in Level level)
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
    instantiateGadgetsFromArray(state.immutableHalf.hatches, GadType.hatch);
    instantiateGadgetsFromArray(state.immutableHalf.goals, GadType.goal);
    instantiateGadgetsFromArray(state.immutableHalf.waters, GadType.water);
    instantiateGadgetsFromArray(state.immutableHalf.waters, GadType.fire);
    instantiateGadgetsFromArray(state.immutableHalf.steams, GadType.steam);

    instantiateGadgetsFromArray(state.munchers, GadType.muncher);
    instantiateGadgetsFromArray(state.catapults, GadType.catapult);
}

void assignTribesToGoals(World state, in Permu permu)
in {
    import std.format;
    assert (state.hatches.len, "we'll do modulo on the hatches, 0 is bad");
    assert (state.tribes.numPlayerTribes, "can't assign goals to 0 players");
    assert (permu.len == state.tribes.numPlayerTribes,
        format!"permu length mismatch: permu len = %d, playable tribes = %d"
            (permu.len, state.tribes.numPlayerTribes));
}
do { with (state)
{
    immutable numTribes = state.tribes.numPlayerTribes;
    while (hatches.len % numTribes != 0 && numTribes % hatches.len != 0)
        state.immutableHalf.hatches = state.immutableHalf.hatches[0 .. $-1];
    assert (hatches.len);
    while (goals.len
        && goals.len % numTribes != 0 && numTribes % goals.len != 0)
        state.immutableHalf.goals = state.immutableHalf.goals[0 .. $-1];

    auto stylesInPlay = tribes.playerTribes.map!(tr => tr.style).array;
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
            state.immutableHalf.hatches[j].addOwner(style);
        if (goals.len == 0)
            continue;
        for (int j = slot % goals.len; j < goals.len; j += numTribes)
            state.immutableHalf.goals[j].addOwner(style);
    }
}}
