module graphic.gadget.hatch;

import std.algorithm; // min

import basics.help;
import basics.globals; // hatch arrow graphic
import basics.topology;
import game.effect;
import graphic.cutbit;
import graphic.gadget;
import graphic.internal;
import hardware.sound;
import net.ac;
import net.repdata;
import net.style;
import tile.occur;

class Hatch : GadgetWithTribeList {
private:
    bool _blinkNow;

public:
    immutable bool spawnFacingLeft;

    enum updateOpen      = 55;
    enum updateBlinkStop = 48;
    enum updatesBlinkOn  =  4;
    enum updatesBlinkOff =  2;

    this(const(Topology) top, in GadOcc levelpos)
    {
        super(top, levelpos);
        spawnFacingLeft = levelpos.hatchRot;
    }

    this(in Hatch rhs)
    {
        assert (rhs);
        super(rhs);
        spawnFacingLeft = rhs.spawnFacingLeft;
        _blinkNow       = rhs._blinkNow;
    }

    override Hatch clone() const { return new Hatch(this); }

    override void perform(in Phyu u, EffectSink effect)
    {
        // (of) is first absolute frame of opening. This is earlier if the
        // sound shall match a later frame of the hatch, as given by specialX.
        // xfs * yfs is length of animation, see Gadget.animateForPhyu.
        immutable int of = updateOpen - tile.specialX;
        frame = (u - of).clamp(0, frames - 1);

        if (u >= updateBlinkStop)
            _blinkNow = false;
        else {
            _blinkNow
            = (u % (updatesBlinkOn + updatesBlinkOff) < updatesBlinkOn);
        }
        if (u == updateOpen)
            effect.addSoundGeneral(u, Sound.HATCH_OPEN);
    }

protected:
    override void onDraw(in Style blinkStyle) const
    {
        if (_blinkNow && hasTribe(blinkStyle) && blinkStyle != Style.garden) {
            const(Cutbit) c = getSkillButtonIcon(blinkStyle);
            c.draw(loc + tile.trigger - c.len/2,
                Ac.walker.acToSkillIconXf, 0);
        }
    }
}
// end class Hatch
