module lix.lixxie;

import std.algorithm; // swap

import basics.globals; // fuse image
import basics.help;
import basics.matrix;
import basics.user; // multipleBuilders
import game;
import graphic.color;
import graphic.gadget;
import graphic.graphic;
import graphic.gralib;
import graphic.map;
import graphic.torbit;
import hardware.sound;
import lix;

// DTODOCOMMENT: add the interesting things from the 150+ line comment in
// C++/A4 Lix's lix/lix.h top comment.

class Lixxie : Graphic {

private:

    int  _ex;
    int  _ey;
    bool _facingLeft;

    int  _flingX;
    int  _flingY;
    bool _flingNew;
    bool _flingBySameTribe;

    static bool _anyNewFlingers;

    Lookup.LoNr _encBody;
    Lookup.LoNr _encFoot;

    Style _style;

    PerformedActivity _perfAc;

    void draw_at(const int, const int);

public:

    static immutable int updatesForBomb = 75;

    static Torbit*       land;
    static Lookup*       lookup;
    static Map           groundMap;
    static EffectManager effect;

    int queue; // builders and platformers can be queued in advance

    bool marked; // used by the game class, marks if already updated

    bool abilityToRun;
    bool abilityToClimb;
    bool abilityToFloat;

    int  updatesSinceBomb;
    bool exploderKnockback;

/*  this(Style, int = 0, int = 0);
 *  this(in Lixxie rhs);
 */
    override Lixxie clone() const { return new Lixxie(this); }

    static bool anyNewFlingers() { return _anyNewFlingers; }

    Style style() const { return _style; }

    @property int ex() const { return _ex; }
    @property int ey() const { return _ey; }
/*  @property int ex(in int);
 *  @property int ey(in int);
 *
 *  void moveAhead(int = 2);
 *  void moveDown(int = 2);
 *  void moveUp  (int = 2);
 */
    @property bool facingLeft()  const { return   _facingLeft; }
    @property bool facingRight() const { return ! _facingLeft; }
    @property int dir() const { return _facingLeft ? -1 : 1; }
    @property int dir(in int i)
    {
        assert (i != 0);
        return _facingLeft = (i < 0);
    }

    void turn() { _facingLeft = ! _facingLeft; }

    @property const(PerformedActivity) performedActivity() const
    {
        return _perfAc;
    }

    @property Ac ac() const
    {
        assert (_perfAc);
        return _perfAc.ac;
    }

//  bool get_in_trigger_area(const EdGraphic) const;

    @property bool flingNew() const { return _flingNew; }
    @property int  flingX()   const { return _flingX;   }
    @property int  flingY()   const { return _flingY;   }
/*  void addFling(int, int, bool (from same tribe) = false);
 *  void resetFlingNew();
 *
 *  static bool getSteelAbsolute(in int, in int);
 *  bool getSteel         (in int = 0, in int = 0);
 *
 *  void addLand          (in int = 0, in int = 0, in AlCol = color.transp);
 *  void addLandAbsolute (in int = 0, in int = 0, in AlCol = color.transp);
 *
 *      don't call addLand from the skills, use drawPixel. That amends
 *      the x-direction by left-looking lixes by the desired 1 pixel. Kludge:
 *      Maybe remove addLand entirely and put the functionality in drawPixel?
 *
 *  bool isSolid          (in int = 0, in int = 2);
 *  bool isSolidSingle   (in int = 0, in int = 2);
 *  int  solidWallHeight (in int = 0, in int = 0);
 *  int  countSolid       (int, int, int, int);
 *  int  countSteel       (int, int, int, int);
 *
 *  static void removePixelAbsolute(in int, in int);
 *  bool        removePixel         (   int, in int);
 *  bool        removeRectangle     (int, int, int, int);
 *
 *  void drawPixel       (int,      in int,   in AlCol);
 *  void drawRectangle   (int, int, int, int, in AlCol);
 *  void drawBrick       (int, int, int, int);
 *  void drawFrameToMapAsTerrain(int, int, int, int, int, int, int, int);
 *
 *  void playSound        (in ref UpdateArgs, in Sound);
 *  void playSoundIfTribeLocal(in ref UpdateArgs, in Sound);
 */
    @property int frame() const   { return _perfAc.frame;     }
    @property int frame(in int i) { return _perfAc.frame = i; }
/*           void advanceFrame();
 *  override bool isLastFrame() const;
 */
    @property auto bodyEncounters() const { return _encBody; }
    @property auto footEncounters() const { return _encFoot; }
    void setNoEncounters() { _encBody = _encFoot = 0; }

