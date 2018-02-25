module game.nurse.base;

/* Has a model, and feeds replay data to the model, to make the model grow
 * and get strong. She kindergardens a few other states via the state manager.
 * These other states occasionally get put into the current model's guts.
 *
 * The nurse does not handle input, or undispatched replay data.
 * The nurse is part of the physics model, not the controlling.
 */

import std.algorithm;
import std.range;

import net.repdata; // update
import basics.globconf; // update player name on cut replay
import basics.user; // Result
import file.date;
import game.model.model;
import game.model.state;
import game.tribe;
import hardware.tharsis;

public import level.level;
public import game.replay;
public import game.effect;

abstract class Nurse {
private:
    Replay _replay;
    GameModel _model;
    const(Date) _levelBuilt; // to write it into to results generated later

public:
    @property const(Replay) constReplay() const { return _replay; }
    @property Phyu upd() const { return _model.cs.update; }

    // this is bad, DTODO: refactor
    @property constStateForDrawingOnly()  const { return _model.cs; }
    @property stateOnlyPrivatelyForGame() const { return _model.cs; }
    // end bad
    void drawAllGadgets() { _model.cs.drawAllGadgets(); }

    // We get to own the replay, but not the level or the effect manager.
    // EffectManager may be null.
    this(in Level lev, Replay rp, EffectManager ef)
    {
        _replay = rp;
        _model = new GameModel(lev, rp.stylesInUse, rp.permu, ef);
        _levelBuilt = lev.built;
        assert (_replay);
    }

    void dispose()
    {
        onDispose();
        if (_model) {
            _model.dispose();
            _model = null;
        }
    }

    @property bool everybodyOutOfLix() const
    {
        return cs.tribes.byValue.all!(a => a.outOfLix);
    }

    @property bool doneAnimating() const
    {
        return cs.tribes.byValue.all!(a => a.doneAnimating)
            && cs.traps         .all!(a => ! a.isEating(upd));
    }

    @property bool singleplayerHasSavedAtLeast(in int lixRequired) const
    {
        return cs.singleplayerHasSavedAtLeast(lixRequired);
    }

    final @property auto scores() const
    {
        return cs.tribes.byValue.map!(tr => tr.score);
    }

    auto gadgetsOfTeam(in Style st) const
    {
        return chain(
            cs.goals.filter!(g => g.hasTribe(st)),
            cs.hatches.filter!(h => h.blinkStyle == st));
    }

    Trophy trophyForTribe(in Style style) const
    {
        assert (style in cs.tribes);
        return resultOf(cs.tribes[style]);
    }

    // This should be refactored. The base Nurse is happy to compute trophies,
    // but doesn't like to check whether it's fine to save trophies.
    void saveTrophyIfSingleplayerSavedAtLeast(in int lixRequired)
    {
        if (cs.multiplayer
            || ! _replay.players.byValue.canFind!(pl => pl.name == userName)
            || ! singleplayerHasSavedAtLeast(lixRequired))
            return;
        addTrophy(_replay.levelFilename, trophyForTribe(cs.singleplayerStyle));
    }

protected:
    void onDispose() { }

    @property inout(GameModel) model() inout { return _model; }
    @property inout(Replay) replay() inout { return _replay; }
    @property Replay replay(Replay r) { return _replay = r; }

    @property inout(GameState) cs() inout
    in { assert (_model); }
    body { return _model.cs; }

    void updateOnce()
    {
        version (tharsisprofiling)
            Zone zone = Zone(profiler, "PhysSeq updateOnceNoSync");
        auto dataSlice = _replay.getDataForPhyu(Phyu(upd + 1));
        assert (dataSlice.isSorted!("a.player < b.player"));
        _model.advance(dataSlice.map!(rd =>
            GameModel.ColoredData(rd, _replay.plNrToStyle(rd.player))));
    }

private:
    Trophy resultOf(in Tribe tr) const
    {
        auto result = new Trophy(_levelBuilt);
        result.lixSaved = tr.score.current;
        result.skillsUsed = tr.skillsUsed;
        if (tr.hasScored)
            result.phyusUsed = tr.recentScoring;
        return result;
    }
}
