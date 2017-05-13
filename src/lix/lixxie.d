module lix.lixxie;

import std.algorithm; // swap
import std.string; // format, for codegen

import basics.globals; // fuse image
import basics.help;
import basics.matrix;
import basics.topology;
import basics.user; // multipleBuilders
import game.mask;
import tile.phymap;
import graphic.color;
import graphic.gadget;
import graphic.graphic;
import graphic.internal;
import graphic.torbit;
import hardware.sound;
import lix;

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
    Job _job;
    OutsideWorld* _outsideWorld; // set whenever physics and tight coupling
                                 // are needed, nulled again at end of those
    int _ploderTimer; // phyus since ploder assignment. For details,
                      // see lix.skills.exploder.handlePloderTimer.

    enum int exOffset = 16; // offset of the effective coordinate of the lix
    enum int eyOffset = 26; // sprite from the top left corner

    @property inout(Phymap) lookup() inout
    {
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
    enum int ploderDelay = 75; // explode once _ploderTimer >= ploderDelay

    Style style() const { return _style; }

    @property int ex() const { return _ex; }
    @property int ey() const { return _ey; }
    // setters for these are below in the main code

    @property const(Job) constJob() const
    {
        return _job;
    }
    package @property inout(Job) job() inout
    {
        return _job;
    }

    @property Ac ac() const
    {
        assert (_job);
        return _job.ac;
    }

    @property PhyuOrder updateOrder() const
    {
        assert (_job);
        return _job.updateOrder;
    }

    package @property inout(OutsideWorld*) outsideWorld() inout
    {
        assert (_outsideWorld !is null, "can't access _outsideWorld here");
        return _outsideWorld;
    }

            @property int  ploderTimer() const   { return _ploderTimer; }
    package @property void ploderTimer(in int i) { _ploderTimer = i;    }

    @property int  flingX()   const { return _flingX;   }
    @property int  flingY()   const { return _flingY;   }

    @property int frame() const   { return _job.frame;     }
    @property int frame(in int i) { return _job.frame = i; }

    // (super == Graphic) shall use frame and ac to draw itself
    // DTODOREFACTOR: Inheriting from Graphic
    // violates the Liskov subtitution principle because I don't want
    // to offer setting yf here. Give the Lix different activities instead.

    override @property int xf() const { return this.frame; }
    override @property int yf() const { return this.ac;    }

    @property auto bodyEncounters() const { return _encBody; }
    @property auto footEncounters() const { return _encFoot; }

    void setNoEncountersNoBlockerFlags()
    {
        _encBody = 0;
        _encFoot = 0;
        inBlockerFieldLeft  = false;
        inBlockerFieldRight = false;
        turnedByBlocker     = false;
    }

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
    mixin(flagsProperty!(0x0020, "ploderIsExploder"));
    mixin(flagsProperty!(0x0040, "flingNew"));
    mixin(flagsProperty!(0x0080, "flingBySameTribe"));

    mixin(flagsProperty!(0x0100, "turnedByBlocker"));
    mixin(flagsProperty!(0x0200, "inBlockerFieldLeft"));
    mixin(flagsProperty!(0x0400, "inBlockerFieldRight"));
    /* turnedByBlocker is set by the blocker on the target Lix, typically
     * before the target lix updates itself -- see PhyuOrder in module net.ac.
     * If true, turned builders e.g. generate extra steps on their own update.
     */

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

this(const(Topology) env, OutsideWorld* ow, in Point aLoc)
{
    mixin (tmpOutsideWorld);
    _style = outsideWorld.tribe.style;
    _ex = env.wrap(aLoc).x.even;
    _ey = env.wrap(aLoc).y;
    super(getLixSpritesheet(_style), env, Point(_ex - exOffset,
                                                _ey - eyOffset));
    _job  = Job.factory(this, Ac.faller);
    frame = 4;
    addEncountersFromHere();
}

this(in Lixxie rhs)
{
    assert (rhs !is null);
    _style = rhs._style;
    _ex    = rhs._ex;
    _ey    = rhs._ey;
    _flags = rhs._flags;
    super(graphic.internal.getLixSpritesheet(_style), rhs.env,
        Point(_ex - exOffset, _ey - eyOffset));

    dir = rhs.dir; // important to set super's mirr and rot
    _flingX = rhs._flingX;
    _flingY = rhs._flingY;
    _encBody = rhs._encBody;
    _encFoot = rhs._encFoot;
    ploderTimer = rhs.ploderTimer;
    _job = rhs._job.cloneAndBindToLix(this);
    _outsideWorld = null; // Must be passed anew by the next update.
                          // Can't copy this from const lix, keep it at .init.
}

override Lixxie clone() const { return new Lixxie(this); }

void addEncountersFromHere()
{
    _encFoot |= lookup.get(Point(_ex, _ey));
    _encBody |= _encFoot
             |  lookup.get(Point(_ex, _ey -  4))
             |  lookup.get(Point(_ex, _ey -  8))
             |  lookup.get(Point(_ex, _ey - 12));
}

package void repositionSprite()
{
    super.loc = Point(_ex - exOffset + _job.spriteOffsetX, _ey - eyOffset);
}

@property int ex(in int n)
{
    _ex = basics.help.even(n);
    if (env.torusX)
        _ex = positiveMod(_ex, env.xl);
    assert (_job);
    repositionSprite();
    addEncountersFromHere();
    return _ex;
}

@property int ey(in int n)
{
    _ey = n;
    if (env.torusY)
        _ey = positiveMod(_ey, env.yl);
    repositionSprite();
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

void moveDown(int plusY)
{
    for ( ; plusY > 0; --plusY) ey = (_ey + 1);
    for ( ; plusY < 0; ++plusY) ey = (_ey - 1);
}

void moveUp(in int minusY)
{
    moveDown(-minusY);
}

bool inTriggerArea(in Gadget g) const
{
    // There is potential for refactoring here. Gadget doesn't hold a reference
    // on the GadOcc it's instantiated with. Occurrence has Rect selbox()
    // const, therefore GadOcc should naturally get Rect triggerArea() const.
    // Then Gadget should defer to GadOcc.
    return env.isPointInRectangle(Point(ex, ey),
        Rect(g.x + g.tile.triggerX(), g.y + g.tile.triggerY(),
             g.tile.triggerXl,        g.tile.triggerYl));
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
    return lookup.getSteel(Point(_ex + px * dir, _ey + py));
}

bool isSolid(in int px = 0, in int py = 2) const
{
    return lookup.getSolidEven(Point(_ex + px * dir, _ey + py));
}

bool wouldHitSteel(in Mask mask) const
{
    return lookup.getSteelUnlessMaskIgnores(Point(_ex, _ey), mask);
}

bool isSolidSingle(in int px = 0, in int py = 2) const
{
    return lookup.getSolid(Point(_ex + px * dir, _ey + py));
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
    if (outsideWorld.effect)
        outsideWorld.effect.addSound(
            outsideWorld.state.update, _style, outsideWorld.lixID, sound);
}

override bool isLastFrame() const
{
    return ! cutbit.frameExists(frame + 1, ac);
}

void advanceFrame()
{
    frame = (isLastFrame() ? 0 : frame + 1);
}

override void draw() const
{
    if (ac == Ac.nothing)
        return;
    drawFuse(this);
    super.draw();
    drawFlame(this);
}

final void drawAgainHighlit() const
{
    assert (ac != Ac.nothing, "we shouldn't highlight dead lix");
    // No need to draw the fuse, because we draw on top of the old lix drawing.
    // Hack: We examine the base class Graphic for what it would draw,
    // and use a different sprite with the copy-pasted code.
    graphic.internal.getLixSpritesheet(Style.highlight).draw(
        super.loc, xf, yf, super.mirror, super.rotation);
    drawFlame(this);
}



// ############################################################################
// ######################### click priority -- was lix/lix_ac.cpp in C++/A4 Lix
// ############################################################################



bool healthy() const
{
    return ac != Ac.nothing && ! cast (Leaver) this.job;
}

bool cursorShouldOpenOverMe() const
{
    return healthy;
}

// returns 0 iff lix is not clickable and the cursor should be closed
// returns 1 iff lix is not clickable, but the cursor should open still
// returns >= 2 and <= 99,998 iff lix is clickable
// higher return values mean higher priority. The player can invert priority,
// e.g., by holding the right mouse button. This inversion is not handled by
// this function, but should be done by the calling game code.
int priorityForNewAc(in Ac newAc) const
{
    int p = 0; // return value

    // Nothing allowed at all, don't even open the cursor
    if (! cursorShouldOpenOverMe) return 0;

    // Permanent skills
    if ((newAc == Ac.imploder && ploderTimer > 0)
     || (newAc == Ac.exploder && ploderTimer > 0)
     || (newAc == Ac.runner && abilityToRun)
     || (newAc == Ac.climber && abilityToClimb)
     || (newAc == Ac.floater && abilityToFloat) ) return 1;

    switch (ac) {
        // When a blocker shall be freed/exploded, the blocker has extremely
        // high priority, more than anything else on the field.
        case Ac.blocker:
            if (newAc == Ac.walker
             || newAc == Ac.imploder
             || newAc == Ac.exploder) p = 6000;
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
             || newAc == Ac.imploder
             || newAc == Ac.exploder) p = 2000;
            else return 1;
            break;

        // standard activities, not considered working lixes
        case Ac.walker:
        case Ac.lander:
        case Ac.runner:
            p = 3000;
            break;

        // Builders and platformers can be queued. These assignments go
        // always through (p > 1), that's important in networked games.
        // Maybe we prefer non-builders over builders here, but that's not
        // a problem with networking. Values > 1 do something different
        // in the UI, but allow the same networking actions.
        case Ac.builder:
        case Ac.platformer:
            if (newAc == ac)
                p = avoidBuilderQueuing.value ? 1000 : 4000;
            else
                p = 5000;
            break;

        // Usually, anything different from the current activity can be assign.
        default:
            if (newAc != ac)
                p = 5000;
            else
                return 1;
    }
    p += (newAc == Ac.batter && avoidBatterToExploder.value
          ? (- ploderTimer) : ploderTimer);
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

void perform(OutsideWorld* ow)
{
    mixin(tmpOutsideWorld);
    performUseGadgets(this); // in lix.perform
}

void becomePloder(OutsideWorld* ow)
{
    mixin(tmpOutsideWorld);
    become(ploderIsExploder ? Ac.exploder : Ac.imploder);
}

void applyFlingXY(OutsideWorld* ow)
{
    if (! healthy)
        return;
    mixin(tmpOutsideWorld);
    Tumbler.applyFlingXY(this); // this will check if flingNew == true
}

void become(bool manualAssignment = false)(in Ac newAc)
{
    assert (_job);
    auto oldJob = _job;
    auto newJob = Job.factory(this, newAc);
    immutable yesBecome = newJob.callBecomeAfterAssignment
                          || ! manualAssignment;
    if (ac != newJob.ac && yesBecome) {
        _job.onBecomingSomethingElse();
    }
    static if (manualAssignment) {
        // while Lix still has old performed ac
        newJob.onManualAssignment();
    }
    if (yesBecome) {
        newJob.onBecome();
        if (_job is oldJob) {
            // if onBecome() calls become() again, only let the last change
            // through into Lixxie's data. Ignore the intermediate _job.
            _job = newJob;
            static if (manualAssignment)
                // can go to -1, then after the update, frame 0 is displayed
                frame = frame - 1;
            repositionSprite(); // consider new job's spriteOffsetX
        }
    }
}

}
// end class Lixxie
