module lix.skill.leaver;

import lix;
import hardware.sound;

class RemovedLix : Job {
    mixin JobChild;

    override @property bool blockable() const { return false; }

    override void onBecome(in Job old)
    {
        assert (old.ac != Ac.nothing,
            "Lix can't be killed twice, that would miscount them.");
        if (JobUnion.healthy(old.ac))
            outsideWorld.tribe.recordOutToLeaver(
                lixxie.outsideWorld.state.update);
        outsideWorld.tribe.recordLeaverDone();
        lixxie.ploderTimer = 0; // Hard cancel :/ Maybe burn fast and then 0?
    }

}



abstract class Leaver : Job {
    mixin JobChild;

    override @property bool blockable() const { return false; }

    final override void onBecome(in Job old)
    {
        lixxie.outsideWorld.tribe.recordOutToLeaver(
            lixxie.outsideWorld.state.update);
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
    mixin JobChild;

    override void onBecomeLeaver(in Job)
    {
        playSound(Sound.SPLAT);
    }
}

class Burner : Leaver {
    mixin JobChild;

    override void onBecomeLeaver(in Job)
    {
        playSound(Sound.FIRE);
    }
}

class Drowner : Leaver {
    mixin JobChild;

    override void onBecomeLeaver(in Job old)
    {
        playSound(Sound.WATER);
        if (old.ac == Ac.tumbler && old.frame >= 9)
            // fall head-first into water, not feet-first (frame 0)
            this.frame = 6;
    }
}
