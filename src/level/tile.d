module level.tile;

/* Tile was named Object in C++/A4 Lix. Object is not only the base class
 * in D that gets inherited by all classes, but it's a horrible name for
 * a class in general. Tile is a splendid name for this.
 *
 * A Tile owns its very own Cutbit. When the Tile is destroyed, the Cutbit
 * is also destroyed.
 */

import std.algorithm; // max

import basics.alleg5; // bitmap locking
import basics.globals;
import file.filename;
import file.io;
import graphic.color;
import graphic.cutbit;
import hardware.sound;

enum TileType {
    EMPTY,
    TERRAIN, // subtype 1 = steel
    DECO,    // subtype 1 = flying flag, not wanted in networked games
    HATCH,
    GOAL,
    TRAP,
    WATER,   // subtype 1 = fire
    ONEWAY,  // subtype 1 = pointing right instead of left
    FLING,	 // subtype & 1 = always same xdir, subtype & 2 = non-constant
    TRAMPOLINE,
    MAX
}

class Tile {

public:

    Cutbit cb;

    TileType type;
    int  subtype;

    int  selbox_x;  // These coordinates locate the smallest rectangle inside
    int  selbox_y;  // the object's cutbit's frame (0, 0) that still holds all
    int  selbox_xl; // nontransparent pixels. This refines the selection
    int  selbox_yl; // with a pulled selection rectangle in the Editor.

    int  trigger_x;
    int  trigger_y;
    int  trigger_xl;
    int  trigger_yl;
    bool trigger_xc; // center around trigger_x instead of going right from it
    bool trigger_yc; // center around trigger_y instead of going down from it

    // these are not used for everything
    int  special_x; // FLING: x-direction, HATCH: start of opening anim
    int  special_y; // FLING: y-direction

    Sound sound;

    ////////////////
    // Funktionen //
    ////////////////

    // named constructor
    static Tile take_over_cutbit(Cutbit, TileType = TileType.EMPTY, int = 0);

    ~this() {
        if (cb) destroy(cb);
        cb = null;
    }

    void read_definitions_file(in Filename);

    // these do automatically the calculation of the absolute trigger location
    int get_trigger_x() const { return trigger_x - trigger_xc * trigger_xl/2; }
    int get_trigger_y() const { return trigger_y - trigger_yc * trigger_yl/2; }

    // Reorders TERRAIN = 0, HATCH = 1, ... into the correct display order
    // for the editor, gameplay, or level image dumper
    static TileType perm(in int);

private:

