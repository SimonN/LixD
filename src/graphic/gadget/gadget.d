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

import std.algorithm;
import std.conv;

import basics.help;
import net.repdata;
import basics.topology;
import graphic.cutbit;
import graphic.color;
import graphic.graphic;
import graphic.gadget;
import graphic.torbit;
import tile.phymap;
import tile.occur;
import tile.gadtile;
import net.style; // dubious, but I need it for fat interface antipattern

public alias Water     = Gadget;
public alias Fire      = Gadget;
public alias FlingPerm = Gadget;

package immutable string StandardGadgetCtor =
    "this(const(Topology) top, in ref GadOcc levelpos)
    {
        super(top, levelpos);
    }";

class Gadget : Graphic {
public:
    const(GadgetTile) tile;

protected:
    // protected, use the factory to generate gadgets of the correct subclass
    this(const(Topology) top, in ref GadOcc levelpos)
    in {
        assert (levelpos.tile, "we shouldn't make gadgets from missing tiles");
        assert (levelpos.tile.cb, "we shouldn't make gadgets from bad tiles");
    }
    body {
        super(levelpos.tile.cb, top, levelpos.loc);
        tile = levelpos.tile;
    }

public:
    static Gadget
    factory(const(Topology) top, in ref GadOcc levelpos)
    {
        assert (levelpos.tile);
        final switch (levelpos.tile.type) {
            case GadType.HATCH:   return new Hatch   (top, levelpos);
            case GadType.GOAL:    return new Goal    (top, levelpos);
            case GadType.TRAP:    return new TrapTrig(top, levelpos);
            case GadType.WATER:   return new Water   (top, levelpos);
            case GadType.FLINGTRIG: return new FlingTrig(top, levelpos);
            case GadType.FLINGPERM: return new FlingPerm(top, levelpos);
            case GadType.MAX:
                assert (false, "GadType isn't supported by Gadget.factory");
        }
    }

    override Gadget clone() const { return new Gadget(this); }
    this(in Gadget rhs)
    in {
        assert (rhs !is null, "we shouldn't copy from null rhs");
        assert (rhs.tile !is null, "don't copy from rhs with missing tile");
    }
    body {
        super(rhs);
        tile = rhs.tile;
    }

    void animateForPhyu(in Phyu upd)
    {
        // Most graphics have only one animation. This can be in a row,
        // in column, or in a rectangular sheet. We traverse a rectangular
        // sheet row-majorly, like we read a western book.
        // The rectangular sheet solves github issues #4 and #213 about
        // graphics card limitation with Amanda's tar.
        xf = positiveMod(upd, xfs);
        yf = positiveMod(upd / xfs, yfs);
    }

    protected void drawInner() const { } // override if necessary
    final override void draw() const
    {
        super.draw();
        drawInner();
    }

    // For semi-transparent goal markers in multiplayer.
    void drawExtrasOnTopOfLand(in Style st) const { }

    final void drawLookup(Phymap lk) const
    {
        assert (tile);
        Phybitset phyb = 0;
        final switch (tile.type) {
            case GadType.HATCH:
            case GadType.MAX: return;

            case GadType.GOAL:  phyb = Phybit.goal; break;
            case GadType.TRAP:  phyb = Phybit.trap; break;
            case GadType.WATER: phyb = tile.subtype == 0 ? Phybit.water
                                                         : Phybit.fire; break;
            case GadType.FLINGTRIG: phyb = Phybit.fling; break;
            case GadType.FLINGPERM: phyb = Phybit.fling; break;
        }
        lk.rect!(Phymap.add)(tile.triggerArea + this.loc, phyb);
    }
}
// end class Gadget
