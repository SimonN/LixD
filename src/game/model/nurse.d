module game.model.nurse;

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
    // end bad
    void drawAllGadgets() { _model.cs.drawAllGadgets(); }

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

    @property bool everybodyOutOfLix() const
    {
        assert (_model);
        return _model.cs.tribes.byValue.all!(a => a.outOfLix);
    }

    @property bool doneAnimating() const
    {
        assert (_model);
        return _model.cs.tribes.byValue.all!(a => a.doneAnimating)
            && _model.cs.traps         .all!(a => ! a.isEating(upd));
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
        while (! doneAnimating && _model.cs.update < targetPhyu) {
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

    struct EvalResult {
        Trophy trophy; //
        bool mercyKilled; // replay took too long after last assign before win
    }

    // Again, only noninteractive mode should call this
    EvalResult evaluateReplayUntilSingleplayerHasSavedAtLeast(int lixRequired)
    in {
        assert (_model);
        assert (_replay);
    }
    body {
        EvalResult ret;
        while (! _model.cs.singleplayerHasSavedAtLeast(lixRequired)
            && ! everybodyOutOfLix
        ) {
            updateOnce();
            // allow 5 minutes after the last replay data before cancelling
            if (upd >= _replay.latestPhyu + 5 * (60 * 15)) {
                ret.mercyKilled = true;
                break;
            }
        }
        ret.trophy = trophyForTribe(_replay.playerLocalOrSmallest.style);
        return ret;
    }

    Trophy trophyForTribe(in Style style) const
    {
        assert (style in _model.cs.tribes);
        return resultOf(_model.cs.tribes[style]);
    }

    auto gadgetsOfTeam(in Style st) const
    body {
        assert (_model);
        return _model.cs.goals.filter!(g => g.hasTribe(st)).chain(
               _model.cs.hatches.filter!(h => h.blinkStyle == st));
    }

private:
    void framestepBackTo(immutable Phyu u)
    {
        if (u >= _model.cs.update)
            return;
        _model.takeOwnershipOf(_cache.loadBeforePhyu(Phyu(u + 1)).clone);
        _replay.eraseEarlySingleplayerNukes(); // should bring no bugs
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