    this() { }



public:

static Tile take_over_cutbit(
    Cutbit    _cb,
    TileType  _type = TileType.EMPTY,
    int       _subtype = 0
) {
    if (_cb is null) return null;
    Tile new_tile = new Tile();

    with (new_tile) {
        cb       = _cb;
        type     = _type;
        subtype  = _subtype;

        selbox_x = cb.get_xl(); // Initializing the selbox with the smallest
        selbox_y = cb.get_yl(); // selbox possible, starting at the wrong ends
    }
    new_tile.set_nice_defaults_based_on_type();
    new_tile.determine_selection_box();

    return new_tile;
}



private void set_nice_defaults_based_on_type()
{
    switch (type) {
    case TileType.HATCH:
        trigger_x  = cb.get_xl() / 2;
        trigger_y  = std.algorithm.max(20, cb.get_yl() - 24);
        special_x  = 1;
        break;
    case TileType.GOAL:
        trigger_x  = cb.get_xl() / 2;
        trigger_y  = cb.get_yl() - 2;
        trigger_xl = 12;
        trigger_yl = 12;
        trigger_xc = true;
        trigger_yc = true;
        break;
    case TileType.TRAP:
        trigger_x  = cb.get_xl() / 2;
        trigger_y  = cb.get_yl() * 4 / 5;
        trigger_xl = 4; // _xl was 6 before July 2014, but 6 is not symmetric
        trigger_yl = 6; // on a piece with width 16 and (lix-xl % 2 == 0)
        trigger_xc = true;
        trigger_yc = true;
        sound      = Sound.SPLAT;
        break;
    case TileType.WATER:
        trigger_x  = 0;
        trigger_y  = 20;
        trigger_xl = cb.get_xl();
        trigger_yl = cb.get_yl() - 20;
        if (subtype) {
            // then it's fire, not water
            trigger_y  = 0;
            trigger_yl = cb.get_yl();
        }
        break;
    default:
        break;
    }
}



private void determine_selection_box()
{
    assert (cb);
    AlBit albit = cb.get_albit();
    mixin(temp_lock!"albit");

    for  (int xf = 0; xf < cb.get_x_frames(); ++xf)
     for (int yf = 0; yf < cb.get_y_frames(); ++yf) {
        int  x_min = -1;
        int  x_max = cb.get_xl();
        int  y_min = -1;
        int  y_max = cb.get_yl();

        WHILE_X_MAX: while (x_max >= 0) {
            x_max -= 1;
            for (int y = 0; y < cb.get_yl(); y += 1)
             if (cb.get_pixel(xf, yf, x_max, y) != color.transp)
             break WHILE_X_MAX;
        }
        WHILE_X_MIN: while (x_min < x_max) {
            x_min += 1;
            for (int y = 0; y < cb.get_yl(); y += 1)
             if (cb.get_pixel(xf, yf, x_min, y) != color.transp)
             break WHILE_X_MIN;
        }
        WHILE_Y_MAX: while (y_max >= 0) {
            y_max -= 1;
            for (int x = 0; x < cb.get_xl(); x += 1)
             if (cb.get_pixel(xf, yf, x, y_max) != color.transp)
             break WHILE_Y_MAX;
        }
        WHILE_Y_MIN: while (y_min < y_max) {
            y_min += 1;
            for (int x = 0; x < cb.get_xl(); x += 1)
             if (cb.get_pixel(xf, yf, x, y_min) != color.transp)
             break WHILE_Y_MIN;
        }
        selbox_x  = min(selbox_x, x_min);
        selbox_y  = min(selbox_y, y_min);
        selbox_xl = max(selbox_xl, x_max - x_min + 1);
        selbox_yl = max(selbox_yl, y_max - y_min + 1);
    }
}



void read_definitions_file(in Filename filename)
{
    // We assume that the object's xl, yl, type, and subtype
    // have been correctly set by the constructor.
    IoLine[] lines = fill_vector_from_file_nothrow(filename);

    foreach (i; lines) if (i.type == '#') {
        if      (i.text1 == objdef_ta_absolute_x) {
            trigger_x = i.nr1;
            trigger_xc = false;
        }
        else if (i.text1 == objdef_ta_absolute_y) {
            trigger_y = i.nr1;
            trigger_yc = false;
        }
        else if (i.text1 == objdef_ta_from_center_x) {
            trigger_x = cb.get_xl() / 2 + i.nr1;
            trigger_xc = true;
        }
        else if (i.text1 == objdef_ta_from_center_y) {
            trigger_y = cb.get_yl() / 2 + i.nr1;
            trigger_yc = true;
        }
        else if (i.text1 == objdef_ta_from_bottom_y) {
            trigger_y = cb.get_yl() - 2 + i.nr1;
            trigger_yc = true;
        }
        else if (i.text1 == objdef_ta_xl) {
            trigger_xl = i.nr1;
            if (trigger_xl < 0) trigger_xl = 0;
        }
        else if (i.text1 == objdef_ta_yl) {
            trigger_yl = i.nr1;
            if (trigger_yl < 0) trigger_yl = 0;
        }
        else if (i.text1 == objdef_hatch_opening_frame) {
            type = TileType.HATCH;
            special_x = i.nr1;
        }
        else if (i.text1 == objdef_fling_nonpermanent) {
            type = TileType.FLING;
            subtype |= 2; // bit 1 nonpermanent trap
        }
        else if (i.text1 == objdef_fling_ignore_orient) {
            type = TileType.FLING;
            subtype |= 1; // bit 0 signifies fixed direction
        }
        else if (i.text1 == objdef_fling_x) {
            type = TileType.FLING;
            special_x = i.nr1;
        }
        else if (i.text1 == objdef_fling_y) {
            type = TileType.FLING;
            special_y = i.nr1;
        }
        else if (i.text1 == objdef_type_trampoline) {
            type = TileType.TRAMPOLINE;
        }
    }
    // end foreach
}




TileType perm(in int n)
{
    // don't start with 0 because most classes start with TERRAIN, not EMPTY.
    return n == 1 ? TileType.HATCH
     :     n == 2 ? TileType.GOAL
     :     n == 3 ? TileType.DECO
     :     n == 4 ? TileType.TRAP
     :     n == 5 ? TileType.WATER
     :     n == 6 ? TileType.FLING
     :     n == 7 ? TileType.TRAMPOLINE
     :     n == 8 ? TileType.TERRAIN
     //:   n == 9 ? TileType.ONEWAY
     :              TileType.EMPTY; // I don't know a proper list
}


}
// end class Tile
