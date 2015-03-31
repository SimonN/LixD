module level.graset;

/* Right now, this is only an interface used by module level.tilelib.
 * Porting L1 and L2 graphics loading to D/A5 Lix will be done much later.
 */

import basics.help; // clear_array
import level.tile;

class GraphicSet {

public:

    const(Tile) get_terrain(int) const { assert (false, "DTODOORIG: impl"); }
    const(Tile) get_special(int) const { assert (false, "DTODOORIG: impl"); }
    int         get_terrain_id(in Tile) const { assert (false, "DTODOORIG"); }
    int         get_special_id(in Tile) const { assert (false, "DTODOORIG"); }

    // These are useful while creating a graphics set. level.tilelib should
    // provide no or just const access to a graphics set after it's completed.
    void push_back_terrain(Tile ob) { terrain ~= ob; }
    void push_back_special(Tile ob) { special ~= ob; }

    this() { }
    // ~this(); -- exists, see below

private:

    Tile[] terrain;
    Tile[] special;



public:

~this()
{
    clear_array(terrain);
    clear_array(special);
}

}
// end class GraphicSet
