module lix.leaving;

import lix;
import hardware.sound;

class RemovedLix : PerformedActivity {

    mixin(CloneByCopyFrom!"RemovedLix");

    override @property bool leaving()   const { return true;  }
    override @property bool blockable() const { return false; }

    override void onBecome()
    {
        assert (lixxie.performedActivity.ac != Ac.NOTHING,
            "Lix can't be killed twice, that would miscount them.");
        assert (lixxie.performedActivity.leaving,
            "Lix should only transistion to NOTHING from a killing/exiting "
            "animation. Otherwise, they won't be counted correctly. "
            "See template KillingInformation for the counting.");
        --outsideWorld.tribe.lixLeaving;
    }

}



private mixin template KillingAnimation(
    string className,
    Sound  soundEffect
) {
    mixin(CloneByCopyFrom!className);

    override @property bool leaving()   const { return true;  }
    override @property bool blockable() const { return false; }

    override void onBecome()
    {
        --outsideWorld.tribe.lixOut;
        ++outsideWorld.tribe.lixLeaving;
        static if (soundEffect != Sound.NOTHING)
            playSound(soundEffect);
    }

    override void performActivity()
    {
        if (isLastFrame)
            become(Ac.NOTHING);
        else
            advanceFrame();
    }
}



class Exiter : PerformedActivity {

    int xOffsetFromGoal;

    mixin KillingAnimation!("Exiter", Sound.NOTHING);

    alias copyFromAndBindToLix = super.copyFromAndBindToLix;
    protected void copyFromAndBindToLix(in Exiter rhs, Lixxie lixToBindTo)
    {
        super.copyFromAndBindToLix(rhs, lixToBindTo);
        xOffsetFromGoal = rhs.xOffsetFromGoal;
    }

    // DTODOSKILLS: Implement moving left/right during exiting
}



class Splatter : PerformedActivity {
    mixin KillingAnimation!("Splatter", Sound.SPLAT);
}

class Burner : PerformedActivity {
    mixin KillingAnimation!("Burner", Sound.FIRE);
    // DTODOSKILLS: Implement moving up/down in the air
}

class Drowner : PerformedActivity {
    mixin KillingAnimation!("Drowner", Sound.WATER);
    // DTODOSKILLS: Look at C++ Lix about how we moved during drowning
}
