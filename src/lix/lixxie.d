module lix.lixxie;

import std.algorithm; // swap

import basics.globals; // fuse image
import basics.help;
import basics.matrix;
import basics.user; // multipleBuilders
import game.lookup;
import game.tribe;
import graphic.color;
import graphic.gadget;
import graphic.graphic;
import graphic.gralib;
import graphic.map;
import graphic.torbit;
import hardware.sound;
import lix.enums;
import lix.acfunc;

// import editor.graphed;
// import graphic.graphbg;

// DTODOCOMMENT: add the interesting things from the 150+ line comment in
// C++/A4 Lix's lix/lix.h top comment.

// DTODO: implement these classes
class EffectManager {
    void add_sound        (in int, in Tribe, int, in Sound) { }
    void add_sound_if_trlo(in int, in Tribe, int, in Sound) { }
}

class Lixxie : Graphic {

private:

    int  _ex;
    int  _ey;
    int  _dir;

    Tribe _tribe;

    int  _fling_x;
    int  _fling_y;
    bool _fling_new;
    bool _fling_by_same_tribe;

    static bool _any_new_flingers;

    int  _frame;

    Lookup.LoNr _enc_body;
    Lookup.LoNr _enc_foot;

    Style _style;
    Ac    _ac;

    void draw_at(const int, const int);

public:

    static immutable int distance_safe_fall = 126;
    static immutable int distance_float     =  60;
    static immutable int updates_for_bomb   =  75;

    static Torbit        land;
    static Lookup        lookup;
    static Map           groundMap;
    static EffectManager effect;

    int specialX;
    int specialY;
    int queue; // builders and platformers can be queued in advance

    bool marked; // used by the game class, marks if already updated

    bool runner;
    bool climber;
    bool floater;

    int  updates_since_bomb;
    bool exploder_knockback;



/*  this(Tribe = null, int = 0, int = 0); // tribe==null ? NOTHING : FALLER
 *  this(in Lixxie rhs);
 *  invariant();
 */
    mixin CloneableBase;

    static bool get_any_new_flingers() { return _any_new_flingers; }

    inout(Tribe) tribe() inout { return _tribe; }
          Style  style() const { return _style; }

    @property int ex() const { return _ex; }
    @property int ey() const { return _ey; }
/*  @property int ex(in int);
 *  @property int ey(in int);
 *
 *  void move_ahead(   int = 2);
 *  void move_down (   int = 2);
 *  void move_up   (in int = 2);
 */
    @property int dir() const   { return _dir; }
    @property int dir(in int i) { return _dir = (i>0)?1 : (i<0)?-1 : _dir; }
    void turn()                 { _dir *= -1; }

//  bool get_in_trigger_area(const EdGraphic) const;

    @property Ac ac() const { return _ac; }

    void set_ac_without_calling_become(in Ac new_ac) { _ac = new_ac; }

    @property bool pass_top () const { return ac_func[ac].pass_top;  }
    @property bool leaving  () const { return ac_func[ac].leaving;   }
    @property bool blockable() const { return ac_func[ac].blockable; }

    @property Sound sound_assign() const { return ac_func[ac].sound_assign; }
    @property Sound sound_become() const { return ac_func[ac].sound_become; }

