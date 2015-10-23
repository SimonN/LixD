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
import game.lookup;
import graphic.cutbit;
import graphic.color;
import graphic.graphic;
import graphic.gadget;
import graphic.torbit;
import level.level;
import level.tile;
import hardware.sound;

package template StandardGadgetCtor()
{
    const char[] StandardGadgetCtor =
        "this(Torbit tb, in ref Pos levelpos) { super(tb, levelpos); }";
}

class Gadget : Graphic {

public:

    const(Tile) tile;
    bool        drawWithEditorInfo;

    // override these if necessary
    protected void drawGameExtras() { }
    protected void drawEditorInfo() { }

    // hatch should override this
    Pos toPos() const { return Pos(tile, x, y); }

    @property Sound sound() { return Sound.NOTHING; }

/*  static Gadget factory(Torbit, const(Tile), int x = 0, int y = 0);
 *  static Gadget factory(Torbit, in ref level.level.Pos);
 *  static Gadget this(Gadget);
 */
    mixin CloneableBase;

/*  @property int selboxX()  const;
 *  @property int selboxY()  const;
 *  @property int selboxXl() const;
 *  @property int selboxYl() const;
 *
 *  void animate();
 *
 *  final void draw();
 *  final void draw_lookup(Lookup);
 */

protected this(Torbit tb, in ref Pos levelpos)
{
    super(levelpos.ob.cb, tb, levelpos.x, levelpos.y);
    tile = levelpos.ob;
}



public:

this(Gadget rhs)
{
    assert (rhs);
    super(rhs);
    tile = rhs.tile;
    drawWithEditorInfo = rhs.drawWithEditorInfo;
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
animate()
{
    // the most basic animation loop
    if (isLastFrame())
        xf = 0;
    else
        xf = xf + 1;
}



// Most gadgets can't be rotated or mirrored. Even hatches have a separate
// field for that now. However, editor terrain is still realized with a
// base Gadget instantiation.

@property int
selboxX() const
{
    int edge = rotation.to!int;
    if (mirror)
        edge = (edge == 1 ? 3 : edge == 3 ? 1 : edge);
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
draw()
{
    super.draw();

    drawGameExtras();

    if (drawWithEditorInfo) {
        drawEditorInfo();

        // now draw trigger area on top
        if (tile.type == TileType.GOAL
         || tile.type == TileType.HATCH
         || tile.type == TileType.TRAP
         || tile.type == TileType.WATER
         || tile.type == TileType.FLING
         || tile.type == TileType.TRAMPOLINE
        )
            ground.drawRectangle(x + tile.triggerX,
                                 y + tile.triggerY,
                                 tile.triggerXl, tile.triggerYl,
                                 color.makecol(0x40, 0xFF, 0xFF));
    }
}



final void draw_lookup(Lookup lk)
{
    assert (tile);
    Lookup.LoNr nr = 0;
    switch (tile.type) {
        case TileType.GOAL:       nr = Lookup.bitGoal; break;
        case TileType.TRAP:       nr = Lookup.bitTrap; break;
        case TileType.WATER:      nr = tile.subtype == 0
                                     ? Lookup.bitWater
                                     : Lookup.bitFire; break;
        case TileType.FLING:      nr = Lookup.bitFling; break;
        case TileType.TRAMPOLINE: nr = Lookup.bitTrampoline; break;
        default: break;
    }
    lk.addRectangle(x + tile.triggerX, y + tile.triggerY,
                        tile.triggerXl,    tile.triggerYl, nr);
}

}
// end class Gadget
