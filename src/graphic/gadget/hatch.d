module graphic.gadget.hatch;

import std.algorithm; // min

import basics.help;
import basics.globals; // hatch arrow graphic
import basics.topology;
import game.effect;
import graphic.cutbit;
import graphic.gadget;
import graphic.internal;
import graphic.torbit;
import hardware.sound;
import net.ac;
import net.repdata;
import net.style;
import tile.gadtile;
import tile.occur;

class Hatch : Gadget {
private:
    int  _xFramesOpen;
    bool _blinkNow;

public:
    enum updateOpen      = 55;
    enum updateBlinkStop = 48;
    enum updatesBlinkOn  =  4;
    enum updatesBlinkOff =  2;

    immutable bool spawnFacingLeft;
    Style blinkStyle = Style.garden; // if left at garden, then don't blink

    this(const(Topology) top, in ref GadOcc levelpos)
    {
        super(top, levelpos);
        spawnFacingLeft = levelpos.hatchRot;
        while (this.frameExists(_xFramesOpen, 0))
            ++_xFramesOpen;
    }

    this(in Hatch rhs)
    {
        assert (rhs);
        super(rhs);
        spawnFacingLeft = rhs.spawnFacingLeft;
        blinkStyle      = rhs.blinkStyle;
        _xFramesOpen    = rhs._xFramesOpen;
        _blinkNow       = rhs._blinkNow;
    }

    override Hatch clone() const { return new Hatch(this); }

    override void animateForPhyu(in Phyu) { } // use Hatch.animate instead

    void animate(EffectManager effect, in Phyu u)
    {
        immutable int of = updateOpen - tile.specialX;
        // of == first absolute frame of opening. This is earlier if the sound
        // shall match a later frame of the hatch, as defined in specialX.

        if (u < of)
            xf = yf = 0;
        else {
            // open or just opening
            yf = 0;
            xf = min(u - of,  _xFramesOpen - 1);
        }

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