    @property bool fling_new() const { return _fling_new; }
    @property int  fling_x()   const { return _fling_x;   }
    @property int  fling_y()   const { return _fling_y;   }
/*  void add_fling(int, int, bool (from same tribe) = false);
 *  void reset_fling_new();
 *
 *  static bool getSteel_absolute(in int, in int);
 *  bool getSteel         (in int = 0, in int = 0);
 *
 *  void add_land          (in int = 0, in int = 0, in AlCol = color.transp);
 *  void add_land_absolute (in int = 0, in int = 0, in AlCol = color.transp);
 *
 *      don't call add_land from the skills, use draw_pixel. That amends
 *      the x-direction by left-looking lixes by the desired 1 pixel. Kludge:
 *      Maybe remove add_land entirely and put the functionality in draw_pixel?
 *
 *  bool is_solid          (in int = 0, in int = 2);
 *  bool is_solid_single   (in int = 0, in int = 2);
 *  int  solid_wall_height (in int = 0, in int = 0);
 *  int  count_solid       (int, int, int, int);
 *  int  count_steel       (int, int, int, int);
 *
 *  static void remove_pixel_absolute(in int, in int);
 *  bool        remove_pixel         (   int, in int);
 *  bool        remove_rectangle     (int, int, int, int);
 *
 *  void draw_pixel       (int,      in int,   in AlCol);
 *  void draw_rectangle   (int, int, int, int, in AlCol);
 *  void draw_brick       (int, int, int, int);
 *  void draw_frame_to_map(int, int, int, int, int, int, int, int);
 *
 *  void play_sound        (in ref UpdateArgs, in Sound);
 *  void play_sound_if_trlo(in ref UpdateArgs, in Sound);
 */
    @property int frame() const   { return _frame;     }
    @property int frame(in int i) { return _frame = i; }
/*           void next_frame();
 *  override bool isLastFrame() const;
 */
    @property auto body_encounters() const        { return _enc_body;     }
    @property auto foot_encounters() const        { return _enc_foot;     }
    @property auto body_encounters(Lookup.LoNr n) { return _enc_body = n; }
    @property auto foot_encounters(Lookup.LoNr n) { return _enc_foot = n; }
    void set_no_encounters() { _enc_body = _enc_foot = 0; }

//  int  get_priority  (in Ac, in bool);
    void evaluate_click(in Ac ac) { assclk(ac); }
/*  void assclk        (in Ac);
 *  void become        (in Ac);
 *  void become_default(in Ac);
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
          groundMap, even(new_ex) - lix.enums.ex_offset,
                           new_ey  - lix.enums.ey_offset);
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
        _ex - lix.enums.ex_offset,
        _ey - lix.enums.ey_offset);

    _fling_x = rhs._fling_x;
    _fling_y = rhs._fling_y;
    _fling_new           = rhs._fling_new;
    _fling_by_same_tribe = rhs._fling_by_same_tribe;

    _enc_body = rhs._enc_body;
    _enc_foot = rhs._enc_foot;

    specialX = rhs.specialX;
    specialY = rhs.specialY;
    queue     = rhs.queue;
    marked    = rhs.marked;

    runner    = rhs.runner;
    climber   = rhs.climber;
    floater   = rhs.floater;

    updates_since_bomb = rhs.updates_since_bomb;
    exploder_knockback = rhs.exploder_knockback;
}



invariant()
{
    assert (_dir == -1 || _dir == 1);
}



static void set_static_maps(Torbit tb, Lookup lo, Map ma)
{
    land = tb;
    lookup = lo;
    groundMap = ma;
}



private XY get_fuseXy() const
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
    super.x = _ex - lix.enums.ex_offset;
    if (groundMap.torusX)
        _ex = positiveMod(_ex, land.xl);
    immutable XY fuseXy = get_fuseXy();
    _enc_foot |= lookup.get(_ex, _ey);
    _enc_body |= _enc_foot
              |  lookup.get(_ex, _ey - 4)
              |  lookup.get(fuseXy.x, fuseXy.y);
    return _ex;
}



@property int
ey(in int n) {
    _ey = n;
    super.y = _ey - lix.enums.ey_offset;
    if (groundMap.torusY)
        _ey = positiveMod(_ey, land.yl);
    immutable XY fuseXy = get_fuseXy();
    _enc_foot |= lookup.get(_ex, _ey);
    _enc_body |= _enc_foot
              |  lookup.get(_ex, _ey - 4)
              |  lookup.get(fuseXy.x, fuseXy.y);
    return _ey;
}



void move_ahead(int plus_x)
{
    plus_x = even(plus_x);
    plus_x *= _dir;
    // move in little steps, to check for lookupmap encounters on the way
    for ( ; plus_x > 0; plus_x -= 2) ex = (_ex + 2);
    for ( ; plus_x < 0; plus_x += 2) ex = (_ex - 2);
}



void move_down(int plus_y)
{
    for ( ; plus_y > 0; --plus_y) ey = (_ey + 1);
    for ( ; plus_y < 0; ++plus_y) ey = (_ey - 1);
}



void move_up(in int minus_y)
{
    move_down(-minus_y);
}



bool get_in_trigger_area(in Gadget g) const
{
    return groundMap.isPointInRectangle(ex, ey,
        g.x + g.tile.triggerX(), g.y + g.tile.triggerY(),
              g.tile.triggerXl,        g.tile.triggerYl);
}



void add_fling(in int px, in int py, in bool same_tribe)
{
    if (_fling_by_same_tribe && same_tribe) return;

    _any_new_flingers    = true;
    _fling_by_same_tribe = (_fling_by_same_tribe || same_tribe);
    _fling_new = true;
    _fling_x   += px;
    _fling_y   += py;
}



void reset_fling_new()
{
    _any_new_flingers    = false;
    _fling_new           = false;
    _fling_by_same_tribe = false;
    _fling_x             = 0;
    _fling_y             = 0;
}



void evaluate_click(Ac ac)         { assert (false, "DTODO: evaluate_click not impl");      }
int  get_priority  (Ac ac, bool b) { assert (false, "DTODO: get_priority not implemented"); }



bool getSteel(in int px, in int py)
{
    return lookup.getSteel(_ex + px * _dir, _ey + py);
}



static bool getSteel_absolute(in int x, in int y)
{
    return lookup.getSteel(x, y);
}



void add_land(in int px, in int py, const AlCol col)
{
    add_land_absolute(_ex + px * _dir, _ey + py, col);
}



// this one could be static
void add_land_absolute(in int x = 0, in int y = 0, in AlCol col = color.transp)
{
    // DTODOVRAM: land.setPixel should be very slow, think hard
    land.setPixel(x, y, col);
    lookup.add    (x, y, Lookup.bitTerrain);
}



bool is_solid(in int px, in int py)
{
    return lookup.getSolidEven(_ex + px * _dir, _ey + py);
}



bool is_solid_single(in int px, in int py)
{
    return lookup.getSolid(_ex + px * _dir, _ey + py);
}



int solid_wall_height(in int px, in int py)
{
    int solid = 0;
    for (int i = 1; i > -12; --i) {
        if (is_solid(px, py + i)) ++solid;
        else break;
    }
    return solid;
}



int count_solid(int x1, int y1, int x2, int y2)
{
    if (x2 < x1) swap(x1, x2);
    if (y2 < y1) swap(y1, y2);
    int ret = 0;
    for (int ix = basics.help.even(x1); ix <= even(x2); ix += 2) {
        for (int iy = y1; iy <= y2; ++iy) {
            if (is_solid(ix, iy)) ++ret;
        }
    }
    return ret;
}



int count_steel(int x1, int y1, int x2, int y2)
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



bool remove_pixel(int px, in int py)
{
    // this amendmend is only in draw_pixel() and remove_pixel()
    if (_dir < 0) --px;

    // test whether the landscape can be dug
    if (! getSteel(px, py) && is_solid(px, py)) {
        lookup.rm     (_ex + px * _dir, _ey + py, Lookup.bitTerrain);
        land.setPixel(_ex + px * _dir, _ey + py, color.transp);
        return false;
    }
    // Stahl?
    else if (getSteel(px, py)) return true;
    else return false;
}



void remove_pixel_absolute(in int x, in int y)
{
    if (! getSteel_absolute(x, y) && lookup.getSolid(x, y)) {
        lookup.rm(x, y, Lookup.bitTerrain);
        land.setPixel(x, y, color.transp);
    }
}



bool remove_rectangle(int x1, int y1, int x2, int y2)
{
    if (x2 < x1) swap(x1, x2);
    if (y2 < y1) swap(y1, y2);
    bool ret = false;
    for (int ix = x1; ix <= x2; ++ix) {
        for (int iy = y1; iy <= y2; ++iy) {
            // return true if at least one pixel has been steel
            if (remove_pixel(ix, iy)) ret = true;
        }
    }
    return ret;
}



// like remove_pixel
void draw_pixel(int px, in int py, in AlCol col)
{
    // this amendmend is only in draw_pixel() and remove_pixel()
    if (_dir < 0) --px;

    if (! is_solid_single(px, py)) add_land(px, py, col);
}



void draw_rectangle(int x1, int y1, int x2, int y2, in AlCol col)
{
    if (x2 < x1) swap(x1, x2);
    if (y2 < y1) swap(y1, y2);
    for (int ix = x1; ix <= x2; ++ix)
        for (int iy = y1; iy <= y2; ++iy)
            draw_pixel(ix, iy, col);
}



void draw_brick(int x1, int y1, int x2, int y2)
{
    assert (false, "DTODO: implement lixxie.draw_brick. Cache the colors!");
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
void draw_frame_to_map
(
    int frame, int anim,
    int xs, int ys, int ws, int hs,
    int xd, int yd
) {
    assert (false, "DTODO: implement draw_frame_to_map (as terrain => speed!");
    /*
    for (int y = 0; y < hs; ++y) {
        for (int x = 0; x < ws; ++x) {
            const AlCol col = get_cutbit().get_pixel(frame, anim, xs+x, ys+y);
            if (col != color.transp && ! getSteel(xd + x, yd + y)) {
                add_land(xd + x, yd + y, col);
            }
        }
    }
    */
}



