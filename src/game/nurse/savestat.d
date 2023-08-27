module game.nurse.savestat;

import std.algorithm;

import file.option; // replayAfterFrameBack
import game.nurse.cache;
import hardware.tharsis;
import physics.state;

public import game.nurse.base;

class SaveStatingNurse : Nurse {
private:
    PhysicsCache _cache;

public:
    /*
     * Forwarding constructor. We get to own the replay, but not the level
     * or the effect manager. Need to forward
     * this constructor between the Nurse backend and the InteractiveNurse.
     * This necessity feels strange.
     */
    this(in Level lev, Replay rp, EffectSink ef)
    {
        super(lev, rp, ef);
        _cache = new PhysicsCache();
        _cache.saveZero(cs);
    }

    void considerGC() nothrow
    {
        if (_cache)
            _cache.considerGC();
    }

    Phyu updatesSinceZero() const
    out (result) { assert (result >= 0); }
    do { return Phyu(now - _cache.zeroStatePhyu); }

    bool userStateExists() { return _cache.userStateExists; }
    void saveUserState()   { _cache.saveUser(cs, replay); }

    final void cutGlobalFutureFromReplay()
    {
        if (replay.latestPhyu <= now) {
            return;
        }
        replay.cutGlobalFutureAfter(now);
        onCuttingSomethingFromReplay();
    }

    void loadUserState()
    {
        auto loaded = _cache.loadUser(replay, Phyu(cs.age + 1));
        model.takeOwnershipOf(loaded.state.clone);

        // Now, 'now' is the loaded state's age, not our old 'now'.
        immutable bool eqb = replay.equalBefore(loaded.replay, Phyu(now + 1));
        immutable bool ext = replay.extends(loaded.replay);
        if (! eqb || ! ext) {
            replay = loaded.replay.clone();
            if (! eqb) {
                // A visible difference already at now().
                onCuttingSomethingFromReplay(); // Don't cut, but play sound.
            }
        }
        if (! replayAfterFrameBack.value) {
            cutGlobalFutureFromReplay();
        }
    }

    void restartLevel()
    {
        replay.eraseEarlySingleplayerNukes();
        model.takeOwnershipOf(
            _cache.loadBeforePhyu(_cache.zeroStatePhyu).clone);
    }

    void framestepBackBy(int backBy)
    {
        framestepBackTo(Phyu(now - backBy));
        if (! file.option.replayAfterFrameBack.value) {
            cutGlobalFutureFromReplay();
        }
    }

    /*
     * Rewinds physics, but doesn't advance. The Game will tell us to advance.
     * We must rewind to keep physics consistent with the replay up to then.
     * I forgot why we don't immediately advance back to the original phyu
     * -- probably we (don't advance) to do the minimum possible work
     * in this function addPlyMaybeGoBack.
     */
    void addPlyMaybeGoBack(const(Ply[]) vec)
    {
        if (vec.length == 0)
            return;
        assert (replay);
        vec.each!(data => replay.add(data));
        framestepBackTo(Phyu(vec.map!(data => data.when).reduce!min - 1));
    }

    void tweakReplayRecomputePhysics(in ChangeRequest rq)
    {
        immutable Phyu current = now;
        immutable tweakResult = replay.tweak(rq);
        if (! tweakResult.somethingChanged) {
            return;
        }
        framestepBackTo(Phyu(tweakResult.firstDifference - 1));
        updateTo(max(current, tweakResult.goodPhyuToView));
        if (rq.how == ChangeVerb.cutFutureOfOneLix) {
            onCuttingSomethingFromReplay();
        }
    }

    void updateTo(in Phyu targetPhyu)
    {
        while (! doneAnimating && now < targetPhyu) {
            updateOnce();
            considerAutoSavestateIfCloseTo(targetPhyu, DuringTurbo.no);
        }
    }

protected:
    final override void onDispose()
    {
        if (_cache) {
            _cache.dispose();
            _cache = null;
        }
    }

    // Override this, e.g., if you want to draw from the InteractiveNurse
    void onAutoSave() { }
    void onCuttingSomethingFromReplay() { }

    final void considerAutoSavestateIfCloseTo(
        in Phyu target, in DuringTurbo turbo
    ) {
        assert (_cache);
        if (_cache.wouldAutoSave(cs, target, turbo)) {
            version (tharsisprofiling)
                Zone zone = Zone(profiler, "SaveStatingNurse autosaves");
            onAutoSave();
            _cache.autoSave(cs, target);
        }
    }

private:
    void framestepBackTo(immutable Phyu u)
    {
        if (u >= now)
            return;
        model.takeOwnershipOf(_cache.loadBeforePhyu(Phyu(u + 1)).clone);
        replay.eraseEarlySingleplayerNukes(); // should bring no bugs
        updateTo(u);
    }
}
