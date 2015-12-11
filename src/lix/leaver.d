module lix.leaver;

import lix;
import hardware.sound;

class RemovedLix : PerformedActivity {

    mixin(CloneByCopyFrom!"RemovedLix");

    override @property bool blockable() const { return false; }

    override void onBecome()
    out {
        assert (lixxie.outsideWorld.tribe.lixOut     >= 0);
        assert (lixxie.outsideWorld.tribe.lixLeaving >= 0);
    }
    body {
        assert (lixxie.performedActivity.ac != Ac.nothing,
            "Lix can't be killed twice, that would miscount them.");
        if (healthy) --outsideWorld.tribe.lixOut;
        else         --outsideWorld.tribe.lixLeaving;
    }

}



abstract class Leaver : PerformedActivity {

    override @property bool blockable() const { return false; }

    override void onBecome()
    {
        --lixxie.outsideWorld.tribe.lixOut;
        ++lixxie.outsideWorld.tribe.lixLeaving;
    }

    override void performActivity() { advanceFrameAndLeave(); }

    final void advanceFrameAndLeave()
    {
        if (lixxie.isLastFrame)
            lixxie.become(Ac.nothing);
        else
            lixxie.advanceFrame();
    }

}



class Exiter : Leaver {

    int xOffsetFromGoal;

    mixin(CloneByCopyFrom!"Exiter");

    protected void copyFromAndBindToLix(in Exiter rhs, Lixxie lixToBindTo)
    {
        super.copyFromAndBindToLix(rhs, lixToBindTo);
        xOffsetFromGoal = rhs.xOffsetFromGoal;
    }

    // DTODOSKILLS: Implement moving left/right during exiting
}



class Splatter : Leaver {

    mixin(CloneByCopyFrom!"Splatter");

    override void onBecome()
    {
        playSound(Sound.SPLAT);
        super.onBecome();
    }
}

class Burner : Leaver {

    mixin(CloneByCopyFrom!"Burner");

    override void onBecome()
    {
        playSound(Sound.FIRE);
        super.onBecome();
    }
    // DTODOSKILLS: Implement moving up/down in the air
}

class Drowner : Leaver {

    mixin(CloneByCopyFrom!"Burner");

    override void onBecome()
    {
        playSound(Sound.WATER);
        super.onBecome();
    }
    // DTODOSKILLS: Look at C++ Lix about how we moved during drowning
}
