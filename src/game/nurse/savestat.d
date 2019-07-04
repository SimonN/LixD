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
    body { return Phyu(upd - _cache.zeroStatePhyu); }

    bool userStateExists() { return _cache.userStateExists; }
    void saveUserState()   { _cache.saveUser(cs, replay); }

    void cutReplay()
    {
        if (replay.latestPhyu <= upd)
            return;
        onCutReplay();
        replay.deleteAfterPhyu(upd);
    }

    void loadUserState()
    {
        auto loaded = _cache.loadUser(replay, Phyu(cs.update + 1));
        model.takeOwnershipOf(loaded.state.clone);

        if (! replay.equalBefore(loaded.replay, Phyu(upd + 1))) {
            replay = loaded.replay.clone();
            onCutReplay(); // don't cut, but maybe play sound
        }
        if (! replayAfterFrameBack.value)
            cutReplay();
    }

    void restartLevel()
    {
        replay.eraseEarlySingleplayerNukes();
        model.takeOwnershipOf(
            _cache.loadBeforePhyu(_cache.zeroStatePhyu).clone);
    }

    void framestepBackBy(int backBy)
    {
        framestepBackTo(Phyu(upd - backBy));
        if (! file.option.replayAfterFrameBack.value)
            cutReplay();
    }

    void addPlyMaybeGoBack(const(Ply[]) vec)
    {
        if (vec.length == 0)
            return;
        assert (replay);
        vec.each!(data => replay.add(data));
        framestepBackTo(Phyu(vec.map!(data => data.update).reduce!min - 1));
    }

    void updateTo(in Phyu targetPhyu)
    {
        while (! doneAnimating && upd < targetPhyu) {
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
    void onCutReplay() { }

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
        if (u >= upd)
            return;
        model.takeOwnershipOf(_cache.loadBeforePhyu(Phyu(u + 1)).clone);
        replay.eraseEarlySingleplayerNukes(); // should bring no bugs
        updateTo(u);
    }
}
