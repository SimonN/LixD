module graphic.gadget.openfor;

/* GadgetCanBeOpen : Gadget      has the method isOpenFor(Tribe).
 * Water       : GadgetCanBeOpen is a permanent trap, water or fire.
 * Triggerable : GadgetCanBeOpen is a cooldown trap or cooldown flinger.
 * Trampoline  : GadgetCanBeOpen is permanently active, anims on trigger.
 */

import basics.help;
import game.state;
import game.tribe;
import graphic.gadget;
import graphic.torbit;
import level.level;
import level.tile;
import hardware.sound;

public alias Water     = PermanentlyOpen;
public alias Fire      = PermanentlyOpen;
public alias FlingPerm = PermanentlyOpen;

public alias TrapTrig  = Triggerable;
public alias FlingTrig = Triggerable;

public alias Flinger   = GadgetCanBeOpen; // both FlingPerm and FlingTrig

private class GadgetCanBeOpen : GadgetWithTribeList {

public:

    int wasFedDuringFrame;

    mixin (StandardGadgetCtor);

    this(in GadgetCanBeOpen rhs)
    {
        super(rhs);
        wasFedDuringFrame = rhs.wasFedDuringFrame;
    }

    abstract override GadgetCanBeOpen clone() const;

    bool isOpenFor(in GameState s, in Tribe t) const
    {
        return ! hasTribe(s, t);
    }

    override void animateForUpdate(in int upd)
    {
        // _wasFedDuringFrame == 0 is the init value, there shouldn't ever
        // happen anything on that frame, Game.update isn't even called then
        if (wasFedDuringFrame == 0) {
            xf = 0;
        }
        else {
            immutable fr = (upd - wasFedDuringFrame) + 1;
            if (fr >= 0 && fr < animationLength)
                xf = fr;
            else
                xf = 0;
        }
        clearTribes();
    }

}
// end class GadgetCanBeOpen



private class PermanentlyOpen : GadgetCanBeOpen {

    mixin (StandardGadgetCtor);

    override PermanentlyOpen clone() const { return new PermanentlyOpen(this);}
    this(in PermanentlyOpen rhs) { super(rhs); }

    override bool isOpenFor(in GameState, in Tribe t) const { return true; }

    override void animateForUpdate(in int upd)
    {
        Gadget.animateForUpdate(upd); // the constantly looping animation
    }

    override @property Sound sound()
    {
        return tile.type != TileType.WATER ? Sound.NOTHING // perm. flinger
             : tile.subtype == 0           ? Sound.WATER
             :                               Sound.FIRE;
    }

}
// end class PermanentAnim



private class Triggerable : GadgetCanBeOpen {

    mixin (StandardGadgetCtor);

    override Triggerable clone() const { return new Triggerable(this);}
    this(in Triggerable rhs) { super(rhs); }

    override bool isOpenFor(in GameState s, in Tribe t) const
    {
        return xf == 0 && ! hasTribe(s, t);
    }

}
// end class Triggerable



class Trampoline : GadgetCanBeOpen {

    mixin (StandardGadgetCtor);

    override Trampoline clone() const { return new Trampoline(this);}
    this(in Trampoline rhs) { super(rhs); }

    override bool isOpenFor(in GameState s, in Tribe t) const
    {
        // trampolines are always active, even if they animate only on demand
        return true;
    }

}
// end class Trampoline
