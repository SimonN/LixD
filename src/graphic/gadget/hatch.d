module graphic.gadget.hatch;

import std.algorithm; // min

import basics.help;
import basics.globals; // hatch arrow graphic
import basics.styleset;
import basics.topology;
import game.effect;
import graphic.cutbit;
import graphic.gadget;
import graphic.internal;
import hardware.sound;
import net.ac;
import net.repdata;
import tile.occur;

class Hatch : Gadget {
private:
    StyleSet _owners;

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
        _owners = rhs._owners;
        spawnFacingLeft = rhs.spawnFacingLeft;
    }

    override Hatch clone() const { return new Hatch(this); }

    void addOwner(in Style st) pure nothrow @safe @nogc { _owners.insert(st); }
    bool hasOwner(in Style st) const pure nothrow @safe @nogc
    {
        return _owners.contains(st);
    }

    static void maybePlaySound(in Phyu now, EffectSink effect)
    {
        if (now == updateOpen) {
            effect.addSoundGeneral(now, Sound.HATCH_OPEN);
        }
    }

protected:
    override Gadget.Frame frame(in Phyu now) const pure nothrow @safe @nogc
    {
        return Gadget.Frame((now - firstOpeningFrame).clamp(0, frames - 1));
    }

    override void onDraw(in Phyu now, in Style blinkStyle) const
    {
        if (shouldBlink(now)
            && hasOwner(blinkStyle) && blinkStyle != Style.garden
        ) {
            const c = Spritesheet.skillsInPanel.toCutbitFor(blinkStyle);
            c.draw(loc + tile.trigger - c.len/2,
                Ac.walker.acToSkillIconXf, 0);
        }
    }

private:
    // The first absolute frame of opening. This is earlier if the
    // sound shall match a later frame of the hatch, as given by specialX.
    // xfs * yfs is length of animation, see Gadget.animateForPhyu.
    int firstOpeningFrame() const pure nothrow @safe @nogc
    {
        return updateOpen - tile.specialX;
    }

    bool shouldBlink(in Phyu now) const pure nothrow @safe @nogc
    {
        return now < updateBlinkStop
            && now % (updatesBlinkOn + updatesBlinkOff) < updatesBlinkOn;
    }
}
// end class Hatch
