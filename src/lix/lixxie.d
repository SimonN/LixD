module lix.lixxie;

import std.algorithm; // swap
import std.conv;
import std.string; // format, for codegen

import basics.alleg5; // BlenderMinus
import basics.globals; // fuse image
import basics.help;
import basics.matrix;
import basics.topology;
import file.option; // multipleBuilders
import tile.phymap;
import graphic.color;
import graphic.cutbit;
import graphic.gadget;
import graphic.internal;
import graphic.torbit;
import hardware.sound;
import lix;
import physics.mask;

alias Lixxie = LixxieImpl*;
alias ConstLix = const(LixxieImpl)*;

struct LixxieImpl {
private:
    /* _job refers back to Lixxie by counting backwards (Lixxie._job.offsetof).
     * This allows us to model the Job with D's OO features and be fast by
     * making Lixxie-Job-combos fast value types.
     * Gets package access for job to emplace itself here.
     */
    package JobUnion _job;

    short _ex;
    short _ey;
    short _flags;
    byte _flingX;
    byte _flingY;
    byte _ploderTimer; // phyus since assign. See exploder.handlePloderTimer.
    Style _style;
    Phybitset _encFoot;
    OutsideWorld* _outsideWorld; // set whenever physics and tight coupling
                                 // are needed, nulled again at end of those

    // Offset of our effective coordinate from top left sprite corner
    enum Point footOffsetFromCutbit = Point(16, 26);

    enum string tmpOutsideWorld = q{
        assert (ow);
        assert (! _outsideWorld);
        _outsideWorld = ow;
        scope (exit)
            _outsideWorld = null;
    };

    inout(Phymap) lookup() inout
    {
        assert (_outsideWorld, "need outsideWorld for ex/ey movement");
        return outsideWorld.state.lookup;
    }

package:
    enum jobOffset = _job.offsetof;
    static assert (_job.offsetof % size_t.sizeof == 0); // emplace alignment

    const(Topology) env() const
    {
        assert (_outsideWorld, "need outsideWorld for ex/ey movement");
        return outsideWorld.state.lookup;
    }

public:
    enum int ploderDelay = 75; // explode once _ploderTimer >= ploderDelay

    const pure nothrow @safe @nogc {
        Style style() { return _style; }
        Point foot() { return Point(_ex, _ey); }
        // Setters for the foot (i.e., to move the lix) are below in main code
        short ex() { return _ex; } // deprecate eventually, use foot
        short ey() { return _ey; } // deprecate eventually, use foot
    }

    const(Job) constJob() const { return _job.asClass; }
    package inout(Job) job() inout { return _job.asClass; }

    Ac ac() const { return job.ac; }
    PhyuOrder updateOrder() const { return job.updateOrder; }

    package inout(OutsideWorld*) outsideWorld() inout
    {
        assert (_outsideWorld !is null, "can't access _outsideWorld here");
        return _outsideWorld;
    }

    int ploderTimer() const { return _ploderTimer; }
    package void ploderTimer(in int i) { _ploderTimer = i.to!byte; }

    int flingX() const { return _flingX; }
    int flingY() const { return _flingY; }
    int frame() const { return job.frame; }
    void frame(in int i) { return job.frame = i; }
    int xf() const { return this.frame; }
    int yf() const { return this.ac; }

    auto footEncounters() const { return _encFoot; }
    void forceFootEncounters(Phybitset ft) { _encFoot = ft; }
    void setNoEncountersNoBlockerFlags()
    {
        _encFoot = 0;
        inBlockerFieldLeft  = false;
        inBlockerFieldRight = false;
        turnedByBlocker     = false;
    }

