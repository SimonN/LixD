module graphic.gadget.hatch;

import std.algorithm; // min

import basics.help;
import basics.globals; // hatch arrow graphic
import game.effect;
import graphic.cutbit;
import graphic.gadget;
import graphic.gralib;
import graphic.torbit;
import hardware.sound;
import level.level;
import level.tile;
import lix.enums;

class Hatch : Gadget {

private:

    int  _xFramesOpen;
    bool _blinkNow;

public:

    enum updateLetsGo    = 35;
    enum updateOpen      = 50;
    enum updateBlinkStop = 48;
    enum updatesBlinkOn  =  4;
    enum updatesBlinkOff =  2;

    bool  spawnFacingLeft;
    Style blinkStyle = Style.GARDEN; // if left at GARDEN, then don't blink

    this(in Torbit tb, in ref Pos levelpos)
    {
        super(tb, levelpos);
        spawnFacingLeft = levelpos.rot != 0;
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

    override Pos toPos() const
    {
        Pos levelpos = super.toPos();
        levelpos.rot = spawnFacingLeft;
        return levelpos;
    }

    deprecated("use Hatch.animate(EffectManager, int) instead")
    override void animateForUpdate(in int) { }

    void animate(EffectManager effect, in int u) // update of the Game
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

        if (u == updateLetsGo)
            effect.addSoundGeneral(u, Sound.LETS_GO);
        if (u == updateOpen)
            effect.addSoundGeneral(u, Sound.HATCH_OPEN);
    }

protected:

    override void drawGameExtras(Torbit mutableGround) const
    {
        if (_blinkNow && blinkStyle != Style.GARDEN) {
            const(Cutbit) c = getPanelInfoIcon(blinkStyle);
            c.draw(mutableGround, x + tile.triggerX - c.xl / 2,
                                  y + tile.triggerY - c.yl / 2,
                                  Ac.WALKER, 0);
        }
    }

    override void drawEditorInfo(Torbit mutableGround) const
    {
        // draw arrow pointing into the hatch's direction
        const(Cutbit) cb = getInternal(fileImageEditHatch);
        cb.draw(mutableGround, x + yl/2 - cb.xl/2,
                               y + 20, // DTODO: +20 was text_height in A4/C++.
                               spawnFacingLeft ? 1 : 0, 0);
    }

}
// end class Hatch
