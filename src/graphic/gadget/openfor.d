module graphic.gadget.openfor;

/* GadgetCanBeOpen : Gadget      has the method isOpenFor(Tribe).
 * Water       : GadgetCanBeOpen is a permanent trap, water or fire.
 * Triggerable : GadgetCanBeOpen is a cooldown trap or cooldown flinger.
 * Trampoline  : GadgetCanBeOpen is permanently active, anims on trigger.
 */

import basics.help;
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

private class GadgetCanBeOpen : Gadget {

public:

    int wasFedDuringFrame;

    mixin (StandardGadgetCtor);

    this(in GadgetCanBeOpen rhs)
    {
        super(rhs);
        _tribes = rhs._tribes.dupConst;
        wasFedDuringFrame = rhs.wasFedDuringFrame;
    }

    abstract override GadgetCanBeOpen clone() const;

    bool isOpenFor(in Tribe t) const { return ! hasTribe(t); }

    final void addTribe(in Tribe t)
    {
        if (! hasTribe(t))
            _tribes ~= t;
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
        // reset list of tribes that have activated the gadget in this frame
        _tribes = null;
    }

private:

    const(Tribe)[] _tribes;

    final protected bool hasTribe(in Tribe t) const
    {
        foreach (tribeInVec; _tribes)
            if (t is tribeInVec)
                return false;
        return true;
    }

}
// end class GadgetCanBeOpen



private class PermanentlyOpen : GadgetCanBeOpen {

    mixin (StandardGadgetCtor);

    override PermanentlyOpen clone() const { return new PermanentlyOpen(this);}
    this(in PermanentlyOpen rhs) { super(rhs); }

    override bool isOpenFor(in Tribe t) const { return true; }

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

    override bool isOpenFor(in Tribe t) const
    {
        return xf == 0 && ! hasTribe(t);
    }

}
// end class Triggerable



class Trampoline : GadgetCanBeOpen {

    mixin (StandardGadgetCtor);

    override Trampoline clone() const { return new Trampoline(this);}
    this(in Trampoline rhs) { super(rhs); }

    override bool isOpenFor(in Tribe t) const
    {
        // trampolines are always active, even if they animate only on demand
        return true;
    }

}
// end class Trampoline
