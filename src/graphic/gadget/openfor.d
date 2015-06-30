module graphic.gadget.openfor;

/* GadgetCanBeOpen : Gadget      has the method is_open_for(Tribe).
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

class GadgetCanBeOpen : Gadget {

public:

    mixin (StandardGadgetCtor!());

    this(typeof (this) rhs)
    {
        super(rhs);
        _tribes     = rhs._tribes;
        _start_anim = rhs._start_anim;
    }

    abstract override typeof (this) clone();

    @property bool start_anim() const { return _start_anim;     }
    @property bool start_anim(bool b) { return _start_anim = b; }

    bool is_open_for(Tribe t) { return ! has_tribe(t); }

    final void add_tribe(Tribe t)
    {
        if (! has_tribe(t))
            _tribes ~= t;
    }

    override void animate()
    {
        if (xf != 0 || _start_anim)
            super.animate();
        _start_anim = false;
        _tribes = null;
    }

private:

    Tribe[] _tribes;
    bool _start_anim;

    final protected bool has_tribe(const(Tribe) t) const
    {
        foreach (tribe_in_vec; _tribes)
            if (t is tribe_in_vec)
                return false;
        return true;
    }

}
// end class GadgetCanBeOpen



private class PermanentlyOpen : GadgetCanBeOpen {

    mixin (StandardGadgetCtor!());
    mixin (CloneableTrivialOverride!());

    override bool is_open_for(Tribe t)
    {
        return true;
    }

    override void animate()
    {
        Gadget.animate(); // the constantly looping animation
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

    mixin (StandardGadgetCtor!());
    mixin (CloneableTrivialOverride!());

    override bool is_open_for(Tribe t)
    {
        return xf == 0 && ! has_tribe(t);
    }

}
// end class Triggerable



class Trampoline : GadgetCanBeOpen {

    mixin (StandardGadgetCtor!());
    mixin (CloneableTrivialOverride!());

    override bool is_open_for(Tribe t)
    {
        // trampolines are always active, even if they animate only on demand
        return true;
    }

}
// end class Trampoline
