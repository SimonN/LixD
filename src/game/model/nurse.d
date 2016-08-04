module game.model.nurse;

/* Has a model, and feeds replay data to the model, to make the model grow
 * and get strong. She kindergardens a few other states via the state manager.
 * These other states occasionally get put into the current model's guts.
 *
 * The nurse does not handle input, or undispatched replay data.
 * The nurse is part of the physics model, not the controlling.
 */

import std.algorithm;

import basics.nettypes; // update
import basics.user; // Result
import file.date;
import game.effect;
import game.replay;
import game.model.model;
import game.model.state;
import game.tribe;
import hardware.tharsis;
import level.level;

class Nurse {
private:
    Replay _replay;
    GameModel _model;
    StateManager _states;
    const(Date) _levelBuilt; // to write it into to results generated later

public:
    @property const(Replay) replay() const { return _replay; }
    @property Update        upd()    const { return _model.cs.update; }
    @property               land()   const { return _model.cs.land;   }

    // this is bad, DTODO: refactor
    @property constStateForDrawingOnly()  const { return _model.cs; }
    @property stateOnlyPrivatelyForGame() const { return _model.cs; }

    this(in Level lev, Replay rp, EffectManager ef)
    {
        _replay = rp;
        _model  = new GameModel(lev, ef);
        _states = new StateManager();
        _levelBuilt = lev.built;
        assert (_replay);
        _states.saveZero(_model.cs);
    }

    ~this() { dispose(); }
    void dispose()
    {
        if (_model)
            _model.dispose();
        _model = null;
    }

    bool stillPlaying() const
    {
        assert (_model);
        return _model.cs.tribes.any!(a => a.stillPlaying)
            || _model.cs.traps .any!(a => a.isEating(upd));
    }

    Update updatesSinceZero() const
    out (result) { assert (result >= 0); }
    body {
        assert (_states.zeroState);
        assert (_model.cs);
        return Update(_model.cs.update - _states.zeroState.update);
    }

    void restartLevel()
    {
        _model.takeOwnershipOf(_states.zeroState.clone());
        _replay.eraseEarlySingleplayerNukes();
    }

    bool userStateExists() { return _states.userState !is null;    }
    void saveUserState()   { _states.saveUser(_model.cs, _replay); }

    bool loadUserStateDoesItMismatch()
    {
        assert (userStateExists);
        _model.takeOwnershipOf(_states.userState.clone());
        auto diff = _replay.firstDifference(_states.userReplay);
        if (! diff.rhsIsSubsetOfThis)
            _replay = _states.userReplay.clone();
        if (! diff.thisIsSubsetOfRhs && ! diff.rhsIsSubsetOfThis) {
            // Forgetting all autosaves on mismatching timelines fixes #130:
            // https://github.com/SimonN/LixD/issues/130
            _states.forgetAutoSavesOnAndAfter(
                diff.firstDifferenceIfNeitherWasSubset);
            return true;
        }
        return false;
    }

    void addReplayData(in ref ReplayData data)
    {
        assert (_replay);
        _replay.add(data);
    }

    void cutReplay()
    {
        _replay.deleteAfterUpdate(upd);
    }

    alias updateToDuringTurbo = updateToTpl!true;
    alias updateTo            = updateToTpl!false;

    void framestepBackBy(int backBy)
    {
        immutable whatUpdateToLoad = Update(_model.cs.update - backBy);
        auto state = (whatUpdateToLoad <= 0)
                   ? _states.zeroState
                   : _states.autoBeforeUpdate(Update(whatUpdateToLoad + 1));
        assert (_states.zeroState, "zero state is bad");
        _model.takeOwnershipOf(state.clone());
        updateTo(whatUpdateToLoad);
    }

    void applyChangesToLand()
    {
        _model.applyChangesToLand();
    }

    // again, only noninteractive mode should call this
    Result evaluateReplay()
    {
        assert (_model);
        assert (_replay);
        while (_model.cs.tribes.any!(tr => tr.stillPlaying)
                // allow 5 minutes after the last replay data before cancelling
                && upd < _replay.latestUpdate + 5 * (60 * 15))
            updateOnce();
        // DTODONETWORKING: Should query the replay about tribe-local index.
        // It's well possible to check networking replays, even if that won't
        // give informative results in the replay checker. Don't assert here.
        assert (_model.cs.tribes.length == 1);
        return resultOf(_model.cs.tribes[0]);
    }

    Result resultForTribe(in int arrIndex) const
    {
        assert (arrIndex >= 0 && arrIndex < _model.cs.tribes.length);
        return resultOf(_model.cs.tribes[arrIndex]);
    }

private:
    void applyReplayDataToModel()
    {
        assert (_replay);
        auto dataSlice = _replay.getDataForUpdate(upd);
        assert (dataSlice.isSorted!("a.player < b.player"));
        foreach (data; dataSlice)
            _model.applyReplayData(data, _replay.plNrToStyle(data.player));
    }

    void updateOnce()
    {
        version (tharsisprofiling)
            Zone zone = Zone(profiler, "PhysSeq updateOnceNoSync");
        _model.incrementUpdate;
        applyReplayDataToModel();
        assert (_replay);
        _model.advance(_replay.permu);
    }

    // DTODO: Refactor into SaveStatingNurse : Nurse for the interactive
    // mode, and the regular nurse otherwise
    void updateToTpl(bool duringTurbo)(in Update targetUpdate)
    {
        // assert (game.runmode == Runmode.INTERACTIVE);
        if (_model.cs.update >= targetUpdate)
            return;
        while (_model.cs.update < targetUpdate) {
            updateOnce();
            considerAutoSavestateIfCloseTo!duringTurbo(targetUpdate);
        }
    }

    void considerAutoSavestateIfCloseTo(bool duringTurbo)(Update target)
    {
        assert (_states);
        static if (duringTurbo)
            bool saveNow = _states.wouldAutoSaveDuringTurbo(_model.cs, target);
        else
            bool saveNow = _states.wouldAutoSave(_model.cs, target);
        if (saveNow) {
            version (tharsisprofiling)
                Zone zone = Zone(profiler, "Nurse makes auto-savestate");
            // It seems dubious to do drawing to bitmaps during calc/update.
            // However, savestates save the land too, and they should
            // hold the correctly updated land. We could save an instance
            // of a PhysicsDrawer along inside the savestate, but then we would
            // redraw over and over when loading from this state during
            // framestepping backwards. Instead, let's calculate the land now.
            _model.applyChangesToLand();
            _states.autoSave(_model.cs, target);
        }
    }

    Result resultOf(in Tribe tr) const
    {
        auto result = new Result(_levelBuilt);
        result.lixSaved    = tr.lixSaved;
        result.skillsUsed  = tr.skillsUsed;
        result.updatesUsed = tr.updatePreviousSave;
        return result;
    }
}
