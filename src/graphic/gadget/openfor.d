module graphic.gadget.openfor;

/* GadgetAnimsOnFeed : Gadget      has the method isOpenFor(Tribe).
 * Water       : GadgetAnimsOnFeed is a permanent trap, water or fire.
 * Triggerable : GadgetAnimsOnFeed is a cooldown trap or cooldown flinger.
 *
 * GadgetAnimsOnFeed allows for two different rows of animation: The first row
 * is played back once whenever a lix enters the gadget. The second row is
 * looped while the gadget is idle. If the second row doesn't exist, frame 0
 * from the first row is shown all the time while idle. Frame 0 from the first
 * row never belongs to the once-played-back anim, even if there is a 2nd row.
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

    Update wasFedDuringUpdate;
    const(int) idleAnimLength;

    this(const(Topology) top, in ref GadOcc levelpos)
    {
        super(top, levelpos);
        idleAnimLength = delegate() {
            if (! tile || ! tile.cb)
                return 0;
            else for (int i = 0; i < levelpos.tile.cb.xfs; ++i)
                if (! levelpos.tile.cb.frameExists(i, 1))
                    return i;
            return levelpos.tile.cb.xfs;
        }();
    }

    this(in GadgetAnimsOnFeed rhs)
    {
        super(rhs);
        wasFedDuringUpdate = rhs.wasFedDuringUpdate;
        idleAnimLength    = rhs.idleAnimLength;
    }

    override GadgetAnimsOnFeed clone() const
    {
        return new GadgetAnimsOnFeed(this);
    }

    bool isOpenFor(in Update upd, in Style st) const
    {
        // During a single update, the gadget can eat a lix from each tribe.
        // This is fairest in multiplayer.
        if (wasFedDuringUpdate == upd)
            return ! hasTribe(st);
        else
            return ! isEating(upd);
    }

    bool isEating(in Update upd) const
    {
        assert (upd >= wasFedDuringUpdate, "relics from the future");
        return upd < firstIdlingUpdateAfterEating;
    }

    void feed(in Update upd, in Style st)
    {
        assert (isOpenFor(upd, st), "don't feed what it's not open for");
        super.addTribe(st);
        wasFedDuringUpdate = upd;
    }

    override void animateForUpdate(in Update upd)
    {
        if (isEating(upd)) {
            yf = 0;
            xf = (upd == firstIdlingUpdateAfterEating - 1)
                ? 0 // Last frame of eating is a frame that looks like idling.
                    // This is a mechanic taken over 1:1 from C++ Lix.
                : upd - wasFedDuringUpdate + 1;
        }
        else if (idleAnimLength == 0) {
            yf = 0;
            xf = 0;
        }
        else {
            yf = 1;
            xf = (upd - firstIdlingUpdateAfterEating) % idleAnimLength;
        }
        clearTribes();
    }

private:
    Update firstIdlingUpdateAfterEating() const
    {
        if (wasFedDuringUpdate == 0)
            // _wasFedDuringUpdate == 0 is the init value, there shouldn't
            // happen anything on that frame, Game.update isn't even called.
            return Update(0);
        else
            // Frame 0 may not be part of the anim, but even under a very dense
            // stream of lix, frame 0 is shown after eating for 1 update.
            // Thus, no -1 here.
            return Update(wasFedDuringUpdate + animationLength);
    }
}
// end class GadgetAnimsOnFeed

private class PermanentlyOpen : GadgetAnimsOnFeed {

    mixin (StandardGadgetCtor);

    override PermanentlyOpen clone() const { return new PermanentlyOpen(this);}
    this(in PermanentlyOpen rhs) { super(rhs); }

    override bool isOpenFor(in Update, in Style) const { return true; }

    override void animateForUpdate(in Update upd)
    {
        Gadget.animateForUpdate(upd); // the constantly looping animation
    }

    override @property Sound sound()
    {
        return tile.type != GadType.WATER ? Sound.NOTHING // perm. flinger
             : tile.subtype == 0           ? Sound.WATER
             :                               Sound.FIRE;
    }
}
// end class PermanentAnim
