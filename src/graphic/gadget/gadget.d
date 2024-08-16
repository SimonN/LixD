module graphic.gadget.gadget;

/*
 * A Gadget behaves like an object of class Graphic that was created from
 * a Tile, not merely from any Cutbit. Terrain or steel is not a Gadget;
 * those are drawn onto the land and their Tile nature is then forgotten.
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

public alias Water = Gadget;
public alias Fire = Gadget;
public alias Steam = Gadget;

package immutable string StandardGadgetCtor =
    "this(const(Topology) top, in GadOcc levelpos)
    {
        super(top, levelpos);
    }";

class Gadget {
private:
    Graphic _graphic;

public:
    const(GadgetTile) tile;

protected:
    // protected, use the factory to generate gadgets of the correct subclass
    this(const(Topology) top, in GadOcc levelpos)
    in {
        assert (levelpos.tile, "we shouldn't make gadgets from missing tiles");
        assert (levelpos.tile.cb, "we shouldn't make gadgets from bad tiles");
    }
    do {
        _graphic = new Graphic(levelpos.tile.cb, top, levelpos.loc);
        tile = levelpos.tile;
    }

public:
    static Gadget
    factory(const(Topology) top, in GadOcc levelpos)
    {
        assert (levelpos.tile);
        final switch (levelpos.tile.type) {
            case GadType.hatch: return new Hatch(top, levelpos);
            case GadType.goal: return new Goal(top, levelpos);
            case GadType.muncher: return new Muncher(top, levelpos);
            case GadType.water: return new Water(top, levelpos);
            case GadType.fire: return new Fire(top, levelpos);
            case GadType.catapult: return new Catapult(top, levelpos);
            case GadType.steam: return new Steam(top, levelpos);
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
    do {
        _graphic = rhs._graphic.clone;
        tile = rhs.tile;
    }

    final const pure nothrow @safe @nogc {
        Point loc() { return _graphic.loc; }
        Rect rect() { return _graphic.rect; }
        int xl() { return _graphic.xl; }
        int yl() { return _graphic.yl; }
        int frames() { return max(1, _graphic.xfs * _graphic.yfs); }
    }

    final void draw(in Phyu now, in Style treatSpecially) const
    {
        if (frames <= 1) {
            _graphic.drawSpecificFrame(Point(0, 0));
        }
        else {
            const fra = frame(now);
            if (fra.forceSecondRow) {
                _graphic.drawSpecificFrame(Point(fra.frame, 1));
            }
            else if (_graphic.yfs == 1) {
                _graphic.drawSpecificFrame(Point(fra.frame, 0));
            }
            else {
                assert (_graphic.xfs >= 1, "We must compute modulo");
                _graphic.drawSpecificFrame(Point(
                    fra.frame % _graphic.xfs,
                    fra.frame / _graphic.xfs));
            }
        }
        onDraw(now, treatSpecially);
    }

    // For semi-transparent goal markers in multiplayer.
    void drawExtrasOnTopOfLand(in Style st) const { }

    final void drawLookup(Phymap lk) const
    {
        assert (tile);
        Phybitset phyb = 0;
        final switch (tile.type) {
            case GadType.hatch:
            case GadType.MAX: return;

            case GadType.goal: phyb = Phybit.goal; break;
            case GadType.muncher: phyb = Phybit.muncher; break;
            case GadType.water: phyb = Phybit.water; break;
            case GadType.fire: phyb = Phybit.fire; break;
            case GadType.catapult: phyb = Phybit.catapult; break;
            case GadType.steam: phyb = Phybit.steam; break;
        }
        lk.rect!(Phymap.add)(tile.triggerArea + this.loc, phyb);
    }

protected:
    static struct Frame {
        /*
         * frame: It means the graphic's xf normally. But some graphics are
         * in a column, e.g., Amanda's tar. Class Gadget may interpret (frame)
         * as yf in such a case, see draw(). But subclasses shouldn't worry.
         */
        int frame;
        bool forceSecondRow; // For triggered traps
    }

    /*
     * Customization points for class Gadget's draw() template method pattern:
     *
     * frame: Via this, the subclass must report to base class Gadget
     * which frame (xf, yf) they want to paint, given the current tick.
     *
     * onDraw: Optionally, the subclass may draw some after the base has drawn.
     */
    Frame frame(in Phyu now) const pure nothrow @safe @nogc
    {
        return Gadget.Frame(positiveMod(now, frames));
    }

    void onDraw(in Phyu now, in Style treatSpecially) const { }
}
// end class Gadget
