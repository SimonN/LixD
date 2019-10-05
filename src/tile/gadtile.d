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
    bool subtype; // see Type enum for what subtype does
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
        WATER, // subtype true = fire
        FLINGTRIG, // subtype true = always same xdir
        FLINGPERM, // subtype true = always same xdir
        MAX
    }

public:
    static typeof(this) takeOverCutbit(
        string aName,
        Cutbit aCb,
        Type   aType,
        bool   aSubtype,
        const(IoLine)[] linesFromDefFile,
    ) {
        if (! aCb || ! aCb.valid)
            return null;
        return new typeof(this)(aName, aCb, aType, aSubtype, linesFromDefFile);
    }

    @property type() const { return _type; }
    override @property string name() const { return _name; }

    @property Point trigger() const
    {
        return Point(_triggerX - _triggerXc * triggerXl/2,
                     _triggerY - _triggerYc * triggerYl/2);
    }

    @property Rect triggerArea() const
    {
        return Rect(trigger, triggerXl, triggerYl);
    }

protected:
    this(
        string aName,
        Cutbit aCb,
        Type   aType,
        bool   aSubtype,
        const(IoLine)[] linesFromDefFile,
    ) {
        super(aCb); // take ownership
        _name   = aName;
        _type   = aType;
        subtype = aSubtype;
        set_nice_defaults_based_on_type();

        with (LockReadOnly(cb.albit)) {
            findSelboxAssumeLocked();
        }
        readDefinitionsFile(linesFromDefFile);
        adaptFireTriggerAreaToOldBodyRules();
        logAnyErrors();
    }

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


    void readDefinitionsFile(const(IoLine[]) lines)
    {
        // We assume that the object's xl, yl, type, and subtype
        // have been correctly set by the constructor.
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
                _type = Type.FLINGTRIG;
            }
            else if (i.text1 == tileDefFlingIgnoreOrientation) {
                if (_type != Type.FLINGTRIG)
                    _type = Type.FLINGPERM;
                subtype = true; // fixed direction
            }
            else if (i.text1 == tileDefFlingX) {
                if (_type != Type.FLINGTRIG)
                    _type = Type.FLINGPERM;
                specialX = i.nr1;
            }
            else if (i.text1 == tileDefFlingY) {
                if (_type != Type.FLINGTRIG)
                    _type = Type.FLINGPERM;
                specialY = i.nr1;
            }
        }
    }
    // end read_definitions_file

    /*
     * During 0.9, I don't want to touch the trigger area definitions file.
     * Make (fire with foot checks) behave like (fire in 0.9.29 and earlier
     * with body checks).
     * https://www.lemmingsforums.net/index.php?topic=4440
     */
    void adaptFireTriggerAreaToOldBodyRules()
    {
        if (_type != Type.WATER || ! subtype) {
            // This isn't fire.
            return;
        }
        // Downwards-extend trigger area by 12.
        _triggerY += _triggerYc ? 6 : 0;
        triggerYl += 12;
    }

    void logAnyErrors() const
    {
        if (! cb)
            return;
        if ((type == Type.TRAP || type == Type.FLINGTRIG) && cb.yfs != 2) {
            logf("Error: Triggered %s `%s':",
                type == Type.TRAP ? "trap" : "flinger", name);
            logf("    -> Image has %d rows of frames, not 2.", cb.yfs);
        }
    }
}
// end class GadgetTile
