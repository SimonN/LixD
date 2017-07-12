module graphic.gadget.openfor;

/* GadgetAnimsOnFeed : Gadget      has the method isOpenFor(Tribe).
 * Water       : GadgetAnimsOnFeed is a permanent trap, water or fire.
 * Triggerable : GadgetAnimsOnFeed is a cooldown trap or cooldown flinger.
 *
 * GadgetAnimsOnFeed allows for two different rows of animation: The first row
 * is looped while idle. When a lix enters, the game immediately jumps to the
 * second row, finishes one loop through the second row, then displays the
 * first frame of the first row again. This first frame of the first row is
 * skipped if the gadget is triggered immediately again that frame, instead
 * looping back to the beginning of the second row. Thus: If the second row
 * has n frames, the gadget activates every n frames.
 *
 * Second row doesn't exist: This is outdated from C++ Lix and D Lix 0.6.
 * I removed the code for that. It worked like this: Frame 0 from the first
 * row is shown all the time while idle. All frames other than the first frame
 * act like the second row in the second-row-exists case. You had to loop
 * into frame 0 and show frame 0 at least once between two eatings.
 */

import basics.help;
import net.repdata;
import basics.topology;
import graphic.gadget;
import graphic.torbit;
import tile.occur;
import tile.gadtile;
import hardware.sound;
import net.style;

public alias Water     = PermanentlyOpen;
public alias Fire      = PermanentlyOpen;
public alias FlingPerm = PermanentlyOpen;

public alias TrapTrig  = GadgetAnimsOnFeed;
public alias FlingTrig = GadgetAnimsOnFeed;
public alias Flinger   = GadgetAnimsOnFeed; // both FlingPerm and FlingTrig

private class GadgetAnimsOnFeed : GadgetWithTribeList {
    Phyu wasFedDuringPhyu;
    immutable int idleAnimLength;
    immutable int eatingAnimLength;

    this(const(Topology) top, in ref GadOcc levelpos)
    out { assert (idleAnimLength >= 1); }
    body {
        super(top, levelpos);
        idleAnimLength = delegate() {
            if (! tile || ! tile.cb || ! tile.cb.frameExists(0, 0))
                return 1;
            for (int i = 0; i < tile.cb.xfs; ++i)
                if (! tile.cb.frameExists(i, 0))
                    return i;
            return tile.cb.xfs;
        }();
        eatingAnimLength = delegate() {
            if (! tile || ! tile.cb)
                return 1;
            else if (tile.cb.yfs == 1)
                return tile.cb.xfs - 1;
            else for (int i = 0; i < tile.cb.xfs; ++i)
                if (! tile.cb.frameExists(i, 1))
                    return i;
            return tile.cb.xfs;
        }();
    }

    this(in GadgetAnimsOnFeed rhs)
    {
        super(rhs);
        wasFedDuringPhyu = rhs.wasFedDuringPhyu;
        idleAnimLength   = rhs.idleAnimLength;
        eatingAnimLength = rhs.eatingAnimLength;
    }

    override GadgetAnimsOnFeed clone() const
    {
        return new GadgetAnimsOnFeed(this);
    }

    bool isOpenFor(in Phyu upd, in Style st) const
    {
        // During a single update, the gadget can eat a lix from each tribe.
        // This is fairest in multiplayer.
        if (wasFedDuringPhyu == upd)
            return ! hasTribe(st);
        else
            return ! isEating(upd);
    }

    bool isEating(in Phyu upd) const
    {
        assert (upd >= wasFedDuringPhyu, "relics from the future");
        return upd < firstIdlingPhyuAfterEating;
    }

    void feed(in Phyu upd, in Style st)
    {
        assert (isOpenFor(upd, st), "don't feed what it's not open for");
        super.addTribe(st);
        wasFedDuringPhyu = upd;
    }

    override void animateForPhyu(in Phyu upd)
    {
        if (isEating(upd)) {
            yf = 1;
            xf = upd - wasFedDuringPhyu;
        }
        else {
            yf = 0;
            xf = (upd - firstIdlingPhyuAfterEating) % idleAnimLength;
        }
        clearTribes();
    }

private:
    Phyu firstIdlingPhyuAfterEating() const
    {
        return wasFedDuringPhyu == 0 ? Phyu(0) // never eaten anything
            : Phyu(wasFedDuringPhyu + eatingAnimLength);
    }
}
// end class GadgetAnimsOnFeed

private class PermanentlyOpen : GadgetAnimsOnFeed {

    mixin (StandardGadgetCtor);

    override PermanentlyOpen clone() const { return new PermanentlyOpen(this);}
    this(in PermanentlyOpen rhs) { super(rhs); }

    override bool isOpenFor(in Phyu, in Style) const { return true; }

    override void animateForPhyu(in Phyu upd)
    {
        Gadget.animateForPhyu(upd); // the constantly looping animation
    }

    override @property Sound sound()
    {
        return tile.type != GadType.WATER ? Sound.NOTHING // perm. flinger
             : tile.subtype == 0           ? Sound.WATER
             :                               Sound.FIRE;
    }
}
// end class PermanentAnim
