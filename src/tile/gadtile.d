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
import tile.visitor;

alias GadType = GadgetTile.Type;

class GadgetTile : AbstractTile {
private:
    Type _type;
    immutable string _name;

    int  _triggerX;  // raw data, can be center or left
    int  _triggerY;  // raw data, can be center or top
    bool _triggerXc; // center around triggerX instead of going right from it
    bool _triggerYc; // center around triggerY instead of going down from it

public:
    /*
     * flingForward matters only for Type.steam and Type.catapult.
     *
     * flingForward == true means that the lix always preserves her x-direction
     * as long as specialX is >= 0, which it really should be for flingForward.
     *
     * flingForward == false means that specialX < 0 flings leftward and
     * specialX > 0 flings rightward, regardless of the lix's earlier facing.
     */
    bool flingForward = true;

    int  triggerXl;
    int  triggerYl;

    // these are not used for everything
    int  specialX; // FLING: x-direction, HATCH: start of opening anim
    int  specialY; // FLING: y-direction

    enum Type {
        hatch, // = entrance, entrance hatch, starting point
        goal, // = exit, archway, where you want everybody to go
        muncher, // = triggered trap, nonconstant trap
        water, // = hazard, permanent trap
        fire, // = hazard, permanent trap, laser, buzzsaw
        catapult, // = nonconstant flinger, triggered flinger with cooldown
        steam, // = constant flinger, transportation beam
        MAX
    }

public:
    static typeof(this) takeOverCutbit(
        string aName,
        Cutbit aCb,
        Type   aType,
        const(IoLine)[] linesFromDefFile,
    ) {
        if (! aCb || ! aCb.valid)
            return null;
        return new typeof(this)(aName, aCb, aType, linesFromDefFile);
    }

    Type type() const pure nothrow @safe @nogc { return _type; }
    override string name() const { return _name; }

    override void accept(TileVisitor v) const { v.visit(this); }

    Point trigger() const pure nothrow @safe @nogc
    {
        return Point(_triggerX - _triggerXc * triggerXl/2,
                     _triggerY - _triggerYc * triggerYl/2);
    }

    Rect triggerArea() const pure nothrow @safe @nogc
    {
        return Rect(trigger, triggerXl, triggerYl);
    }

protected:
    this(
        string aName,
        Cutbit aCb,
        Type   aType,
        const(IoLine)[] linesFromDefFile,
    ) {
        super(aCb); // take ownership
        _name   = aName;
        _type   = aType;
        flingForward = true;
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
        case Type.hatch:
            _triggerX = cb.xl / 2;
            _triggerY = max(20, cb.yl - 24);
            specialX  = 1;
            break;
        case Type.goal:
            _triggerX = cb.xl / 2;
            _triggerY = cb.yl - 2;
            triggerXl = 12;
            triggerYl = 12;
            _triggerXc = true;
            _triggerYc = true;
            break;
        case Type.muncher:
            _triggerX = cb.xl / 2;
            _triggerY = cb.yl * 4 / 5;
            triggerXl = 4; // _xl was 6 before July 2014, but 6 isn't symmetric
            triggerYl = 6; // on a piece with width 16 and (lix-xl % 2 == 0)
            _triggerXc = true;
            _triggerYc = true;
            break;
        case Type.water:
            _triggerX = 0;
            _triggerY = 20;
            triggerXl = cb.xl;
            triggerYl = cb.yl - 20;
            break;
        case Type.fire:
            _triggerX = 0;
            _triggerY = 0;
            triggerXl = cb.xl;
            triggerYl = cb.yl;
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
                _type = Type.hatch;
                specialX = i.nr1;
            }
            else if (i.text1 == tileDefFlingNonpermanent) {
                _type = Type.catapult;
            }
            else if (i.text1 == tileDefFlingIgnoreOrientation) {
                if (_type != Type.catapult)
                    _type = Type.steam;
                flingForward = false; // always fling left or always right
            }
            else if (i.text1 == tileDefFlingX) {
                if (_type != Type.catapult)
                    _type = Type.steam;
                specialX = i.nr1;
            }
            else if (i.text1 == tileDefFlingY) {
                if (_type != Type.catapult)
                    _type = Type.steam;
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
        if (_type != Type.fire) {
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
        if ((type == Type.muncher || type == Type.catapult) && cb.yfs != 2) {
            logf("Error: Triggered %s %s:", type, name);
            logf("    -> Image has %d rows of frames, not 2.", cb.yfs);
        }
    }
}
// end class GadgetTile
