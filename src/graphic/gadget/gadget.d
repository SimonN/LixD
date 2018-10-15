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

import optional;

import basics.help;
import net.repdata;
import basics.topology;
import game.effect;
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

class Gadget {
private:
    Graphic _graphic;
    int _frame; // between 0 incl. and (_graphic.xfs * _graphic.yfs) exclusive

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
        _graphic = new Graphic(levelpos.tile.cb, top, levelpos.loc);
        _frame = 0;
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

    Gadget clone() const { return new Gadget(this); }
    this(in Gadget rhs)
    in {
        assert (rhs !is null, "we shouldn't copy from null rhs");
        assert (rhs._graphic !is null, "don't copy from rhs without graphic");
        assert (rhs.tile !is null, "don't copy from rhs with missing tile");
    }
    body {
        _graphic = rhs._graphic.clone;
        _frame = rhs._frame;
        tile = rhs.tile;
    }

    @property final const pure nothrow @nogc {
        Point loc() { return _graphic.loc; }
        Rect rect() { return _graphic.rect; }
        int xl() { return _graphic.xl; }
        int yl() { return _graphic.yl; }
        int frame() { return _frame; }
    }

    // This affects physics. Call during physics update. It does not draw.
    void perform(in Phyu upd, Optional!EffectManager ef)
    {
        frame = upd;
    }

    protected void onDraw(in Style treatSpecially) const { }
    final void draw(in Style treatSpecially) const
    {
        _graphic.draw();
        onDraw(treatSpecially);
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

protected:
    @property final nothrow @nogc pure {
        // Subclasses should override animateForPhyu instead.
        // Game should call animateForPhyu instead.
        // Most graphics have only one animation. This can be in a row,
        // in column, or in a rectangular sheet. We traverse a rectangular
        // sheet row-majorly, like we read a western book.
        // The rectangular sheet solves github issues #4 and #213 about
        // graphics card limitation with Amanda's tar.
        int frames() const { return max(1, _graphic.xfs * _graphic.yfs); }
        int frame(in int fr)
        {
            _graphic.xf = positiveMod(fr, _graphic.xfs);
            _graphic.yf = positiveMod(fr / _graphic.xfs, _graphic.yfs);
            return _graphic.yf * _graphic.xfs + _graphic.xf;
        }

        // Traps need access to two different rows. Allow to break the
        // abstraction of frame() earlier. >_>
        Point exactXfYf() const { return Point(_graphic.xf, _graphic.yf); }
        Point exactXfYf(Point p)
        {
            _graphic.xf = p.x;
            _graphic.yf = p.y;
            return exactXfYf;
        }
    }
}
// end class Gadget
