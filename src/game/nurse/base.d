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
import file.option; // update player name on cut replay
import file.date;
import file.filename;
import file.trophy;
import hardware.tharsis;
import physics;

public import level.level;
public import file.replay;
public import game.effect;

abstract class Nurse {
private:
    Replay _replay;
    GameModel _model;

public:
    @property const(Replay) constReplay() const { return _replay; }
    @property Phyu upd() const { return _model.cs.update; }

    // this is bad, DTODO: refactor
    @property constStateForDrawingOnly()  const { return _model.cs; }
    @property stateOnlyPrivatelyForGame() const { return _model.cs; }
    // end bad

    // We get to own the replay, but not the level or the effect manager.
    this(in Level lev, Replay rp, EffectSink ef)
    do {
        Style[] stylesToMake = rp.stylesInUse;
        if (stylesToMake.empty)
            stylesToMake = [ Style.garden ];
        _replay = rp;
        _model = new GameModel(lev, stylesToMake, rp.permu, ef);
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

    @property bool singleplayerHasNuked() const
    {
        return cs.singleplayerHasNuked();
    }

    final @property auto scores() const
    {
        return cs.tribes.byValue.map!(tr => tr.score);
    }

    auto gadgetsOfTeam(in Style st) const
    {
        return chain(
            cs.goals.filter!(g => g.hasTribe(st)),
            cs.hatches.filter!(h => h.hasTribe(st)));
    }

    HalfTrophy trophyForTribe(in Style style) const
    {
        assert (style in cs.tribes);
        HalfTrophy ret;
        ret.lixSaved = cs.tribes[style].score.current;
        ret.skillsUsed = cs.tribes[style].skillsUsed;
        return ret;
    }

protected:
    void onDispose() { }

    @property inout(GameModel) model() inout { return _model; }
    @property inout(Replay) replay() inout { return _replay; }
    @property Replay replay(Replay r) { return _replay = r; }

    @property inout(GameState) cs() inout
    in { assert (_model); }
    do { return _model.cs; }

    void updateOnce()
    {
        version (tharsisprofiling)
            Zone zone = Zone(profiler, "PhysSeq updateOnceNoSync");
        auto dataSlice = _replay.plySliceFor(Phyu(upd + 1));
        assert (dataSlice.isSorted!("a.player < b.player"));
        _model.advance(dataSlice.map!(rd =>
            GameModel.ColoredData(rd, _replay.plNrToStyle(rd.player))));
    }
}
