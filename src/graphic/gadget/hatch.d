module graphic.gadget.hatch;

import basics.globals; // hatch arrow graphic
import graphic.cutbit;
import graphic.gadget;
import graphic.gralib;
import graphic.torbit;
import level.level;
import level.tile;

class Hatch : Gadget {

public:

    bool spawn_facing_left;

    this(Torbit tb, const(Tile) ti, int x = 0, int y = 0)
    {
        super(tb, ti, x, y);
    }

    this(Torbit tb, in ref Pos levelpos)
    {
        super(tb, levelpos);
        rotation = levelpos.rot;
    }

    this(Hatch rhs)
    {
        assert (rhs);
        super(rhs);
        spawn_facing_left = rhs.spawn_facing_left;
    }

    // for a hatch, rotation means "spawn lix facing left", not "rotate cutbit"
    @property override int xl() const { return tile.cb.xl; }
    @property override int yl() const { return tile.cb.yl; }

    override void animate()
    {
        // animate normally at first, but don't loop
        if (! is_last_frame())
            super.animate();
    }

    override void draw_info()
    {
        // draw arrow pointing into the hatch's direction
        const(Cutbit) cb = get_internal(file_bitmap_edit_hatch);
        cb.draw(ground, x + yl/2 - cb.xl/2,
                        y + 20, // DTODO: +20 was ::text_height in A4/C++.
                        rotation ? 1 : 0, 0);
    }


}
// end class Hatch