    void forceBodyAndFootEncounters(Lookup.LoNr bo, Lookup.LoNr ft)
    {
        _encBody = bo;
        _encFoot = ft;
    }

//  int  get_priority  (in Ac, in bool);
/*  void manualAssignment(in Ac);
 *  void become          (in Ac);
 *  void becomeDefault   (in Ac);
 *  void update          (in UpdateArgs);
 *
 *  override void draw();
 */



public:

this(
    Style newStyle,
    int   new_ex,
    int   new_ey
) {
    super(getLixSpritesheet(newStyle), groundMap,
          even(new_ex) - exOffset, new_ey - eyOffset);
    _style  = newStyle;
    _perfAc = PerformedActivity.factory(this, Ac.FALLER);
    frame   = 4;
    // important for torus bitmaps: calculate modulo in time
    ex = new_ex.even;
    ey = new_ey;
}



this(in Lixxie rhs)
{
    assert (rhs !is null);

    _style = rhs._style;
    _ex    = rhs._ex;
    _ey    = rhs._ey;

    _facingLeft = rhs._facingLeft;

    super(graphic.gralib.getLixSpritesheet(_style), groundMap,
        _ex - exOffset, _ey - eyOffset);

    _flingX = rhs._flingX;
    _flingY = rhs._flingY;
    _flingNew         = rhs._flingNew;
    _flingBySameTribe = rhs._flingBySameTribe;

    _encBody = rhs._encBody;
    _encFoot = rhs._encFoot;

    queue    = rhs.queue;
    marked   = rhs.marked;

    abilityToRun   = rhs.abilityToRun;
    abilityToClimb = rhs.abilityToClimb;
    abilityToFloat = rhs.abilityToFloat;

    updatesSinceBomb  = rhs.updatesSinceBomb;
    exploderKnockback = rhs.exploderKnockback;

    _perfAc = rhs._perfAc.cloneAndBindToLix(this);
}



static void setStaticMaps(Torbit* tb, Lookup* lo, Map ma)
{
    land = tb;
    lookup = lo;
    groundMap = ma;
}



private XY getFuseXY() const
{
    XY ret = countdown.get(frame, ac);
    if (_facingLeft)
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
ex(in int n) {
    _ex = basics.help.even(n);
    super.x = _ex - exOffset;
    if (groundMap.torusX)
        _ex = positiveMod(_ex, land.xl);
    addEncountersFromHere();
    return _ex;
}



@property int
ey(in int n) {
    _ey = n;
    super.y = _ey - eyOffset;
    if (groundMap.torusY)
        _ey = positiveMod(_ey, land.yl);
    addEncountersFromHere();
    return _ey;
}



void moveAhead(int plusX = 2)
{
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
    return groundMap.isPointInRectangle(ex, ey,
        g.x + g.tile.triggerX(), g.y + g.tile.triggerY(),
              g.tile.triggerXl,        g.tile.triggerYl);
}



void addFling(in int px, in int py, in bool same_tribe)
{
    if (_flingBySameTribe && same_tribe) return;

    _anyNewFlingers    = true;
    _flingBySameTribe = (_flingBySameTribe || same_tribe);
    _flingNew = true;
    _flingX   += px;
    _flingY   += py;
}



void resetFlingNew()
{
    _anyNewFlingers   = false;
    _flingNew         = false;
    _flingBySameTribe = false;
    _flingX           = 0;
    _flingY           = 0;
}



bool getSteel(in int px, in int py)
{
    return lookup.getSteel(_ex + px * dir, _ey + py);
}



static bool getSteelAbsolute(in int x, in int y)
{
    return lookup.getSteel(x, y);
}



void addLand(in int px, in int py, const AlCol col)
{
    addLandAbsolute(_ex + px * dir, _ey + py, col);
}



// this one could be static
void addLandAbsolute(in int x = 0, in int y = 0, in AlCol col = color.transp)
{
    // DTODOVRAM: land.setPixel should be very slow, think hard
    land.setPixel(x, y, col);
    lookup.add   (x, y, Lookup.bitTerrain);
}



bool isSolid(in int px = 0, in int py = 2)
{
    return lookup.getSolidEven(_ex + px * dir, _ey + py);
}



bool isSolidSingle(in int px = 0, in int py = 2)
{
    return lookup.getSolid(_ex + px * dir, _ey + py);
}



int solidWallHeight(in int px = 0, in int py = 0)
{
    int solid = 0;
    for (int i = 1; i > -12; --i) {
        if (isSolid(px, py + i)) ++solid;
        else break;
    }
    return solid;
}



int countSolid(int x1, int y1, int x2, int y2)
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



int countSteel(int x1, int y1, int x2, int y2)
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



// ############################################################################
// ############# finished with the removal functions, now the drawing functions
// ############################################################################



bool removePixel(int px, in int py)
{
    // this amendmend is only in drawPixel() and removePixel()
    if (_facingLeft) --px;

    // test whether the landscape can be dug
    if (! getSteel(px, py) && isSolid(px, py)) {
        lookup.rm    (_ex + px * dir, _ey + py, Lookup.bitTerrain);
        land.setPixel(_ex + px * dir, _ey + py, color.transp);
        return false;
    }
    // Stahl?
    else if (getSteel(px, py)) return true;
    else return false;
}



void removePixelAbsolute(in int x, in int y)
{
    if (! getSteelAbsolute(x, y) && lookup.getSolid(x, y)) {
        lookup.rm(x, y, Lookup.bitTerrain);
        land.setPixel(x, y, color.transp);
    }
}



bool removeRectangle(int x1, int y1, int x2, int y2)
{
    if (x2 < x1) swap(x1, x2);
    if (y2 < y1) swap(y1, y2);
    bool ret = false;
    for (int ix = x1; ix <= x2; ++ix) {
        for (int iy = y1; iy <= y2; ++iy) {
            // return true if at least one pixel has been steel
            if (removePixel(ix, iy)) ret = true;
        }
    }
    return ret;
}



// like removePixel
void drawPixel(int px, in int py, in AlCol col)
{
    // this amendmend is only in drawPixel() and removePixel()
    if (_facingLeft) --px;

    if (! isSolidSingle(px, py)) addLand(px, py, col);
}



void drawRectangle(int x1, int y1, int x2, int y2, in AlCol col)
{
    if (x2 < x1) swap(x1, x2);
    if (y2 < y1) swap(y1, y2);
    for (int ix = x1; ix <= x2; ++ix)
        for (int iy = y1; iy <= y2; ++iy)
            drawPixel(ix, iy, col);
}



void drawBrick(int x1, int y1, int x2, int y2)
{
    assert (false, "DTODO: implement lixxie.drawBrick. Cache the colors!");
    /*
    const int col_l = get_cutbit()->get_pixel(19, LixEn::BUILDER - 1, 0, 0);
    const int col_m = get_cutbit()->get_pixel(20, LixEn::BUILDER - 1, 0, 0);
    const int col_d = get_cutbit()->get_pixel(21, LixEn::BUILDER - 1, 0, 0);

    draw_rectangle(x1 + (dir<0), y1, x2 - (dir>0), y1, col_l);
    draw_rectangle(x1 + (dir>0), y2, x2 - (dir<0), y2, col_d);
    if (dir > 0) {
        draw_pixel(x2, y1, col_m);
        draw_pixel(x1, y2, col_m);
    }
    else {
        draw_pixel(x1, y1, col_m);
        draw_pixel(x2, y2, col_m);
    }
    */
}



// Draws the the rectangle specified by xs, ys, ws, hs of the
// specified animation frame onto the level map at position (xd, yd),
// as diggable terrain. (xd, yd) specifies the top left of the destination
// rectangle relative to the lix's position
void drawFrameToMapAsTerrain
(
    int frame, int anim,
    int xs, int ys, int ws, int hs,
    int xd, int yd
) {
    assert (false, "DTODO: implement this function (as terrain => speed!");
    /*
    for (int y = 0; y < hs; ++y) {
        for (int x = 0; x < ws; ++x) {
            const AlCol col = get_cutbit().get_pixel(frame, anim, xs+x, ys+y);
            if (col != color.transp && ! getSteel(xd + x, yd + y)) {
                addLand(xd + x, yd + y, col);
            }
        }
    }
    */
}



void playSound(in ref UpdateArgs ua, in Sound soundID)
{
    assert (effect);
    effect.addSound(ua.state.update, ua.tribe, ua.id, soundID);
}



void playSoundIfTribeLocal(in ref UpdateArgs ua, in Sound soundID)
{
    assert (effect);
    effect.addSoundIfTribeLocal(ua.state.update, ua.tribe, ua.id, soundID);
}



override bool isLastFrame() const
{
    return ! cutbit.frameExists(frame + 1, ac);
}



void advanceFrame()
{
    frame = (isLastFrame() ? 0 : frame + 1);
}



deprecated("use Lix.draw(), not Lix.draw(Torbit)")
override void draw(Torbit) const { }

void draw()
{
    if (ac == Ac.NOTHING) return;

    super.xf = frame;
    super.yf = ac;

    // draw the fuse if necessary
    if (updatesSinceBomb > 0) {
        immutable XY fuseXy = getFuseXY();
        immutable int fuseX = fuseXy.x;
        immutable int fuseY = fuseXy.y;

        // draw onto this
        Torbit tb = groundMap;

        int x = 0;
        int y = 0;
        for (; -y < (updatesForBomb - updatesSinceBomb)/5+1; --y) {
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
        cb.draw(groundMap,
         fuseX + x - cb.xl/2,
         fuseY + y - cb.yl/2,
         updatesSinceBomb % cb.xfs, 0);
    }
    // end of drawing the fuse

    // Mirror flips vertically. Therefore, when _facingLeft, we have to rotate
    // by 180 degrees in addition.
    mirror   =     _facingLeft;
    rotation = 2 * _facingLeft;
    Graphic.draw(groundMap);
}


// ############################################################################
// ######################### click priority -- was lix/lix_ac.cpp in C++/A4 Lix
// ############################################################################



bool cursorShouldOpenOverMe() const
{
    return ac != Ac.NOTHING && ! _perfAc.isLeaving;
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
    if ((newAc == Ac.EXPLODER  && updatesSinceBomb > 0)
     || (newAc == Ac.EXPLODER2 && updatesSinceBomb > 0)
     || (newAc == Ac.RUNNER    && abilityToRun)
     || (newAc == Ac.CLIMBER   && abilityToClimb)
     || (newAc == Ac.FLOATER   && abilityToFloat) ) return 1;

    switch (ac) {
        // When a blocker shall be freed/exploded, the blocker has extremely
        // high priority, more than anything else on the field.
        case Ac.BLOCKER:
            if (newAc == Ac.WALKER
             || newAc == Ac.EXPLODER
             || newAc == Ac.EXPLODER2) p = 5000;
            else return 1;
            break;

        // Stunners/ascenders may be turned in their later frames, but
        // otherwise act like regular mostly unassignable-to acitivities
        case Ac.STUNNER:
            if (frame >= 16) {
                p = 3000;
                break;
            }
            else goto GOTO_TARGET_FULL_ATTENTION;

        case Ac.ASCENDER:
            if (frame >= 5) {
                p = 3000;
                break;
            }
            else goto GOTO_TARGET_FULL_ATTENTION;

        // further activities that take all of the lix's attention; she
        // canot be assigned anything except permanent skills
        case Ac.FALLER:
        case Ac.TUMBLER:
        case Ac.CLIMBER:
        case Ac.FLOATER:
        case Ac.JUMPER:
        GOTO_TARGET_FULL_ATTENTION:
            if (newAc == Ac.RUNNER
             || newAc == Ac.CLIMBER
             || newAc == Ac.FLOATER
             || newAc == Ac.EXPLODER
             || newAc == Ac.EXPLODER2) p = 2000;
            else return 1;
            break;

        // standard activities, not considered working lixes
        case Ac.WALKER:
        case Ac.LANDER:
        case Ac.RUNNER:
            p = 3000;
            break;

        // builders and platformers can be queued. Use the personal variable
        // to see whether we should read the user's setting. If false, we're
        // having a replay or multiplayer game, and then queuing must work
        // even if the user has disabled it for themselves.
        case Ac.BUILDER:
        case Ac.PLATFORMER:
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
    p += (newAc == Ac.BATTER && batterPriority
          ? (- updatesSinceBomb) : updatesSinceBomb);
    p += 400 * abilityToRun + 200 * abilityToClimb + 100 * abilityToFloat;
    return p;
}



// ############################################################################
// ############### skill function dispatch -- was lix/acFunc.cpp in C++/A4 Lix
// ############################################################################



void become(bool manualAssignment = false)(in Ac newAc)
{
    assert (_perfAc);
    auto oldPerf = _perfAc;
    auto newPerf = PerformedActivity.factory(this, newAc);

    if (newPerf.callBecomeAfterAssignment)
        _perfAc.onBecomingSomethingElse();

    static if (manualAssignment)
        newPerf.onManualAssignment(); // while Lix still has old performed ac

    // Reset sprite placement like climber's offset in x-direction by 1.
    // This is the same code as the sprite placement in set_ex/ey().
    super.x = _ex - exOffset;
    super.y = _ey - eyOffset;

    if (_perfAc.ac != newPerf.ac
        && (newPerf.callBecomeAfterAssignment || ! manualAssignment)
    ) {
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



void assignManually(in Ac newAc)
{
    become!true(newAc);
}



void performActivity(UpdateArgs ua)
{
    assert (_perfAc);
    _perfAc.performActivity(ua);
}

}
// end class Lixxie
