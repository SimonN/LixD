module physics.job.leaver;

import hardware.sound;
import physics.job;

class RemovedLix : Job {
    override bool blockable() const { return false; }

    override void onBecome(in Job old)
    {
        assert (old.ac != Ac.nothing,
            "Lix can't be killed twice, that would miscount them.");
        if (JobUnion.healthy(old.ac))
            lixxie.outsideWorld.tribe.recordOutToLeaver(
                lixxie.outsideWorld.state.age);
        lixxie.outsideWorld.tribe.recordLeaverDone();
        lixxie.ploderTimer = 0; // Hard cancel :/ Maybe burn fast and then 0?
    }
}

abstract class Leaver : Job {
    override bool blockable() const { return false; }

    final override void onBecome(in Job old)
    {
        lixxie.outsideWorld.tribe.recordOutToLeaver(
            lixxie.outsideWorld.state.age);
        onBecomeLeaver(old);
    }

    void onBecomeLeaver(in Job) { } // override this instead of onBecome

    override void perform() { advanceFrameAndLeave(); }

    final void advanceFrameAndLeave()
    {
        if (lixxie.isLastFrame)
            lixxie.become(Ac.nothing);
        else
            lixxie.advanceFrame();
    }
}

class Splatter : Leaver {
    override void onBecomeLeaver(in Job)
    {
        lixxie.playSound(Sound.SPLAT);
    }
}

class Burner : Leaver {
    override void onBecomeLeaver(in Job)
    {
        lixxie.playSound(Sound.FIRE);
    }
}

class Drowner : Leaver {
    override void onBecomeLeaver(in Job old)
    {
        lixxie.playSound(Sound.WATER);
        if (old.ac == Ac.tumbler && old.frame >= 9)
            // fall head-first into water, not feet-first (frame 0)
            this.frame = 6;
    }
}
