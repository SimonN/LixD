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
    int  _dir;

    Tribe _tribe;

    int  _flingX;
    int  _flingY;
    bool _flingNew;
    bool _flingBySameTribe;

    static bool _anyNewFlingers;

    int  _frame;

    Lookup.LoNr _encBody;
    Lookup.LoNr _encFoot;

    Style _style;
    Ac    _ac;

    void draw_at(const int, const int);

public:

    static immutable int distanceSafeFall = 126;
    static immutable int distanceFloat    =  60;
    static immutable int updatesForBomb   =  75;

    static Torbit*       land;
    static Lookup*       lookup;
    static Map           groundMap;
    static EffectManager effect;

    int queue; // builders and platformers can be queued in advance

    bool marked; // used by the game class, marks if already updated

    bool runner;
    bool climber;
    bool floater;

    int  updatesSinceBomb;
    bool exploderKnockback;

    SkillFields skillFields; // defined in lix.acfunc
    alias skillFields this;

/*  this(Tribe = null, int = 0, int = 0); // tribe==null ? NOTHING : FALLER
 *  this(in Lixxie rhs);
 *  invariant();
 */
    mixin CloneableBase;

    static bool anyNewFlingers() { return _anyNewFlingers; }

    inout(Tribe) tribe() inout { return _tribe; }
          Style  style() const { return _style; }

    @property int ex() const { return _ex; }
    @property int ey() const { return _ey; }
/*  @property int ex(in int);
 *  @property int ey(in int);
 *
 *  void moveAhead(int = 2);
 *  void moveDown(int = 2);
 *  void moveUp  (int = 2);
 */
    @property int dir() const   { return _dir; }
    @property int dir(in int i) { return _dir = (i>0)?1 : (i<0)?-1 : _dir; }
    void turn()                 { _dir *= -1; }

//  bool get_in_trigger_area(const EdGraphic) const;

    @property Ac ac() const { return _ac; }

    void setAcWithoutCallingBecome(in Ac newAc) { _ac = newAc; }

    @property bool passTop () const { return acFunc[ac].passTop;  }
    @property bool leaving  () const { return acFunc[ac].leaving;   }
    @property bool blockable() const { return acFunc[ac].blockable; }

    @property Sound soundAssign() const { return acFunc[ac].soundAssign; }
    @property Sound soundBecome() const { return acFunc[ac].soundBecome; }

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
    @property int frame() const   { return _frame;     }
    @property int frame(in int i) { return _frame = i; }
/*           void nextFrame();
 *  override bool isLastFrame() const;
 */
    @property auto body_encounters() const        { return _encBody;     }
    @property auto foot_encounters() const        { return _encFoot;     }
    @property auto body_encounters(Lookup.LoNr n) { return _encBody = n; }
    @property auto foot_encounters(Lookup.LoNr n) { return _encFoot = n; }
    void set_no_encounters() { _encBody = _encFoot = 0; }

//  int  get_priority  (in Ac, in bool);
    void evaluate_click(in Ac ac) { assclk(ac); }
/*  void assclk        (in Ac);
 *  void become        (in Ac);
 *  void becomeDefault(in Ac);
 *  void update        (in UpdateArgs);
 *
 *  override void draw();
 */



public:

this(
    Tribe new_tribe,
    int   new_ex,
    int   new_ey
) {
    super(getLixSpritesheet(new_tribe ? new_tribe.style : Style.GARDEN),
          groundMap, even(new_ex) - exOffset, new_ey - eyOffset);
    _tribe = new_tribe;
    _dir   = 1;
    _style = tribe ? tribe.style : Style.GARDEN,
    _ac    = Ac.NOTHING;
    if (_tribe) {
        become(Ac.FALLER);
        _frame = 4;
    }
    // important for torus bitmaps: calculate modulo in time
    ex = new_ex.even;
    ey = new_ey;
}



this(Lixxie rhs)
{
    assert (rhs !is null);

    _tribe = rhs._tribe;
    _dir   = rhs._dir;
    _style = rhs._style;
    _ac    = rhs._ac;
    _frame = rhs._frame;
    _ex    = rhs._ex;
    _ey    = rhs._ey;

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

    runner   = rhs.runner;
    climber  = rhs.climber;
    floater  = rhs.floater;

    updatesSinceBomb  = rhs.updatesSinceBomb;
    exploderKnockback = rhs.exploderKnockback;
    skillFields       = rhs.skillFields;
}



invariant()
{
    assert (_dir == -1 || _dir == 1);
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
    if (_dir < 0)
        ret.x = this.cutbit.xl - ret.x;
    ret.x += super.x;
    ret.y += super.y;
    return ret;
}



@property int
ex(in int n) {
    _ex = basics.help.even(n);
    super.x = _ex - exOffset;
    if (groundMap.torusX)
        _ex = positiveMod(_ex, land.xl);
    immutable XY fuseXy = getFuseXY();
    _encFoot |= lookup.get(_ex, _ey);
    _encBody |= _encFoot
             |  lookup.get(_ex, _ey - 4)
             |  lookup.get(fuseXy.x, fuseXy.y);
    return _ex;
}



