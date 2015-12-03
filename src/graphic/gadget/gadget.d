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
 * DTODO: We're introducing a ton of special cases for TileType.HATCH here.
 * Consider making a subclass for that.
 */

import std.conv;

import basics.help;
import game.phymap;
import graphic.cutbit;
import graphic.color;
import graphic.graphic;
import graphic.gadget;
import graphic.torbit;
import level.level;
import level.tile;
import hardware.sound;

package immutable string StandardGadgetCtor =
    "this(in Torbit tb, in ref Pos levelpos) { super(tb, levelpos); }";



class Gadget : Graphic {

public:

    const(Tile) tile;
    const(int)  animationLength;

    bool        drawWithEditorInfo;

    // override these if necessary
    protected void drawGameExtras(Torbit) const { }
    protected void drawEditorInfo(Torbit) const { }

    // hatch should override this
    Pos toPos() const { return Pos(tile, x, y); }

    @property Sound sound() { return Sound.NOTHING; }

/*  static Gadget factory(in Torbit, in ref level.level.Pos);
 *  static Gadget this(in Gadget);
 */

/*  @property int selboxX()  const;
 *  @property int selboxY()  const;
 *  @property int selboxXl() const;
 *  @property int selboxYl() const;
 *
 *  void animateForUpdate(int update);
 *
 *  final void draw();
 *  final void draw_lookup(Phymap);
 */

// protected: use the factory to generate gadgets of the correct subclass
protected this(in Torbit tb, in ref Pos levelpos)
in {
    assert (levelpos.ob, "we shouldn't make gadgets from missing tiles");
    assert (levelpos.ob.cb, "we shouldn't make gadgets from bad tiles");
}
body {
    super(levelpos.ob.cb, tb, levelpos.x, levelpos.y);
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
factory(Torbit tb, in ref Pos levelpos)
{
    assert (levelpos.ob);
    final switch (levelpos.ob.type) {
        case TileType.TERRAIN:    return new Gadget    (tb, levelpos);
        case TileType.DECO:       return new Gadget    (tb, levelpos);
        case TileType.HATCH:      return new Hatch     (tb, levelpos);
        case TileType.GOAL:       return new Goal      (tb, levelpos);
        case TileType.TRAP:       return new TrapTrig  (tb, levelpos);
        case TileType.WATER:      return new Water     (tb, levelpos);
        case TileType.TRAMPOLINE: return new Trampoline(tb, levelpos);
        case TileType.FLING:
            if (levelpos.ob.subtype & 2) return new FlingTrig(tb, levelpos);
            else                         return new FlingPerm(tb, levelpos);
        case TileType.EMPTY:
        case TileType.MAX:
            assert (false, "TileType isn't supported by Gadget.factory");
    }
}



void
animateForUpdate(in int upd)
{
    xf = positiveMod(upd, animationLength);
}



@property int
selboxX() const
{
    int edge = rotation.to!int;
    if (mirror)
        edge = (edge == 1 ? 3 : edge == 3 ? 1 : edge);

    // Most gadgets can't be rotated or mirrored. Even hatches have a separate
    // field for that now. However, editor terrain is still realized with a
    // base Gadget instantiation.
    assert (tile.type != TileType.TERRAIN || edge == 0,
        "only editor terrain may be rotated and mirrored, not ingame gadgets");

    switch (edge) {
        case 0: return tile.selboxX; // rotation is clockwise
        case 1: return tile.cb.yl - tile.selboxY - tile.selboxYl;
        case 2: return tile.cb.xl - tile.selboxX - tile.selboxXl;
        case 3: return tile.selboxY;
        default: assert (false);
    }
}



@property int
selboxY() const
{
    int edge = rotation.to!int;
    if (mirror)
        edge = (edge == 0 ? 2 : edge == 2 ? 0 : edge);
    assert (tile.type != TileType.TERRAIN || edge == 0,
        "only editor terrain may be rotated and mirrored, not ingame gadgets");
    switch (edge) {
        case 0: return tile.selboxY;
        case 1: return tile.selboxX;
        case 2: return tile.cb.yl - tile.selboxY - tile.selboxYl;
        case 3: return tile.cb.xl - tile.selboxX - tile.selboxXl;
        default: assert (false);
    }
}



@property int
selboxXl() const
{
    if (rotation.to!int % 2 == 1) return tile.selboxYl;
    else                          return tile.selboxXl;
}



@property int
get_selboxYl() const
{
    if (rotation.to!int % 2 == 1) return tile.selboxXl;
    else                          return tile.selboxYl;
}



final override void
draw(Torbit mutableGround) const
{
    super.draw(mutableGround);

    drawGameExtras(mutableGround);

    if (drawWithEditorInfo) {
        drawEditorInfo(mutableGround);

        // now draw trigger area on top
        if (tile.type == TileType.GOAL
         || tile.type == TileType.HATCH
         || tile.type == TileType.TRAP
         || tile.type == TileType.WATER
         || tile.type == TileType.FLING
         || tile.type == TileType.TRAMPOLINE
        )
            mutableGround.drawRectangle(x + tile.triggerX,
                                        y + tile.triggerY,
                                        tile.triggerXl, tile.triggerYl,
                                        color.makecol(0x40, 0xFF, 0xFF));
    }
}



final void draw_lookup(Phymap lk)
{
    assert (tile);
    Phybitset phyb = 0;
    switch (tile.type) {
        case TileType.GOAL:       phyb = Phybit.goal; break;
        case TileType.TRAP:       phyb = Phybit.trap; break;
        case TileType.WATER:      phyb =
                     tile.subtype == 0 ? Phybit.water
                                       : Phybit.fire; break;
        case TileType.FLING:      phyb = Phybit.fling; break;
        case TileType.TRAMPOLINE: phyb = Phybit.trampo; break;
        default: break;
    }
    lk.rect!(Phymap.add)(x + tile.triggerX, y + tile.triggerY,
                             tile.triggerXl,    tile.triggerYl, phyb);
}

}
// end class Gadget