    private template flagsProperty(int bit, string name) {
        enum string flagsProperty = format(q{
            bool %s() const pure nothrow @safe @nogc
            {
                return (_flags & %d) != 0;
            }
            bool %s(in bool b) pure nothrow @safe @nogc
            {
                return b ? (_flags |= %d) != 0 : (_flags &= ~%d) != 0;
            }
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

    bool facingRight() const pure nothrow @safe @nogc { return ! facingLeft; }
    int dir() const pure nothrow @safe @nogc { return facingLeft ? -1 : 1; }
    void dir(in int i) pure nothrow @safe @nogc
    {
        assert (i != 0);
        facingLeft = (i < 0);
    }

    void turn() { dir = -dir; }

    // Mirror flips vertically. Therefore, when facingLeft, we have to
    // rotate by 180 degrees in addition.

public:

this(OutsideWorld* ow, in Point aLoc)
{
    mixin (tmpOutsideWorld);
    _style = outsideWorld.tribe.style;
    _ex = env.wrap(aLoc).x.even.to!(typeof(_ex));
    _ey = env.wrap(aLoc).y.to!(typeof(_ey));
    _job = JobUnion(Ac.faller);
    frame = 4;
    addEncountersFromHere();
}

this(this)
{
    // Even the _job, as a struct, is copied bitwise. Perfect, since it points
    // to its lixxie by deducting its offset. Only 1 Lixxie member is special:
    _outsideWorld = null; // Must be passed anew by the next update.
}

LixxieImpl clone() const
{
    LixxieImpl ret;
    ret._style = this._style;
    ret._ex = this._ex;
    ret._ey = this._ey;
    ret._flags = this._flags;
    ret._flingX = this._flingX;
    ret._flingY = this._flingY;
    ret._encFoot = this._encFoot;
    ret.ploderTimer = this.ploderTimer;
    ret._job = this._job; // POD, designed to be copied like this
    ret._outsideWorld = null; // Must be passed anew by the next update.
    return ret;
}

void addEncountersFromHere()
{
    _encFoot |= lookup.get(Point(_ex, _ey));
}

int ex(in int n)
{
    _ex = basics.help.even(n).to!(typeof(_ex));
    if (env.torusX)
        _ex = positiveMod(_ex, env.xl).to!(typeof(_ex));
    addEncountersFromHere();
    return _ex;
}

int ey(in int n)
{
    _ey = n.to!(typeof(_ey));
    if (env.torusY)
        _ey = positiveMod(_ey, env.yl).to!(typeof(_ey));
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
    return env.isPointInRectangle(Point(ex, ey), g.tile.triggerArea + g.loc);
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
    outsideWorld.effect.addSound(
        outsideWorld.state.age, outsideWorld.passport, sound);
}

const(Cutbit) cutbit() const { return getLixSpritesheet(_style); }
bool isLastFrame() const { return ! cutbit.frameExists(frame + 1, ac); }
void advanceFrame() { frame = (isLastFrame() ? 0 : frame + 1); }

package Point locCutbit() const // top left of sprite
{
    return foot - footOffsetFromCutbit + Point(job.spriteOffsetX, 0);
}

void draw() const
{
    if (ac == Ac.nothing)
        return;
    drawFuse(&this);
    cutbit.draw(locCutbit, xf, yf, facingLeft, 2 * facingLeft);
    drawFlame(&this);
    // Don't draw abilities here. The game should draw these before drawing any
    // lix, to have the lixes always in the foreground. Not good OO, but hm.
}

final void drawAgainHighlit() const
{
    assert (ac != Ac.nothing, "we shouldn't highlight dead lix");
    // No need to draw the fuse, because we draw on top of the old lix drawing.
    const cb = graphic.internal.getLixSpritesheet(Style.highlight);
    with (Blender(
        // cb is very light. We draw its colors like BlenderMinus and
        // its alpha like the standard blender's alpha. This will draw a near-
        // -black outline of the lix. The desired result is a black outline,
        // this is close enough.
        ALLEGRO_BLEND_OPERATIONS.ALLEGRO_DEST_MINUS_SRC,
        ALLEGRO_BLEND_MODE.ALLEGRO_ONE,
        ALLEGRO_BLEND_MODE.ALLEGRO_ONE,
        ALLEGRO_BLEND_OPERATIONS.ALLEGRO_ADD,
        ALLEGRO_BLEND_MODE.ALLEGRO_ONE,
        ALLEGRO_BLEND_MODE.ALLEGRO_INVERSE_ALPHA,
    )) {
        cb.draw(locCutbit + Point(1, 0), xf, yf, facingLeft, 2 * facingLeft);
        cb.draw(locCutbit - Point(1, 0), xf, yf, facingLeft, 2 * facingLeft);
        cb.draw(locCutbit - Point(0, 1), xf, yf, facingLeft, 2 * facingLeft);
        // Don't draw outline below. We don't want to obscure the ground.
    }
    cb.draw(locCutbit, xf, yf, facingLeft, 2 * facingLeft);
    drawAbilities(&this, true);
    drawFlame(&this);
}



// ############################################################################
// ######################### click priority -- was lix/lix_ac.cpp in C++/A4 Lix
// ############################################################################



bool healthy() const { return JobUnion.healthy(ac); }
bool cursorShouldOpenOverMe() const { return healthy; }

// returns 0 iff lix is not clickable and the cursor should be closed
// returns 1 iff lix is not clickable, but the cursor should open still
// returns >= 2 and <= 99,998 iff lix is clickable
// higher return values mean higher priority. The player can invert priority,
// e.g., by holding the right mouse button. This inversion is not handled by
// this function, but should be done by the calling game code.
int priorityForNewAc(in Ac newAc) const
{
    // Nothing allowed at all, don't even open the cursor
    if (! cursorShouldOpenOverMe) return 0;

    // Permanent skills
    if ((newAc == Ac.imploder && ploderTimer > 0)
     || (newAc == Ac.exploder && ploderTimer > 0)
     || (newAc == Ac.runner && abilityToRun)
     || (newAc == Ac.climber && abilityToClimb)
     || (newAc == Ac.floater && abilityToFloat) ) return 1;

    immutable base = basePriorityForNewAcGivenOldAc(newAc);
    if (base < 2) {
        return base;
    }
    return base + (newAc == Ac.batter && avoidBatterToExploder.value
            ? (- ploderTimer) : ploderTimer)
        + 400 * abilityToRun + 200 * abilityToClimb + 100 * abilityToFloat;
}

private int basePriorityForNewAcGivenOldAc(in Ac newAc) const
out (ret) { assert(ret < 2 || ret % 1000 == 0); }
do {
    switch (ac) {
        // When a blocker shall be freed/exploded, the blocker has extremely
        // high priority, more than anything else on the field.
        case Ac.blocker:
            if (newAc == Ac.walker
                || newAc == Ac.imploder
                || newAc == Ac.exploder)
                return 6000;
            // New in Lix 0.10: Allow ability assignments to blocker.
            if (newAc == Ac.runner
                || newAc == Ac.climber
                || newAc == Ac.floater)
                return 1000;
            goto WE_ARE_REALLY_TOO_BUSY;

        // Stunners/ascenders may be turned in their later frames, but
        // otherwise act like regular mostly unassignable-to acitivities
        case Ac.stunner:
            if (frame >= 16)
                return 3000;
            goto WE_ARE_REALLY_TOO_BUSY;

        case Ac.ascender:
            if (frame >= 5)
                return 3000;
            goto WE_ARE_REALLY_TOO_BUSY;

        // further activities that take all of the lix's attention; she
        // canot be assigned anything except permanent skills
        case Ac.faller:
        case Ac.tumbler:
        case Ac.climber:
        case Ac.floater:
        case Ac.jumper:
        WE_ARE_REALLY_TOO_BUSY:
            if (newAc == Ac.runner
                 || newAc == Ac.climber
                 || newAc == Ac.floater
                 || newAc == Ac.imploder
                 || newAc == Ac.exploder)
                return 2000;
            return 1;

        // standard activities, not considered working lixes
        case Ac.walker:
        case Ac.lander:
        case Ac.runner:
            return 3000;

        // Builders and platformers can be queued. These assignments go
        // always through (p > 1), that's important in networked games.
        // Maybe we prefer non-builders over builders here, but that's not
        // a problem with networking. Values > 1 do something different
        // in the UI, but allow the same networking actions.
        case Ac.builder:
        case Ac.platformer:
            if (newAc == ac)
                return avoidBuilderQueuing.value ? 1000 : 4000;
            return 5000;

        // Usually, anything different from the current activity can be assign.
        default:
            return (newAc != ac) ? 5000 : 1;
    }
}


// ############################################################################
// ############### skill function dispatch -- was lix/acFunc.cpp in C++/A4 Lix
// ############################################################################



void become(in Ac newAc) { becomeTemplate!false(newAc); }

void assignManually(OutsideWorld* ow, in Ac newAc)
{
    mixin(tmpOutsideWorld);
    becomeTemplate!true(newAc);
}

void perform(OutsideWorld* ow)
{
    mixin(tmpOutsideWorld);
    performUseGadgets(&this); // in lix.perform
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
    Tumbler.applyFlingXY(&this); // this will check if flingNew == true
}

private void becomeTemplate(bool manualAssignment)(in Ac newAc)
{
    JobUnion oldJob = _job;
    _job = JobUnion(newAc);

    immutable AfterAssignment afas = manualAssignment
        ? job.onManualAssignment(oldJob.asClass) // has side effects
        : AfterAssignment.becomeNormally;

    if (oldJob.asClass.ac != ac && ! restoreOldJob(afas)) {
        // For memory safety, we could temporarily copy oldJob back into _job,
        // call onBecomingSomethingElse, and copy back the new job.
        // Not doing that, and instead telling the Job override functions not
        // to look into their lixxie().
        oldJob.asClass.returnSkillsDontCallLixxieInHere(outsideWorld.tribe);
    }
    if (restoreOldJob(afas)) {
        _job = oldJob;
    }
    else if (afas == AfterAssignment.becomeNormally) {
        job.onBecome(oldJob.asClass); // can call become() recursively
        static if (manualAssignment)
            // can go to -1, then after the update, frame 0 is displayed
            frame = frame - 1;
    }
}

private bool restoreOldJob(AfterAssignment afas)
{
    final switch (afas) {
        case AfterAssignment.becomeNormally:  return false;
        case AfterAssignment.doNotBecome:     return true;
        case AfterAssignment.weAlreadyBecame: return false;
    }
}

}
