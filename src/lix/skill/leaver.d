module lix.skill.leaver;

import lix;
import hardware.sound;

class RemovedLix : Job {

    mixin(CloneByCopyFrom!"RemovedLix");

    override @property bool blockable() const { return false; }

    override void onBecome()
    out {
        assert (lixxie.outsideWorld.tribe.lixOut     >= 0);
        assert (lixxie.outsideWorld.tribe.lixLeaving >= 0);
    }
    body {
        assert (lixxie.job.ac != Ac.nothing,
            "Lix can't be killed twice, that would miscount them.");
        if (healthy) --outsideWorld.tribe.lixOut;
        else         --outsideWorld.tribe.lixLeaving;
    }

}



abstract class Leaver : Job {

    override @property bool blockable() const { return false; }

    final override void onBecome()
    {
        --lixxie.outsideWorld.tribe.lixOut;
        ++lixxie.outsideWorld.tribe.lixLeaving;
        onBecomeLeaver();
    }

    void onBecomeLeaver() { } // override this instead of onBecome

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

    mixin(CloneByCopyFrom!"Splatter");

    override void onBecomeLeaver()
    {
        playSound(Sound.SPLAT);
    }
}

class Burner : Leaver {

    mixin(CloneByCopyFrom!"Burner");

    override void onBecomeLeaver()
    {
        playSound(Sound.FIRE);
    }
    // DTODOSKILLS: Implement moving up/down in the air
}

class Drowner : Leaver {

    mixin(CloneByCopyFrom!"Drowner");

    override void onBecomeLeaver()
    {
        if (lixxie.ac == Ac.tumbler && lixxie.frame >= 9)
            // fall head-first into water, not feet-first (frame 0)
            this.frame = 6;
        playSound(Sound.WATER);
    }
    // DTODOSKILLS: Look at C++ Lix about how we moved during drowning
}
