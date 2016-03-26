module tile.gadtile;

/* Tile was named Object in C++/A4 Lix. Object is not only the base class
 * in D that gets inherited by all classes, but it's a horrible name for
 * a class in general. Tile is a splendid name for this.
 *
 * A Tile owns its very own Cutbit. When the Tile is destroyed, the Cutbit
 * is also destroyed.
 */

import basics.alleg5; // bitmap locking
import basics.globals;
import basics.rect;
import file.filename;
import file.io;
import graphic.cutbit;
import hardware.sound;
import tile.platonic;

alias GadType = GadgetTile.Type;

class GadgetTile : Platonic {
private:
    Type _type;

    int  _triggerX;  // raw data, can be center or left
    int  _triggerY;  // raw data, can be center or top
    bool _triggerXc; // center around triggerX instead of going right from it
    bool _triggerYc; // center around triggerY instead of going down from it

public:
    int  subtype;
    int  triggerXl;
    int  triggerYl;

    // these are not used for everything
    int  specialX; // FLING: x-direction, HATCH: start of opening anim
    int  specialY; // FLING: y-direction

    Sound sound;

    enum Type {
        HATCH,
        GOAL,
        DECO,    // subtype 1 = flying flag, not wanted in networked games
        TRAP,
        WATER,   // subtype 1 = fire
        FLING,	 // subtype & 1 = always same xdir, subtype & 2 = non-constant
        MAX
    }

protected:
    this(
        Cutbit aCb,
        Type   aType,
        int    aSubtype,
    ) {
        super(aCb); // take ownership
        _type   = aType;
        subtype = aSubtype;
        set_nice_defaults_based_on_type();
        with (LockReadOnly(cb.albit)) {
            findSelboxAssumeLocked();
        }
    }

public:
    @property type() const { return _type; }

    // phase out these two eventually, replace by Rect/Point below
    @property int triggerX() const { return _triggerX - _triggerXc * triggerXl/2; }
    @property int triggerY() const { return _triggerY - _triggerYc * triggerYl/2; }

    @property Point trigger()     const { return Point(triggerX, triggerY); }
    @property Rect  triggerArea() const
    {
        return Rect(triggerX, triggerY, triggerXl, triggerYl);
    }

    static typeof(this) takeOverCutbit(
        Cutbit aCb,
        Type   aType = Type.DECO,
        int    aSubtype = 0
    ) {
        if (! aCb || ! aCb.valid)
            return null;
        return new typeof(this)(aCb, aType, aSubtype);
    }

    void readDefinitionsFile(in Filename filename)
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
                _type = Type.HATCH;
                specialX = i.nr1;
            }
            else if (i.text1 == tileDefFlingNonpermanent) {
                _type = Type.FLING;
                subtype |= 2; // bit 1 nonpermanent trap
            }
            else if (i.text1 == tileDefFlingIgnoreOrientation) {
                _type = Type.FLING;
                subtype |= 1; // bit 0 signifies fixed direction
            }
            else if (i.text1 == tileDefFlingX) {
                _type = Type.FLING;
                specialX = i.nr1;
            }
            else if (i.text1 == tileDefFlingY) {
                _type = Type.FLING;
                specialY = i.nr1;
            }
        }
    }
    // end read_definitions_file

private:
    void set_nice_defaults_based_on_type()
    {
        assert (cb);
        switch (type) {
        case Type.HATCH:
            _triggerX = cb.xl / 2;
            _triggerY = std.algorithm.max(20, cb.yl - 24);
            specialX  = 1;
            break;
        case Type.GOAL:
            _triggerX = cb.xl / 2;
            _triggerY = cb.yl - 2;
            triggerXl = 12;
            triggerYl = 12;
            _triggerXc = true;
            _triggerYc = true;
            break;
        case Type.TRAP:
            _triggerX = cb.xl / 2;
            _triggerY = cb.yl * 4 / 5;
            triggerXl = 4; // _xl was 6 before July 2014, but 6 isn't symmetric
            triggerYl = 6; // on a piece with width 16 and (lix-xl % 2 == 0)
            _triggerXc = true;
            _triggerYc = true;
            sound      = Sound.SPLAT;
            break;
        case Type.WATER:
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
}
// end class GadgetTile