@property int
ey(in int n) {
    _ey = n;
    super.y = _ey - eyOffset;
    if (groundMap.torusY)
        _ey = positiveMod(_ey, land.yl);
    immutable XY fuseXy = getFuseXY();
    _encFoot |= lookup.get(_ex, _ey);
    _encBody |= _encFoot
             |  lookup.get(_ex, _ey - 4)
             |  lookup.get(fuseXy.x, fuseXy.y);
    return _ey;
}



void moveAhead(int plusX = 2)
{
    plusX = even(plusX);
    plusX *= _dir;
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
    return lookup.getSteel(_ex + px * _dir, _ey + py);
}



static bool getSteelAbsolute(in int x, in int y)
{
    return lookup.getSteel(x, y);
}



void addLand(in int px, in int py, const AlCol col)
{
    addLandAbsolute(_ex + px * _dir, _ey + py, col);
}



// this one could be static
void addLandAbsolute(in int x = 0, in int y = 0, in AlCol col = color.transp)
{
    // DTODOVRAM: land.setPixel should be very slow, think hard
    land.setPixel(x, y, col);
    lookup.add   (x, y, Lookup.bitTerrain);
}



bool isSolid(in int px, in int py)
{
    return lookup.getSolidEven(_ex + px * _dir, _ey + py);
}



bool isSolidSingle(in int px, in int py)
{
    return lookup.getSolid(_ex + px * _dir, _ey + py);
}



int solidWallHeight(in int px, in int py)
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
    if (_dir < 0) --px;

    // test whether the landscape can be dug
    if (! getSteel(px, py) && isSolid(px, py)) {
        lookup.rm     (_ex + px * _dir, _ey + py, Lookup.bitTerrain);
        land.setPixel(_ex + px * _dir, _ey + py, color.transp);
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
    if (_dir < 0) --px;

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

    draw_rectangle(x1 + (_dir<0), y1, x2 - (_dir>0), y1, col_l);
    draw_rectangle(x1 + (_dir>0), y2, x2 - (_dir<0), y2, col_d);
    if (_dir > 0) {
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
    effect.addSound(ua.st.update, tribe, ua.id, soundID);
}



void playSoundIfTribeLocal(in ref UpdateArgs ua, in Sound soundID)
{
    assert (effect);
    effect.addSoundIfTribeLocal(ua.st.update, tribe, ua.id, soundID);
}



override bool isLastFrame() const
{
    return ! cutbit.frameExists(frame + 1, ac);
}



void nextFrame()
{
    _frame = isLastFrame() ? 0 : _frame + 1;
}



override void draw()
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

    // Mirror flips vertically. Therefore, when _dir < 0, we have to rotate
    // by 180 degrees in addition.
    mirror   =      _dir < 0;
    rotation = 2 * (_dir < 0);
    Graphic.draw();
}


// ############################################################################
// ######################### click priority -- was lix/lix_ac.cpp in C++/A4 Lix
// ############################################################################



// returns 0 iff lix is not clickable and the cursor should be closed
// returns 1 iff lix is not clickable, but the cursor should open still
// returns >= 2 and <= 99,998 iff lix is clickable
// higher return values mean higher priority. The player can invert priority,
// e.g., by holding the right mouse button. This inversion is not handled by
// this function, but should be done by the calling game code.
int get_priority(
    in Ac   newAc,
    in bool personal // Shall personal settings override the default valuation?
) {                  // If false, allow anything anyone could do, for network
    int p = 0;

    // Nothing allowed at all, don't even open the cursor
    if (ac == Ac.NOTHING || acFunc[ac].leaving) return 0;

    // Permanent skills
    if ((newAc == Ac.EXPLODER  && updatesSinceBomb > 0)
     || (newAc == Ac.EXPLODER2 && updatesSinceBomb > 0)
     || (newAc == Ac.RUNNER    && runner)
     || (newAc == Ac.CLIMBER   && climber)
     || (newAc == Ac.FLOATER   && floater) ) return 1;

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
    p += 400 * runner + 200 * climber + 100 * floater;
    return p;
}



// ############################################################################
// ############### skill function dispatch -- was lix/acFunc.cpp in C++/A4 Lix
// ############################################################################



void assclk(in Ac newAc)
{
    immutable Ac oldAc = ac;
    if (acFunc[newAc].assclk)
        acFunc[newAc].assclk(this);
    else
        become(newAc); // this dispatches again

    if (oldAc != ac)
        --_frame;
        // can go to -1, then nothing happens on the
        // next update and frame 0 will be shown then
}



void become(in Ac newAc)
{
    if (newAc != ac && queue > 0) {
        tribe.returnSkills(ac, queue);
        queue = 0; // in case other skill_become() redirect again to become()
    }
    // Reset sprite placement like climber's offset in x-direction by 1,
    // or the digger sprite displacement in one frame. This is the same code
    // as the sprite placement in set_ex/ey().
    super.x = _ex - exOffset;
    super.y = _ey - eyOffset;

    if (acFunc[newAc].become)
        acFunc[newAc].become(this);
    else
        becomeDefault(newAc);
}



void becomeDefault(in Ac newAc)
{
    _frame   = 0;
    _ac      = newAc;
    queue    = 0;
}



void update(in UpdateArgs ua)
{
    if (acFunc[ac].update)
        acFunc[ac].update(this, ua);
}

}
// end class Lixxie
