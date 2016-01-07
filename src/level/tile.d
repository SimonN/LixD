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
    FLING,	 // subtype & 1 = always same xdir, subtype & 2 = non-constant
    TRAMPO,
    MAX
}

class Tile {

public:

    Cutbit cb;

    TileType type;
    int  subtype;

    int  selboxX;  // These coordinates locate the smallest rectangle inside
    int  selboxY;  // the object's cutbit's frame (0, 0) that still holds all
    int  selboxXl; // nontransparent pixels. This refines the selection
    int  selboxYl; // with a pulled selection rectangle in the Editor.

    @property int triggerX() const
    {
        return _triggerX - _triggerXc * triggerXl/2;
    }

    @property int triggerY() const
    {
        return _triggerY - _triggerYc * triggerYl/2;
    }

    int  triggerXl;
    int  triggerYl;

    // these are not used for everything
    int  specialX; // FLING: x-direction, HATCH: start of opening anim
    int  specialY; // FLING: y-direction

    Sound sound;

    // named constructor
    static Tile takeOverCutbit(Cutbit, TileType = TileType.EMPTY, int = 0);

    ~this() {
        if (cb) destroy(cb);
        cb = null;
    }

    void read_definitions_file(in Filename);

    // Reorders TERRAIN = 0, HATCH = 1, ... into the correct display order
    // for the editor, gameplay, or level image dumper
    static TileType perm(in int);

private:

    int  _triggerX;  // raw data, can be center or left
    int  _triggerY;  // raw data, can be center or top
    bool _triggerXc; // center around triggerX instead of going right from it
    bool _triggerYc; // center around triggerY instead of going down from it

    this() { }



public:

static Tile takeOverCutbit(
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

        selboxX = cb.xl; // Initializing the selbox with the smallest
        selboxY = cb.yl; // selbox possible, starting at the wrong ends
    }
    new_tile.set_nice_defaults_based_on_type();
    new_tile.determine_selection_box();

    return new_tile;
}



private void set_nice_defaults_based_on_type()
{
    switch (type) {
    case TileType.HATCH:
        _triggerX = cb.xl / 2;
        _triggerY = std.algorithm.max(20, cb.yl - 24);
        specialX  = 1;
        break;
    case TileType.GOAL:
        _triggerX = cb.xl / 2;
        _triggerY = cb.yl - 2;
        triggerXl = 12;
        triggerYl = 12;
        _triggerXc = true;
        _triggerYc = true;
        break;
    case TileType.TRAP:
        _triggerX = cb.xl / 2;
        _triggerY = cb.yl * 4 / 5;
        triggerXl = 4; // _xl was 6 before July 2014, but 6 is not symmetric
        triggerYl = 6; // on a piece with width 16 and (lix-xl % 2 == 0)
        _triggerXc = true;
        _triggerYc = true;
        sound      = Sound.SPLAT;
        break;
    case TileType.WATER:
        _triggerX = 0;
        _triggerY = 20;
        triggerXl = cb.xl;
        triggerYl = cb.yl - 20;
        if (subtype) {
            // then it's fire, not water
            _triggerY = 0;
            triggerYl = cb.yl;
        }
        break;
    default:
        break;
    }
}



private void determine_selection_box()
{
    assert (cb);
    auto lock = LockReadOnly(cb.albit);

    for  (int xf = 0; xf < cb.xfs; ++xf)
     for (int yf = 0; yf < cb.yfs; ++yf) {
        int  xMin = -1;
        int  xMax = cb.xl;
        int  yMin = -1;
        int  yMax = cb.yl;

        WHILE_X_MAX: while (xMax >= 0) {
            xMax -= 1;
            for (int y = 0; y < cb.yl; y += 1)
             if (cb.get_pixel(xf, yf, xMax, y) != color.transp)
             break WHILE_X_MAX;
        }
        WHILE_X_MIN: while (xMin < xMax) {
            xMin += 1;
            for (int y = 0; y < cb.yl; y += 1)
             if (cb.get_pixel(xf, yf, xMin, y) != color.transp)
             break WHILE_X_MIN;
        }
        WHILE_Y_MAX: while (yMax >= 0) {
            yMax -= 1;
            for (int x = 0; x < cb.xl; x += 1)
             if (cb.get_pixel(xf, yf, x, yMax) != color.transp)
             break WHILE_Y_MAX;
        }
        WHILE_Y_MIN: while (yMin < yMax) {
            yMin += 1;
            for (int x = 0; x < cb.xl; x += 1)
             if (cb.get_pixel(xf, yf, x, yMin) != color.transp)
             break WHILE_Y_MIN;
        }
        selboxX  = min(selboxX,  xMin);
        selboxY  = min(selboxY,  yMin);
        selboxXl = max(selboxXl, xMax - xMin + 1);
        selboxYl = max(selboxYl, yMax - yMin + 1);
    }
}



void read_definitions_file(in Filename filename)
{
    // We assume that the object's xl, yl, type, and subtype
    // have been correctly set by the constructor.
    IoLine[] lines = fillVectorFromFileNothrow(filename);

    foreach (i; lines) if (i.type == '#') {
        if      (i.text1 == tileDefTAAbsoluteX) {
            _triggerX = i.nr1;
            _triggerXc = false;
        }
        else if (i.text1 == tileDefTAAbsoluteY) {
            _triggerY = i.nr1;
            _triggerYc = false;
        }
        else if (i.text1 == tileDefTAFromCenterX) {
            _triggerX = cb.xl / 2 + i.nr1;
            _triggerXc = true;
        }
        else if (i.text1 == tileDefTAFromCenterY) {
            _triggerY = cb.yl / 2 + i.nr1;
            _triggerYc = true;
        }
        else if (i.text1 == tileDefTAFromBottomY) {
            _triggerY = cb.yl - 2 + i.nr1;
            _triggerYc = true;
        }
        else if (i.text1 == tileDefTAXl) {
            triggerXl = i.nr1;
            if (triggerXl < 0) triggerXl = 0;
        }
        else if (i.text1 == tileDefTAYl) {
            triggerYl = i.nr1;
            if (triggerYl < 0) triggerYl = 0;
        }
        else if (i.text1 == tileDefHatchOpeningFrame) {
            type = TileType.HATCH;
            specialX = i.nr1;
        }
        else if (i.text1 == tileDefFlingNonpermanent) {
            type = TileType.FLING;
            subtype |= 2; // bit 1 nonpermanent trap
        }
        else if (i.text1 == tileDefFlingIgnoreOrientation) {
            type = TileType.FLING;
            subtype |= 1; // bit 0 signifies fixed direction
        }
        else if (i.text1 == tileDefFlingX) {
            type = TileType.FLING;
            specialX = i.nr1;
        }
        else if (i.text1 == tileDefFlingY) {
            type = TileType.FLING;
            specialY = i.nr1;
        }
        else if (i.text1 == tileDefTypeTrampoline) {
            type = TileType.TRAMPO;
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
     :     n == 7 ? TileType.TRAMPO
     :     n == 8 ? TileType.TERRAIN
     :              TileType.EMPTY; // I don't know a proper list
}


}
// end class Tile
