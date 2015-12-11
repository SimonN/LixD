module lix.lixxie;

import std.algorithm; // swap

import basics.globals; // fuse image
import basics.help;
import basics.matrix;
import basics.user; // multipleBuilders
import game.phymap;
import graphic.color;
import graphic.gadget;
import graphic.graphic;
import graphic.gralib;
import graphic.torbit;
import hardware.sound;
import lix;

// DTODOCOMMENT: add the interesting things from the 150+ line comment in
// C++/A4 Lix's lix/lix.h top comment.

class Lixxie : Graphic {

private:

    int _ex;
    int _ey;
    int _flags;
    int _flingX;
    int _flingY;

    Phybitset _encBody;
    Phybitset _encFoot;

    Style _style;

    PerformedActivity _perfAc;

    OutsideWorld* _outsideWorld; // set whenever physics and tight coupling
                                 // are needed, nulled again at end of those

    @property inout(Phymap) lookup() inout
    {
        assert (outsideWorld);
        return outsideWorld.state.lookup;
    }

    enum string tmpOutsideWorld = q{
        assert (ow);
        assert (! _outsideWorld);
        _outsideWorld = ow;
        scope (exit)
            _outsideWorld = null;
    };

public:

    int  updatesSinceBomb;

    Style style() const { return _style; }

    @property int ex() const { return _ex; }
    @property int ey() const { return _ey; }
    // setters for these are below in the main code

    package @property inout(PerformedActivity) performedActivity() inout
    {
        return _perfAc;
    }

    @property Ac ac() const
    {
        assert (_perfAc);
        return _perfAc.ac;
    }

    @property UpdateOrder updateOrder() const
    {
        assert (_perfAc);
        return _perfAc.updateOrder;
    }

    package @property inout(OutsideWorld*) outsideWorld() inout
    {
        assert (_outsideWorld !is null);
        return _outsideWorld;
    }

    @property int  flingX()   const { return _flingX;   }
    @property int  flingY()   const { return _flingY;   }

    @property int frame() const   { return _perfAc.frame;     }
    @property int frame(in int i) { return _perfAc.frame = i; }

    // (super == Graphic) shall use frame and ac to draw itself
               override @property int xf() const   { return this.frame; }
               override @property int yf() const   { return this.ac;    }
    deprecated override @property int xf(in int i) { assert (false);    }
    deprecated override @property int yf(in int i) { assert (false);    }

    @property auto bodyEncounters() const { return _encBody; }
    @property auto footEncounters() const { return _encFoot; }
    void setNoEncounters() { _encBody = _encFoot = 0; }

    void forceBodyAndFootEncounters(Phybitset bo, Phybitset ft)
    {
        _encBody = bo;
        _encFoot = ft;
    }

    private template flagsProperty(int bit, string name) {
        enum string flagsProperty = format(q{
            @property bool %s() const    { return     (_flags &   %d) != 0; }
            @property bool %s(in bool b) { return b ? (_flags |=  %d) != 0
                                                    : (_flags &= ~%d) != 0; }
        }, name, bit, name, bit, bit);
    }

    mixin(flagsProperty!(0x0001, "facingLeft"));
    mixin(flagsProperty!(0x0002, "abilityToRun"));
    mixin(flagsProperty!(0x0004, "abilityToClimb"));
    mixin(flagsProperty!(0x0008, "abilityToFloat"));

    mixin(flagsProperty!(0x0010, "marked"));
    mixin(flagsProperty!(0x0020, "exploderKnockback"));
    mixin(flagsProperty!(0x0040, "flingNew"));
    mixin(flagsProperty!(0x0080, "flingBySameTribe"));

    mixin(flagsProperty!(0x0100, "turnedByBlocker"));
    mixin(flagsProperty!(0x0200, "inBlockerFieldLeft"));
    mixin(flagsProperty!(0x0400, "inBlockerFieldRight"));

    @property bool facingRight() const { return ! facingLeft; }
    @property int dir()          const { return facingLeft ? -1 : 1; }
    @property int dir(in int i)
    {
        assert (i != 0);
        facingLeft = (i < 0);
        // Mirror flips vertically. Therefore, when facingLeft, we have to
        // rotate by 180 degrees in addition.
        super.mirror   =     facingLeft;
        super.rotation = 2 * facingLeft;
        return dir;
    }

