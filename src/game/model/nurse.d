module game.model.nurse;

/* Has a model, and feeds replay data to the model, to make the model grow
 * and get strong. She kindergardens a few other states via the state manager.
 * These other states occasionally get put into the current model's guts.
 *
 * The nurse does not handle input, or undispatched replay data.
 * The nurse is part of the physics model, not the controlling.
 */

import std.algorithm;

import net.repdata; // update
import basics.user; // Result
import file.date;
import game.effect;
import game.replay;
import game.model.cache;
import game.model.model;
import game.model.state;
import game.tribe;
import hardware.tharsis;
import level.level;

class Nurse {
private:
    Replay _replay;
    GameModel _model;
    PhysicsCache _cache;
    const(Date) _levelBuilt; // to write it into to results generated later

public:
    @property const(Replay) replay() const { return _replay; }
    @property Phyu upd() const { return _model.cs.update; }

    // this is bad, DTODO: refactor
    @property constStateForDrawingOnly()  const { return _model.cs; }
    @property stateOnlyPrivatelyForGame() const { return _model.cs; }

    // We get to own the replay, but not the level or the effect manager.
    // EffectManager may be null.
    this(in Level lev, Replay rp, EffectManager ef)
    {
        _replay = rp;
        _model = new GameModel(lev, rp.stylesInUse, rp.permu, ef);
        _cache = new PhysicsCache();
        _levelBuilt = lev.built;
        assert (_replay);
        _cache.saveZero(_model.cs);
    }

    void dispose()
    {
        if (_cache) {
            _cache.dispose();
            _cache = null;
        }
        if (_model) {
            _model.dispose();
            _model = null;
        }
    }

    @property bool stillPlaying() const
    {
        assert (_model);
        return _model.cs.tribes.byValue.any!(a => a.stillPlaying)
            || _model.cs.traps         .any!(a => a.isEating(upd));
    }

    @property bool singleplayerHasSavedAtLeast(in int lixRequired) const
    {
        assert (_model);
        return _model.cs.singleplayerHasSavedAtLeast(lixRequired);
    }

    final @property auto scores() const
    {
        assert (_model);
        return _model.cs.tribes.byValue.map!(tr => tr.score);
    }

    Phyu updatesSinceZero() const
    out (result) {
        assert (result >= 0);
    }
    body {
        return Phyu(_model.cs.update - _cache.zeroStatePhyu);
    }

    bool userStateExists() { return _cache.userStateExists; }
    void saveUserState()   { _cache.saveUser(_model.cs, _replay); }

    // This doesn't do any cache invalidation any more, but calls a function
    // of PhysicsCache that takes care of cache invalidation.
    bool loadUserStateDoesItMismatch()
    {
        assert (_model);
        auto loaded = _cache.loadUser(_replay);
        _model.takeOwnershipOf(loaded.state.clone);
        if (! loaded.loadedVsNurseReplay.thisBeginsWithRhs)
            _replay = loaded.replay.clone();
        return loaded.loadedVsNurseReplay.mismatch;
    }

    void addReplayDataMaybeGoBack(const(ReplayData[]) vec)
    {
        if (vec.length == 0)
            return;
        assert (_replay);
        vec.each!(data => _replay.add(data));
        framestepBackTo(Phyu(vec.map!(data => data.update).reduce!min - 1));
    }

    void cutReplay()
    {
        _replay.deleteAfterPhyu(upd);
    }

    // DTODO: Refactor into SaveStatingNurse : Nurse for the interactive
    // mode, and the regular nurse otherwise
    void updateTo(in Phyu targetPhyu, in DuringTurbo duringTurbo)
    {
        // assert (game.runmode == Runmode.INTERACTIVE);
        while (stillPlaying && _model.cs.update < targetPhyu) {
            updateOnce();
            considerAutoSavestateIfCloseTo(targetPhyu, duringTurbo);
        }
    }

    void restartLevel()
    {
        _replay.eraseEarlySingleplayerNukes();
        _model.takeOwnershipOf(_cache.loadBeforePhyu(
                               _cache.zeroStatePhyu).clone);
    }

    void framestepBackBy(int backBy)
    {
        framestepBackTo(Phyu(_model.cs.update - backBy));
    }

    void applyChangesToLand()
    {
        _model.applyChangesToLand();
    }

    // again, only noninteractive mode should call this
    Result evaluateReplayUntilSingleplayerHasSavedAtLeast(in int lixRequired)
    {
        assert (_model);
        assert (_replay);
        while (! _model.cs.singleplayerHasSavedAtLeast(lixRequired)
                && _model.cs.tribes.byValue.any!(tr => tr.stillPlaying)
                // allow 5 minutes after the last replay data before cancelling
                && upd < _replay.latestPhyu + 5 * (60 * 15))
            updateOnce();
        return resultForTribe(_replay.playerLocalOrSmallest.style);
    }

    Result resultForTribe(in Style style) const
    {
        assert (style in _model.cs.tribes);
        return resultOf(_model.cs.tribes[style]);
    }

private:
    void framestepBackTo(immutable Phyu u)
    {
        if (u >= _model.cs.update)
            return;
        _model.takeOwnershipOf(_cache.loadBeforePhyu(Phyu(u + 1)).clone);
        updateTo(u, DuringTurbo.no);
    }

    void updateOnce()
    {
        version (tharsisprofiling)
            Zone zone = Zone(profiler, "PhysSeq updateOnceNoSync");
        _model.incrementPhyu();
        {
            auto dataSlice = _replay.getDataForPhyu(upd);
            assert (dataSlice.isSorted!("a.player < b.player"));
            foreach (data; dataSlice)
                _model.applyReplayData(data, _replay.plNrToStyle(data.player));
        }
        _model.advance();
    }

    void considerAutoSavestateIfCloseTo(in Phyu target, in DuringTurbo turbo)
    {
        assert (_cache);
        if (_cache.wouldAutoSave(_model.cs, target, turbo)) {
            version (tharsisprofiling)
                Zone zone = Zone(profiler, "Nurse makes auto-savestate");
            // It seems dubious to do drawing to bitmaps during calc/update.
            // However, savestates save the land too, and they should
            // hold the correctly updated land. We could save an instance
            // of a PhysicsDrawer along inside the savestate, but then we would
            // redraw over and over when loading from this state during
            // framestepping backwards. Instead, let's calculate the land now.
            _model.applyChangesToLand();
            _cache.autoSave(_model.cs, target);
        }
    }

    Result resultOf(in Tribe tr) const
    {
        auto result = new Result(_levelBuilt);
        result.lixSaved    = tr.lixSaved;
        result.skillsUsed  = tr.skillsUsed;
        result.phyusUsed = tr.updatePreviousSave;
        return result;
    }
}
