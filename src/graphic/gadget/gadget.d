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

import game.lookup;
import graphic.cutbit;
import graphic.color;
import graphic.graphic;
import graphic.gadget;
import graphic.torbit;
import level.level;
import level.tile;

class Gadget : Graphic {

public:

    const(Tile) tile;
    bool        draw_with_editor_info;

    // override these if necessary
    protected void draw_game_extras() { }
    protected void draw_editor_info() { }

    // hatch should override this
    Pos to_pos() const { return Pos(tile, x, y); }

/*  static Gadget factory(Torbit, const(Tile), int x = 0, int y = 0);
 *  static Gadget factory(Torbit, in ref level.level.Pos);
 *  static Gadget this(Gadget);
 *
 *  @property int selbox_x()  const;
 *  @property int selbox_y()  const;
 *  @property int selbox_xl() const;
 *  @property int selbox_yl() const;
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
    draw_with_editor_info = rhs.draw_with_editor_info;
}



static Gadget
factory(Torbit tb, in ref Pos levelpos)
{
    assert (levelpos.ob);
    switch (levelpos.ob.type) {
        case TileType.HATCH: return new Hatch (tb, levelpos);
        case TileType.GOAL:  return new Goal  (tb, levelpos);
        default:             return new Gadget(tb, levelpos);
    }
}



void
animate()
{
    if (is_last_frame())
        xf = 0;
    else
        xf = xf + 1;
    // Traps won't be animated all the time by the Game class, so we don't have
    // to check for anything here.
}



// Most gadgets can't be rotated or mirrored. Even hatches have a separate
// field for that now. However, editor terrain is still realized with a
// base Gadget instantiation.

@property int
selbox_x() const
{
    int edge = rotation.to!int;
    if (mirror)
        edge = (edge == 1 ? 3 : edge == 3 ? 1 : edge);
    switch (edge) {
        case 0: return tile.selbox_x; // rotation is clockwise
        case 1: return tile.cb.yl - tile.selbox_y - tile.selbox_yl;
        case 2: return tile.cb.xl - tile.selbox_x - tile.selbox_xl;
        case 3: return tile.selbox_y;
        default: assert (false);
    }
}



@property int
selbox_y() const
{
    int edge = rotation.to!int;
    if (mirror)
        edge = (edge == 0 ? 2 : edge == 2 ? 0 : edge);
    switch (edge) {
        case 0: return tile.selbox_y;
        case 1: return tile.selbox_x;
        case 2: return tile.cb.yl - tile.selbox_y - tile.selbox_yl;
        case 3: return tile.cb.xl - tile.selbox_x - tile.selbox_xl;
        default: assert (false);
    }
}



@property int
selbox_xl() const
{
    if (rotation.to!int % 2 == 1) return tile.selbox_yl;
    else                          return tile.selbox_xl;
}



@property int
get_selbox_yl() const
{
    if (rotation.to!int % 2 == 1) return tile.selbox_xl;
    else                          return tile.selbox_yl;
}



final override void
draw()
{
    super.draw();

    draw_game_extras();

    if (draw_with_editor_info) {
        draw_editor_info();

        // now draw trigger area on top
        if (tile.type == TileType.GOAL
         || tile.type == TileType.HATCH
         || tile.type == TileType.TRAP
         || tile.type == TileType.WATER
         || tile.type == TileType.FLING
         || tile.type == TileType.TRAMPOLINE
        )
            ground.draw_rectangle(x + tile.trigger_x,
                                  y + tile.trigger_y,
                                  tile.trigger_xl, tile.trigger_yl,
                                  color.makecol(0x40, 0xFF, 0xFF));
    }
}



final void draw_lookup(Lookup lk)
{
    assert (tile);
    Lookup.LoNr nr = 0;
    switch (tile.type) {
        case TileType.GOAL:       nr = Lookup.bit_goal; break;
        case TileType.TRAP:       nr = Lookup.bit_trap; break;
        case TileType.WATER:      nr = tile.subtype == 0
                                     ? Lookup.bit_water
                                     : Lookup.bit_fire; break;
        case TileType.FLING:      nr = Lookup.bit_fling; break;
        case TileType.TRAMPOLINE: nr = Lookup.bit_trampoline; break;
        default: break;
    }
    lk.add_rectangle(x + tile.trigger_x,
                     y + tile.trigger_y,
                     tile.trigger_xl,
                     tile.trigger_yl, nr);
}

}
// end class Gadget
