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

class Hatch : Gadget {
private:
    bool _blinkNow;

public:
    Style blinkStyle = Style.garden; // if left at garden, then don't blink
    immutable bool spawnFacingLeft;

    enum updateOpen      = 55;
    enum updateBlinkStop = 48;
    enum updatesBlinkOn  =  4;
    enum updatesBlinkOff =  2;

    this(const(Topology) top, in ref GadOcc levelpos)
    {
        super(top, levelpos);
        spawnFacingLeft = levelpos.hatchRot;
    }

    this(in Hatch rhs)
    {
        assert (rhs);
        super(rhs);
        spawnFacingLeft = rhs.spawnFacingLeft;
        blinkStyle      = rhs.blinkStyle;
        _blinkNow       = rhs._blinkNow;
    }

    override Hatch clone() const { return new Hatch(this); }

    // Don't call animateForPhyu on Hatches. Use animate() instead.
    // Still, the game iterates over all gadgets and calls our animateForPhyu.
    // Bad OO because we don't recommend parent class's interface.
    override void animateForPhyu(in Phyu) { }

    void animate(EffectManager effect, in Phyu u)
    {
        // (of) is first absolute frame of opening. This is earlier if the
        // sound shall match a later frame of the hatch, as given by specialX.
        // xfs * yfs is length of animation, see Gadget.animateForPhyu.
        immutable int of = updateOpen - tile.specialX;
        immutable int animLen = max(1, xfs * yfs);
        super.animateForPhyu(Phyu(max(0, min(u - of, animLen - 1))));

        if (u >= updateBlinkStop)
            _blinkNow = false;
        else {
            _blinkNow
            = (u % (updatesBlinkOn + updatesBlinkOff) < updatesBlinkOn);
        }
        if (u == updateOpen && effect)
            effect.addSoundGeneral(u, Sound.HATCH_OPEN);
    }

protected:
    override void drawInner() const
    {
        if (_blinkNow && blinkStyle != Style.garden) {
            const(Cutbit) c = getSkillButtonIcon(blinkStyle);
            c.draw(loc + tile.trigger - c.len/2,
                Ac.walker.acToSkillIconXf, 0);
        }
    }
}
// end class Hatch
