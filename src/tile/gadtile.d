module tile.gadtile;

/* Specialization of AbstractTile for hatches, goals, traps, etc.
 * As with AbstractTile, if you have 4 hatches in a level that all look alike,
 * you have 4 GadOccs (gadget occurrences), but only 1 AbstractTile.
 */

import std.algorithm;

import basics.alleg5; // bitmap locking
import basics.globals;
import basics.rect;
import file.filename;
import file.io;
import file.log;
import graphic.cutbit;
import hardware.sound;
import tile.abstile;

alias GadType = GadgetTile.Type;

class GadgetTile : AbstractTile {
private:
    Type _type;

    int  _triggerX;  // raw data, can be center or left
    int  _triggerY;  // raw data, can be center or top
    bool _triggerXc; // center around triggerX instead of going right from it
    bool _triggerYc; // center around triggerY instead of going down from it
    immutable string _name;

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
        TRAP,
        WATER,   // subtype 1 = fire
        FLING,	 // subtype & 1 = always same xdir, subtype & 2 = non-constant
        MAX
    }

protected:
    this(
        string aName,
        Cutbit aCb,
        Type   aType,
        int    aSubtype,
    ) {
        super(aCb); // take ownership
        _name   = aName;
        _type   = aType;
        subtype = aSubtype;
        set_nice_defaults_based_on_type();
        with (LockReadOnly(cb.albit)) {
            findSelboxAssumeLocked();
        }
    }

public:
    @property type() const { return _type; }
    override @property string name() const { return _name; }

    // phase out these two eventually, replace by Rect/Point below
    @property int triggerX() const { return _triggerX - _triggerXc * triggerXl/2; }
    @property int triggerY() const { return _triggerY - _triggerYc * triggerYl/2; }

    @property Point trigger()     const { return Point(triggerX, triggerY); }
    @property Rect  triggerArea() const
    {
        return Rect(triggerX, triggerY, triggerXl, triggerYl);
    }

    static typeof(this) takeOverCutbit(
        string aName,
        Cutbit aCb,
        Type   aType,
        int    aSubtype = 0
    ) {
        if (! aCb || ! aCb.valid)
            return null;
        return new typeof(this)(aName, aCb, aType, aSubtype);
    }

    void readDefinitionsFile(in Filename filename)
    {
        // We assume that the object's xl, yl, type, and subtype
        // have been correctly set by the constructor.
        IoLine[] lines;
        try {
            lines = fillVectorFromFile(filename);
        }
        catch (Exception e) {
            logf("Error reading gadget definitions `%s':", filename.rootless);
            logf("    -> %s", e.msg);
            logf("    -> Falling back to default gadget properties.");
            return;
        }
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
            _triggerY = max(20, cb.yl - 24);
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