void play_sound(in ref UpdateArgs ua, in Sound sound_id)
{
    assert (effect);
    effect.add_sound(ua.st.update, tribe, ua.id, sound_id);
}



void play_sound_if_trlo(in ref UpdateArgs ua, in Sound sound_id)
{
    assert (effect);
    effect.add_sound_if_trlo(ua.st.update, tribe, ua.id, sound_id);
}



override bool isLastFrame() const
{
    return ! cutbit.frameExists(frame + 1, ac);
}



void next_frame()
{
    if (isLastFrame())
        _frame = 0;
    else _frame++;
}



override void draw()
{
    if (ac == Ac.NOTHING) return;

    super.xf = frame;
    super.yf = ac;

    // draw the fuse if necessary
    if (updates_since_bomb > 0) {
        immutable XY fuseXy = get_fuseXy();
        immutable int fuseX = fuseXy.x;
        immutable int fuseY = fuseXy.y;

        // draw onto this
        Torbit tb = groundMap;

        int x = 0;
        int y = 0;
        for (; -y < (updates_for_bomb - updates_since_bomb)/5+1; --y) {
            /*
            // DTODOVRAM: decide on how to draw the pixel-rendered fuse
            const int u = updates_since_bomb;
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
         updates_since_bomb % cb.xfs, 0);
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
    in Ac  new_ac,
    in bool personal // Shall personal settings override the default valuation?
) {                  // If false, allow anything anyone could do, for network
    int p = 0;

    // Nothing allowed at all, don't even open the cursor
    if (ac == Ac.NOTHING || ac_func[ac].leaving) return 0;

    // Permanent skills
    if ((new_ac == Ac.EXPLODER  && updates_since_bomb > 0)
     || (new_ac == Ac.EXPLODER2 && updates_since_bomb > 0)
     || (new_ac == Ac.RUNNER    && runner)
     || (new_ac == Ac.CLIMBER   && climber)
     || (new_ac == Ac.FLOATER   && floater) ) return 1;

    switch (ac) {
        // When a blocker shall be freed/exploded, the blocker has extremely
        // high priority, more than anything else on the field.
        case Ac.BLOCKER:
            if (new_ac == Ac.WALKER
             || new_ac == Ac.EXPLODER
             || new_ac == Ac.EXPLODER2) p = 5000;
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
            if (new_ac == Ac.RUNNER
             || new_ac == Ac.CLIMBER
             || new_ac == Ac.FLOATER
             || new_ac == Ac.EXPLODER
             || new_ac == Ac.EXPLODER2) p = 2000;
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
            if (new_ac == ac
             && (! personal || multipleBuilders)) p = 1000;
            else if (new_ac != ac)                 p = 4000;
            else                                   return 1;
            break;

        // Usually, anything different from the current activity can be assign.
        default:
            if (new_ac != ac) p = 4000;
            else return 1;

    }
    p += (new_ac == Ac.BATTER && batterPriority
          ? (- updates_since_bomb) : updates_since_bomb);
    p += 400 * runner + 200 * climber + 100 * floater;
    return p;
}



// ############################################################################
// ############### skill function dispatch -- was lix/ac_func.cpp in C++/A4 Lix
// ############################################################################



void assclk(in Ac new_ac)
{
    immutable Ac old_ac = ac;
    if (ac_func[new_ac].assclk) ac_func[new_ac].assclk(this);
    else                        become(new_ac); // this dispatches again

    if (old_ac != ac) --_frame; // can go to -1, then nothing happens on the
                                // next update and frame 0 will be shown then
}



void become(in Ac new_ac)
{
    if (new_ac != ac && queue > 0) {
        tribe.returnSkills(ac, queue);
        queue = 0; // in case other skill_become() redirect again to become()
    }
    // Reset sprite placement like climber's offset in x-direction by 1,
    // or the digger sprite displacement in one frame. This is the same code
    // as the sprite placement in set_ex/ey().
    super.x = _ex - lix.enums.ex_offset;
    super.y = _ey - lix.enums.ey_offset;

    if (ac_func[new_ac].become) ac_func[new_ac].become(this);
    else                        become_default(new_ac);
}



void become_default(in Ac new_ac)
{
    _frame    = 0;
    _ac       = new_ac;
    specialY = 0;
    specialX = 0;
    queue     = 0;
}



void update(in UpdateArgs ua)
{
    if (ac_func[ac].update) ac_func[ac].update(this, ua);
}

}
// end class Lixxie
