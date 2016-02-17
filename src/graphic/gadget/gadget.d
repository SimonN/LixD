module graphic.gadget.gadget;

/* Gadget was called EdGraphic in A4/C++ Lix. It represents a Graphic that
 * was created from a Tile, not merely from any Cutbit. The original purpose
 * of EdGraphic was to represent instances of Tile in the editor.
 *
 * Because EdGraphics were extremely useful in the gameplay too, D/A5 Lix
 * treats that use as the main use, and the appropriate name is Gadget.
 * Terrain or steel is not realized in the game as Gadgets, they're drawn
 * onto the land and their Tile nature is immediately forgot afterwards.
 *
 * The editor will use Gadgets for all Tiles, and not call upon the more
 * sophisticated animation functions which the gameplay uses.
 *
 * DTODO: We're introducing a ton of special cases for GadType.HATCH here.
 * Consider making a subclass for that.
 */

import std.conv;

import basics.help;
import basics.nettypes;
import basics.topology;
import game.model.state;
import graphic.cutbit;
import graphic.color;
import graphic.graphic;
import graphic.gadget;
import graphic.torbit;
import tile.phymap;
import tile.pos;
import tile.gadtile;
import hardware.sound;

package immutable string StandardGadgetCtor =
    "this(const(Topology) top, in ref GadPos levelpos)
    {
        super(top, levelpos);
    }";



class Gadget : Graphic {

public:

    const(GadgetTile) tile;
    const(int) animationLength;
    bool       drawWithEditorInfo;

    // override these if necessary
    protected void drawGameExtras(Torbit, in GameState) const { }
    protected void drawEditorInfo(Torbit) const { }

    @property Sound sound() { return Sound.NOTHING; }

// protected: use the factory to generate gadgets of the correct subclass
protected this(const(Topology) top, in ref GadPos levelpos)
in {
    assert (levelpos.ob, "we shouldn't make gadgets from missing tiles");
    assert (levelpos.ob.cb, "we shouldn't make gadgets from bad tiles");
}
body {
    super(levelpos.ob.cb, top, levelpos.x, levelpos.y);
    tile = levelpos.ob;
    animationLength = delegate() {
        if (levelpos.ob.cb is null)
            return 1;
        for (int i = 0; i < levelpos.ob.cb.xfs; ++i)
            if (! levelpos.ob.cb.frameExists(i, 0))
                return i;
        return levelpos.ob.cb.xfs;
    }();
}



public:

override Gadget clone() const { return new Gadget(this); }

this(in Gadget rhs)
in {
    assert (rhs !is null, "we shouldn't copy from null rhs");
    assert (rhs.tile !is null, "don't copy from rhs with missing tile");
}
body {
    super(rhs);
    tile               = rhs.tile;
    animationLength    = rhs.animationLength;
    drawWithEditorInfo = rhs.drawWithEditorInfo;
}

invariant()
{
    assert (tile, "Gadget.tile should not be null");
    assert (tile.cb, "Gadget.tile.cb (the cutbit) shouldn't be null");
    assert (animationLength > 0, "Cutbit should have xfs > 0 unless null");
}

static Gadget
factory(const(Topology) top, in ref GadPos levelpos)
{
    assert (levelpos.ob);
    final switch (levelpos.ob.type) {
        case GadType.DECO:    return new Gadget  (top, levelpos);
        case GadType.HATCH:   return new Hatch   (top, levelpos);
        case GadType.GOAL:    return new Goal    (top, levelpos);
        case GadType.TRAP:    return new TrapTrig(top, levelpos);
        case GadType.WATER:   return new Water   (top, levelpos);
        case GadType.FLING:
            if (levelpos.ob.subtype & 2) return new FlingTrig(top, levelpos);
            else                         return new FlingPerm(top, levelpos);
        case GadType.MAX:
            assert (false, "GadType isn't supported by Gadget.factory");
    }
}

void
animateForUpdate(in Update upd)
{
    xf = positiveMod(upd, animationLength);
}

deprecated("Gadgets should be drawn with const GameState") final override void
draw(Torbit mutableGround) const { super.draw(mutableGround); }

final void
draw(Torbit mutableGround, in GameState state = null) const
{
    super.draw(mutableGround);
    drawGameExtras(mutableGround, state);
}

final void drawLookup(Phymap lk) const
{
    assert (tile);
    Phybitset phyb = 0;
    final switch (tile.type) {
        case GadType.HATCH:
        case GadType.DECO:
        case GadType.MAX: return;

        case GadType.GOAL:   phyb = Phybit.goal; break;
        case GadType.TRAP:   phyb = Phybit.trap; break;
        case GadType.WATER:  phyb = tile.subtype == 0 ? Phybit.water
                                                       : Phybit.fire; break;
        case GadType.FLING:  phyb = Phybit.fling; break;
    }
    lk.rect!(Phymap.add)(x + tile.triggerX, y + tile.triggerY,
                             tile.triggerXl,    tile.triggerYl, phyb);
}

}
// end class Gadget
