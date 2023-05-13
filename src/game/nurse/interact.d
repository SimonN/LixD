module game.nurse.interact;

import game.nurse.cache;
import hardware.sound;

public import game.nurse.savestat;

class InteractiveNurse : SaveStatingNurse {
    /*
     * Forwarding constructor. We get to own the replay, but not the level
     * or the EffectManager. EffectManager must exist for interactive mode.
     */
    this(in Level lev, Replay rp, EffectSink ef)
    {
        assert (ef !is null);
        super(lev, rp, ef);
    }

    void updateTo(in Phyu targetPhyu, in DuringTurbo duringTurbo)
    {
        while (! doneAnimating && now < targetPhyu) {
            updateOnce();
            considerAutoSavestateIfCloseTo(targetPhyu, duringTurbo);
        }
    }

    void terminateSingleplayerWithNuke()
    {
        if (everybodyOutOfLix)
            return;
        replay.terminateSingleplayerWithNukeAfter(now);
    }

    void applyChangesToLand() { model.applyChangesToLand(); }

protected:
    override void onAutoSave()
    {
        // It seems dubious to do drawing to bitmaps during calc/update.
        // However, savestates save the land too, and they should
        // hold the correctly updated land. We could save an instance
        // of a PhysicsDrawer along inside the savestate, but then we would
        // redraw over and over when loading from this state during
        // framestepping backwards. Instead, let's calculate the land now.
        model.applyChangesToLand();
    }

    override void onCuttingSomethingFromReplay()
    {
        playLoud(Sound.SCISSORS);
    }
}