    void turn() { dir = -dir; }



public:

this(
    in Torbit     groundMap,
    OutsideWorld* ow,
    int   new_ex,
    int   new_ey
) {
    mixin (tmpOutsideWorld);

    _style = outsideWorld.tribe.style;

    super(getLixSpritesheet(_style), groundMap,
          even(new_ex) - exOffset, new_ey - eyOffset);

    _perfAc = PerformedActivity.factory(this, Ac.faller);
    frame   = 4;
    ex      = new_ex.even;
    ey      = new_ey;
}



this(in Lixxie rhs)
{
    assert (rhs !is null);

    _style = rhs._style;
    _ex    = rhs._ex;
    _ey    = rhs._ey;
    _flags = rhs._flags;

    super(graphic.gralib.getLixSpritesheet(_style), rhs.ground,
        _ex - exOffset, _ey - eyOffset);

    dir = rhs.dir; // important to set super's mirr and rot

    _flingX = rhs._flingX;
    _flingY = rhs._flingY;
    _encBody = rhs._encBody;
    _encFoot = rhs._encFoot;

    updatesSinceBomb  = rhs.updatesSinceBomb;

    _perfAc = rhs._perfAc.cloneAndBindToLix(this);

    _outsideWorld = null; // Must be passed anew by the next update.
                          // Can't copy this from const lix, keep it at .init.
}

override Lixxie clone() const { return new Lixxie(this); }



private XY getFuseXY() const
{
    XY ret = countdown.get(frame, ac);
    if (facingLeft)
        ret.x = this.cutbit.xl - ret.x;
    ret.x += super.x;
    ret.y += super.y;
    return ret;
}



private void addEncountersFromHere()
{
    immutable XY fuseXy = getFuseXY();
    _encFoot |= lookup.get(_ex, _ey);
    _encBody |= _encFoot
             |  lookup.get(_ex, _ey - 4)
             |  lookup.get(fuseXy.x, fuseXy.y);
}



@property int
ex(in int n)
{
    _ex = basics.help.even(n);
    if (ground.torusX)
        _ex = positiveMod(_ex, ground.xl);
    addEncountersFromHere();
    return _ex;
}



@property int
ey(in int n)
{
    _ey = n;
    if (ground.torusY)
        _ey = positiveMod(_ey, ground.yl);
    addEncountersFromHere();
    return _ey;
}



void moveAhead(int plusX = 2)
{
    if (inBlockerFieldLeft && inBlockerFieldRight)
        // don't allow sideways movement if caught between two blockers
        return;

    plusX = even(plusX) * dir;
    // move in little steps, to check for lookupmap encounters on the way
    for ( ; plusX > 0; plusX -= 2) ex = (_ex + 2);
    for ( ; plusX < 0; plusX += 2) ex = (_ex - 2);
}



void moveDown(int plusY = 2)
{
    for ( ; plusY > 0; --plusY) ey = (_ey + 1);
    for ( ; plusY < 0; ++plusY) ey = (_ey - 1);
}



void moveUp(in int minusY = 2)
{
    moveDown(-minusY);
}



bool get_in_trigger_area(in Gadget g) const
{
    return ground.isPointInRectangle(ex, ey,
        g.x + g.tile.triggerX(), g.y + g.tile.triggerY(),
              g.tile.triggerXl,        g.tile.triggerYl);
}



void addFling(in int px, in int py, in bool same_tribe)
{
    if (flingBySameTribe && same_tribe) return;

    flingBySameTribe = (flingBySameTribe || same_tribe);
    flingNew         = true;
    _flingX += px;
    _flingY += py;
}



void resetFlingNew()
{
    flingNew         = false;
    flingBySameTribe = false;
    _flingX          = 0;
    _flingY          = 0;
}



bool getSteel(in int px, in int py) const
{
    return lookup.getSteel(_ex + px * dir, _ey + py);
}



bool isSolid(in int px = 0, in int py = 2) const
{
    return lookup.getSolidEven(_ex + px * dir, _ey + py);
}



bool isSolidSingle(in int px = 0, in int py = 2) const
{
    return lookup.getSolid(_ex + px * dir, _ey + py);
}



int solidWallHeight(in int px = 0, in int py = 0) const
{
    int solid = 0;
    for (int i = 1; i > -Walker.highestStepUp; --i) {
        if (isSolid(px, py + i)) ++solid;
        else break;
    }
    return solid;
}



int countSolid(int x1, int y1, int x2, int y2) const
{
    if (x2 < x1) swap(x1, x2);
    if (y2 < y1) swap(y1, y2);
    int ret = 0;
    for (int ix = basics.help.even(x1); ix <= even(x2); ix += 2) {
        for (int iy = y1; iy <= y2; ++iy) {
            if (isSolid(ix, iy)) ++ret;
        }
    }
    return ret;
}



int countSteel(int x1, int y1, int x2, int y2) const
{
    if (x2 < x1) swap(x1, x2);
    if (y2 < y1) swap(y1, y2);
    int ret = 0;
    for (int ix = even(x1); ix <= even(x2); ix += 2) {
        for (int iy = y1; iy <= y2; ++iy) {
            if (getSteel(ix, iy)) ++ret;
        }
    }
    return ret;
}



void playSound(in Sound sound)
{
    outsideWorld.effect.addSound(
        outsideWorld.state.update, outsideWorld.tribeID, outsideWorld.lixID,
        sound);
}



void playSoundIfTribeLocal(in Sound sound)
{
    outsideWorld.effect.addSoundIfTribeLocal(
        outsideWorld.state.update, outsideWorld.tribeID, outsideWorld.lixID,
        sound);
}



override bool isLastFrame() const
{
    return ! cutbit.frameExists(frame + 1, ac);
}



void advanceFrame()
{
    frame = (isLastFrame() ? 0 : frame + 1);
}



void prepareDraw()
{
    assert (_perfAc);
    super.x = _ex - exOffset + _perfAc.spriteOffsetX;
    super.y = _ey - eyOffset;
}

override void draw(Torbit tb) const
{
    if (ac == Ac.nothing)
        return;

    // draw the fuse if necessary
    if (updatesSinceBomb > 0) {
        immutable XY fuseXy = getFuseXY();
        immutable int fuseX = fuseXy.x;
        immutable int fuseY = fuseXy.y;

        int x = 0;
        int y = 0;
        for (; -y < (Exploder.updatesForBomb - updatesSinceBomb)/5+1; --y) {
            /*
            // DTODOVRAM: decide on how to draw the pixel-rendered fuse
            const int u = updatesSinceBomb;
            x           = (int) (std::sin(u/2.0) * 0.02 * (y-4) * (y-4));
            tb.setPixel(fuseX + x-1, fuseY + y-1, color[COL_GREY_FUSE_L]);
            tb.setPixel(fuseX + x-1, fuseY + y  , color[COL_GREY_FUSE_L]);
            tb.setPixel(fuseX + x  , fuseY + y-1, color[COL_GREY_FUSE_D]);
            tb.setPixel(fuseX + x  , fuseY + y  , color[COL_GREY_FUSE_D]);
            */
        }
        // draw the flame
        auto cb = getInternal(fileImageFuse_flame);
        cb.draw(tb, fuseX + x - cb.xl/2,
                    fuseY + y - cb.yl/2, updatesSinceBomb % cb.xfs, 0);
    }
    // end of drawing the fuse

    super.draw(tb);
}


// ############################################################################
// ######################### click priority -- was lix/lix_ac.cpp in C++/A4 Lix
// ############################################################################



bool healthy() const
{
    return ! cast (Leaver) this.performedActivity;
}

bool cursorShouldOpenOverMe() const
{
    return ac != Ac.nothing && healthy;
}

// returns 0 iff lix is not clickable and the cursor should be closed
// returns 1 iff lix is not clickable, but the cursor should open still
// returns >= 2 and <= 99,998 iff lix is clickable
// higher return values mean higher priority. The player can invert priority,
// e.g., by holding the right mouse button. This inversion is not handled by
// this function, but should be done by the calling game code.
int priorityForNewAc(
    in Ac   newAc,
    in bool personal // Shall personal settings override the default valuation?
) const {            // If false, allow anything anyone could do, for network
    int p = 0;

    // Nothing allowed at all, don't even open the cursor
    if (! cursorShouldOpenOverMe) return 0;

    // Permanent skills
    if ((newAc == Ac.exploder  && updatesSinceBomb > 0)
     || (newAc == Ac.exploder2 && updatesSinceBomb > 0)
     || (newAc == Ac.runner    && abilityToRun)
     || (newAc == Ac.climber   && abilityToClimb)
     || (newAc == Ac.floater   && abilityToFloat) ) return 1;

    switch (ac) {
        // When a blocker shall be freed/exploded, the blocker has extremely
        // high priority, more than anything else on the field.
        case Ac.blocker:
            if (newAc == Ac.walker
             || newAc == Ac.exploder
             || newAc == Ac.exploder2) p = 5000;
            else return 1;
            break;

        // Stunners/ascenders may be turned in their later frames, but
        // otherwise act like regular mostly unassignable-to acitivities
        case Ac.stunner:
            if (frame >= 16) {
                p = 3000;
                break;
            }
            else goto GOTO_TARGET_FULL_ATTENTION;

        case Ac.ascender:
            if (frame >= 5) {
                p = 3000;
                break;
            }
            else goto GOTO_TARGET_FULL_ATTENTION;

        // further activities that take all of the lix's attention; she
        // canot be assigned anything except permanent skills
        case Ac.faller:
        case Ac.tumbler:
        case Ac.climber:
        case Ac.floater:
        case Ac.jumper:
        GOTO_TARGET_FULL_ATTENTION:
            if (newAc == Ac.runner
             || newAc == Ac.climber
             || newAc == Ac.floater
             || newAc == Ac.exploder
             || newAc == Ac.exploder2) p = 2000;
            else return 1;
            break;

        // standard activities, not considered working lixes
        case Ac.walker:
        case Ac.lander:
        case Ac.runner:
            p = 3000;
            break;

        // builders and platformers can be queued. Use the personal variable
        // to see whether we should read the user's setting. If false, we're
        // having a replay or multiplayer game, and then queuing must work
        // even if the user has disabled it for themselves.
        case Ac.builder:
        case Ac.platformer:
            if (newAc == ac
             && (! personal || multipleBuilders)) p = 1000;
            else if (newAc != ac)                 p = 4000;
            else                                   return 1;
            break;

        // Usually, anything different from the current activity can be assign.
        default:
            if (newAc != ac) p = 4000;
            else return 1;

    }
    p += (newAc == Ac.batter && batterPriority
          ? (- updatesSinceBomb) : updatesSinceBomb);
    p += 400 * abilityToRun + 200 * abilityToClimb + 100 * abilityToFloat;
    return p;
}



// ############################################################################
// ############### skill function dispatch -- was lix/acFunc.cpp in C++/A4 Lix
// ############################################################################



void assignManually(OutsideWorld* ow, in Ac newAc)
{
    mixin(tmpOutsideWorld);
    become!true(newAc);
}

void performActivity(OutsideWorld* ow)
{
    mixin(tmpOutsideWorld);
    assert (_perfAc);
    _perfAc.performActivity();
}



void become(bool manualAssignment = false)(in Ac newAc)
{
    assert (_perfAc);
    auto oldPerf = _perfAc;
    auto newPerf = PerformedActivity.factory(this, newAc);

    if (ac != newPerf.ac)
        _perfAc.onBecomingSomethingElse();

    static if (manualAssignment)
        // while Lix still has old performed ac
        newPerf.onManualAssignment();

    if (newPerf.callBecomeAfterAssignment || ! manualAssignment) {
        newPerf.onBecome();

        if (_perfAc is oldPerf) {
            // if onBecome() calls become() again, only let the last change
            // through into Lixxie's data. Ignore the intermediate _perfAc.
            _perfAc = newPerf;
            static if (manualAssignment)
                // can go to -1, then after the update, frame 0 is displayed
                frame = frame - 1;
        }
    }
}

}
// end class Lixxie
