module physics.physdraw;

/* PhysicsDrawer: responsible for adding/removing terrain on the level torbit
 * during a game. This doesn't render the level at start of game.
 *
 * Has capabilities to cache drawing instructions and then perform then all
 * at once. Drawing to torbit can be disabled, to get only drawing onto the
 * lookup map, for automatic replay verification.
 *
 * All lix styles share one large source VRAM bitmap with the masks and bricks
 * in their many colors.
 *
 * Convention in storing coordinates: Lix activities are expected to pass
 * the coordinates of the terrain changes' top-left corners. They do not pass
 * their own ex/ey. This is different from what Lix do for effects stored
 * in the EffectManager.
 */

import std.array;
import std.algorithm;
import std.conv;
import std.functional;
import std.range;
import std.string;

import enumap;

import basics.alleg5;
import basics.cmdargs;
import basics.help;
import net.repdata;
import tile.phymap;
import graphic.color;
import graphic.cutbit;
import graphic.torbit;
import graphic.internal; // must be initialized first
import hardware.tharsis;
import net.ac;
import net.style;
import physics.job.cuber; // Cuber.cubeSize
import physics.job.digger; // diggerTunnelWidth
import physics.mask;
import physics.terchang;

void initialize() { PhysicsDrawer.initialize(); }
void deinitialize() { PhysicsDrawer.deinitialize(); }

class PhysicsDrawer {

    this(Torbit land, Phymap lookup)
    {
        _land   = land;
        _phymap = lookup;
        assert (_phymap, "_land may be null, but not _phymap");
    }

    void dispose()
    {
        if (_land)
            _land.dispose();
        _land   = null;
        _phymap = null;
    }

    void add(in TerrainAddition tc) { _addsForPhymap ~= tc; }
    void add(in TerrainDeletion tc) { _delsForPhymap ~= tc; }

    // This should be called when loading a savestate, to throw away any
    // queued drawing changes to the land. The savestate comes with a fresh
    // copy of the land that must be registered here.
    void
    rebind(Torbit newLand, Phymap newPhymap)
    in {
        assert (_land, "You want to reset the draw-to-land queues, but you "
            ~ "haven't registered a land to draw to during construction "
            ~ "of PhysicsDrawer.");
        assert (newLand);
        assert (newPhymap);
        assert (_addsForPhymap == null);
        assert (_delsForPhymap == null);
    }
    do {
        _land        = newLand;
        _phymap      = newPhymap;
        _addsForLand = null;
        _delsForLand = null;
    }

    void
    applyChangesToPhymap()
    {
        deletionsToPhymap();
        additionsToPhymap();
    }

    @property bool
    anyChangesToLand()
    {
        return _delsForLand != null || _addsForLand != null;
    }

    // The single public function for any drawing to the land.
    // Should be understandable from the many asserts, otherwise ask me.
    // You should know what a lookup map is (class Phymap from tile.phymap).
    // _land is the torus bitmap onto which we draw the terrain, but this
    // is never queried for physics -- that's what the lookup map is for.
    // in Phyu upd: Pass current update of the game to this.
    void
    applyChangesToLand(in Phyu upd)
    in {
        assert (_land);
        enum msg = "You shouldn't draw to land when you still have changes "
            ~ "to be drawn to the lookup map. You may want to call "
            ~ "applyChangesToPhymap() more often.";
        assert (_delsForPhymap == null, msg);
        assert (_addsForPhymap == null, msg);
        enum msg2 = "applyChangesToLand() doesn't get called each update. "
            ~ "But there should never be something in there that isn't to be "
            ~ "processed during this call.";
        assert (_delsForLand == null || _delsForLand[$-1].update <= upd, msg2);
        assert (_addsForLand == null || _addsForLand[$-1].update <= upd, msg2);
    }
    out {
        assert (_delsForLand == null);
        assert (_addsForLand == null);
    }
    do {
        if (! anyChangesToLand)
            return;

        version (tharsisprofiling)
            auto zone = Zone(profiler, "applyChangesToLand >= 1");
        auto target = TargetTorbit(_land);

        while (_delsForLand != null || _addsForLand != null) {
            // Do deletions for the first update, then additions for that,
            // then deletions for the next update, then additions, ...
            immutable Phyu earliestPhyu
                = _delsForLand != null && _addsForLand != null
                ? min(_delsForLand[0].update, _addsForLand[0].update)
                : _delsForLand != null
                ? _delsForLand[0].update : _addsForLand[0].update;

            deletionsToLandForPhyu(earliestPhyu);
            additionsToLandForPhyu(earliestPhyu);
        }
    }



// ############################################################################
// ############################################################################
// ############################################################################



private:

    static Albit _mask;

    // this enumap is used by the terrain removers, not by the styled adders
    static Enumap!(TerrainDeletion.Type, Albit) _subAlbits;

    Torbit _land;
    Phymap _phymap;

    TerrainDeletion[] _delsForPhymap;
    TerrainAddition[] _addsForPhymap;

    FlaggedDeletion[] _delsForLand;
    FlaggedAddition[] _addsForLand;

    enum buiY  = 0;
    enum cubeY = 3 * net.ac.brickYl;
    enum remY  = cubeY + Cuber.cubeSize;
 	enum remYl = 32;
    enum ploY  = remY + remYl;
    static ploYl() { return physics.mask.masks[TerrainDeletion.Type.implode]
                        .solid.yl; }

    enum bashX  = Digger.tunnelWidth + 1;
    static bashXl() { return physics.mask.masks[TerrainDeletion.Type.bashRight]
                        .solid.xl + 1; }
    static mineX() { return bashX + 4 * bashXl; } // 4 basher masks
    static mineXl() { return physics.mask.masks[TerrainDeletion.Type.mineRight]
                        .solid.xl + 1; }
    enum implodeX = 0;
    static explodeX() { return physics.mask.masks[TerrainDeletion.Type.implode]
                        .solid.xl + 1; }

    static void
    deinitialize()
    {
        foreach (enumVal, ref Albit sub; _subAlbits)
            if (sub !is null) {
                albitDestroy(sub);
                sub = null;
            }
        if (_mask) {
            albitDestroy(_mask);
            _mask = null;
        }
    }

    mixin template AdditionsDefs() {
        immutable build = (tc.type == TerrainAddition.Type.build);
        immutable plaLo = (tc.type == TerrainAddition.Type.platformLong);
        immutable plaSh = (tc.type == TerrainAddition.Type.platformShort);
        immutable yl = (build || plaLo || plaSh) ? net.ac.brickYl
                                                 : tc.cubeYl;
        immutable y  = build ? 0
                     : plaLo ? 1 * net.ac.brickYl
                     : plaSh ? 2 * net.ac.brickYl
                     : cubeY + Cuber.cubeSize - yl;
        immutable xl = build ? net.ac.builderBrickXl
                     : plaLo ? net.ac.platformLongXl
                     : plaSh ? net.ac.platformShortXl
                     :         Cuber.cubeSize;
        immutable x  = xl * tc.style;
    }

    void assertChangesForLand(T)(T[] arr, in Phyu upd)
    {
        // Functions calling assertChangesForLand need not be called on each
        // update, but only if the land must be drawn like it should appear
        // now. In noninteractive mode, this shouldn't be called at all.
        assert (_land);
        assert (_mask);
        assert (isSorted!"a.update < b.update"(arr));
        assert (arr == null || arr[0].update >= upd, format("There are "
            ~ "additions to the land that should be drawn in the earlier "
            ~ "update %d. Right now we have update %d. If this happens after "
            ~ "loading a savestate, empty all queued additions/deletions.",
            arr[0].update, upd));
        assert (al_get_target_bitmap() == _land.albit, "For performance, "
            ~ "set the drawing target to _land outside of *ToLandForPhyu(). "
            ~ "Slow performance is a logic bug!");
    }

    T[] splitOffFromArray(T)(ref T[] arr, in Phyu upd)
    {
        // Split the queue into what needs to be processed during this call,
        // remove these from the caller's queue (arr).
        int cut = 0;
        while (cut < arr.length && arr[cut].update == upd)
            ++cut;
        auto ret = arr[0 .. cut];
        arr      = arr[cut .. $];
        return ret;
    }



// ############################################################################
// ############################################################################
// ############################################################################



    void deletionsToPhymap()
    in { assert (_delsForPhymap.all!(tc =>
        tc.update == _delsForPhymap[0].update));
    }
    out { assert (_delsForPhymap == null); }
    do {
        version (tharsisprofiling)
            auto zone = Zone(profiler, format("PhysDraw del lookup %dx",
                _delsForPhymap.len));
        scope (exit)
            _delsForPhymap = null;

        foreach (const tc; _delsForPhymap) {
            version (tharsisprofiling)
                auto zone2 = Zone(profiler, format("PhysDraw lookup %s",
                    tc.type.to!string));
            int steelHit = 0;
            if (tc.type == TerrainDeletion.Type.dig)
                steelHit = diggerAntiRazorsEdge!true(tc);
            else
                steelHit += _phymap.setAirCountSteelEvenWhereMaskIgnores(
                                tc.loc, masks[tc.type]);
            if (_land)
                _delsForLand ~= FlaggedDeletion(tc, steelHit > 0);
        }
    }

    // The digger can't call the regular setAirCountSteel in a rectangle.
    // Reason: Steel in pixel p affects whether the digger tries to remove
    // earth in a pixel p' left or right of p.
    // As usualy, any steel in the mask requires the land-drawing later to
    // draw pixel-by-pixel. But for the digger, even the land-drawing must
    // go through diggerAntiRazorsEdge again if it's pixel-by-pixel!
    bool diggerAntiRazorsEdge(bool toPhymap, T)(in T tc)
        if (is (T == TerrainDeletion) || is (T == FlaggedDeletion))
    in { assert (tc.type == TerrainDeletion.Type.dig); }
    do {
        bool ret = false;
        Point p;
        for (p.y = 0; p.y < tc.digYl; ++p.y) {
            enum string digCheck = toPhymap ? q{
                if (_phymap.setAirCountSteel(tc.loc + p)) {
                    ret = true;
                    break;
                }
            } : q{
                if (_phymap.getSteel(tc.loc + p))
                    break;
                // Assume we're in subtractive drawing mode: white erases
                auto wrapped = _land.wrap(tc.loc + p);
                al_draw_pixel(wrapped.x + 0.5f, wrapped.y + 0.5f, color.white);
            };
            enum int half = Digger.tunnelWidth / 2;
            for (p.x = half - 1; p.x >= 0; --p.x) { mixin(digCheck); }
            for (p.x = half; p.x < 2*half; ++p.x) { mixin(digCheck); }
        }
        return ret;
    }

    void deletionsToLandForPhyu(in Phyu upd)
    in { assertChangesForLand(_delsForLand, upd); }
    out {
        assert (_delsForLand == null
            ||  _delsForLand[0].update > upd);
    }
    do {
        auto processThese = splitOffFromArray(_delsForLand, upd);
        if (processThese == null)
            return;
        version (tharsisprofiling)
            auto zone = Zone(profiler, format("PhysDraw del land %dx",
                processThese.len));
        with (BlenderMinus) {
            al_hold_bitmap_drawing(true);
            scope (exit)
                al_hold_bitmap_drawing(false);
            foreach (const tc; processThese)
                deletionToLand(tc);
        }
    }

    void deletionToLand(in FlaggedDeletion tc)
    {
        assert (al_is_bitmap_drawing_held());
        version (tharsisprofiling)
            auto zone = Zone(profiler, format("PhysDraw land %s",
                tc.type.to!string));
        if (tc.type != TerrainDeletion.Type.dig)
            spriteToLand(tc, _subAlbits[tc.type]);
        else if (tc.drawPerPixelDueToSteel)
            diggerAntiRazorsEdge!false(tc);
        else {
            // digging height is variable length. Generate correct bitmap.
            assert (tc.type == TerrainDeletion.Type.dig);
            assert (tc.digYl > 0);
            Albit sprite = al_create_sub_bitmap(_mask,
                0, remY, Digger.tunnelWidth, tc.digYl);
            spriteToLand(tc, sprite);
            albitDestroy(sprite);
        }
    }

    void spriteToLand(T)(in T tc, Albit sprite)
        if (is (T == FlaggedDeletion) || is (T == FlaggedAddition))
    {
        assert (al_is_bitmap_drawing_held());
        assert (_land.isTargetTorbit);
        assert (sprite);
        assert (_phymap);
        static if (is (T == FlaggedDeletion))
            immutable bool allAtOnce = ! tc.drawPerPixelDueToSteel;
        else
            immutable bool allAtOnce = ! tc.drawPerPixelDueToExistingTerrain;
        if (allAtOnce) {
            version (tharsisprofiling)
                auto zone = Zone(profiler, format("PhysDraw pix-all %s",
                                                  tc.type.to!string));
            sprite.drawToTargetTorbit(tc.loc);
            return;
        }
        // We continue here only if we must draw per pixel, not all at once.
        // We aren't a digger: Per-pixel-diggers don't even enter
        // spriteToLand, instead they're dispatched by deletionToLand
        // directly to the digger-anti-razor-edging.
        version (tharsisprofiling)
            auto zone = Zone(profiler, format("PhysDraw pix-one %s",
                                              tc.type.to!string));
        foreach (y; 0 .. sprite.yl)
            foreach (x; 0 .. sprite.xl) {
                immutable fromPoint = Point(x, y);
                immutable toPoint   = tc.loc + fromPoint;
                static if (is (T == FlaggedDeletion)) {
                    if (! _phymap.getSteel(toPoint))
                        sprite.singlePixelToTargetTorbit(fromPoint, toPoint);
                }
                else {
                    if (tc.needsColoring[y][x])
                        sprite.singlePixelToTargetTorbit(fromPoint, toPoint);
                }
            }
    }

// ############################################################################
// ############################################################################
// ############################################################################



    void
    additionsToPhymap()
    in { assert(_addsForPhymap.all!(
        tc => tc.update == _addsForPhymap[0].update));
    }
    out {
        assert (_addsForPhymap == null);
    }
    do {
        foreach (const tc; _addsForPhymap) {
            version (tharsisprofiling)
                auto zone = Zone(profiler, "PhysDraw lookupmap "
                                           ~ tc.type.to!string);
            mixin AdditionsDefs;
            assert (yl > 0, format("%s queued with yl <= 0; yl = %d",
                tc.type.to!string, yl));
            // If land exists, remember the changes to be able to draw them
            // later. No land in noninteractive mode => needn't save this.
            // We still create it properly... to keep my code short. <_<;;
            auto fc = FlaggedAddition(tc);
            foreach (int y; 0 .. yl)
                foreach (int x; 0 .. xl) {
                    Point target = tc.loc + Point(x, y);
                    if (_phymap.getSolid(target))
                        fc.drawPerPixelDueToExistingTerrain = true;
                    else {
                        _phymap.add(target, Phybit.terrain);
                        fc.needsColoring[y][x] = true;
                    }
                }
            if (_land)
                _addsForLand ~= fc;
        }
        _addsForPhymap = null;
    }

    void additionsToLandForPhyu(in Phyu upd)
    in { assertChangesForLand(_addsForLand, upd); }
    out {
        assert (_addsForLand == null
            ||  _addsForLand[0].update > upd);
    }
    do {
        auto processThese = splitOffFromArray(_addsForLand, upd);
        if (processThese == null)
            return;
        al_hold_bitmap_drawing(true);
        scope (exit)
            al_hold_bitmap_drawing(false);
        foreach (const tc; processThese) {
            mixin AdditionsDefs;
            Albit sprite = al_create_sub_bitmap(_mask, x, y, xl, yl);
            spriteToLand(tc, sprite);
            albitDestroy(sprite);
        }
    }



// ############################################################################
// ############################################################################
// ############################################################################



    // Blergh function, it's gotten too long. It generates several masks
    // and colorful bricks on the (_mask) bitmap. Maybe outsource to extra
    // file and refactor into smaller private functions.
    static void
    initialize()
    {
        // We need this only during Runmode.INTERACTIVE.
        // We don't need blittable VRAM bitmaps of the various masks.
        // Physics are in RAM entirely, physics masks are done by CTFE.
        version (tharsisprofiling)
            auto zoneInitialize = Zone(profiler, "physDraw initialize");
        assert (! _mask, "don't call physdraw.initialize() twice,"
            ~ " deinitialize first before you call this a second time");
        assert (masks.length, "please initialize game.masks before this");
        alias Type = TerrainDeletion.Type;
        alias rf   = al_draw_filled_rectangle;

        assert (builderBrickXl >= platformLongXl);
        assert (builderBrickXl >= platformShortXl);
        _mask = albitCreate(0x100, 0x80);
        assert (_mask, "couldn't create mask bitmap");

        auto targetBitmap = TargetBitmap(_mask);
        al_clear_to_color(color.transp);

        const recol = InternalImage.styleRecol.toCutbit.albit;
        if (! recol) {
            import basics.globals : dirDataBitmap;
            throw new Exception("We lack the recoloring bitmap. "
                ~ "Is Lix installed properly? We're looking for: "
                ~ InternalImage.styleRecol.toLoggableName);
        }
        assert (recol.xl >= 3);

        auto lockRecol = LockReadOnly(recol);

        void drawBrick(in int x, in int y, in int xl,
            in Alcol light, in Alcol medium, in Alcol dark
        ) {
            alias yl = brickYl;
            rf(x,      y,      x+xl-1, y+1,  light);  // L L L L L M
            rf(x+1,    y+yl-1, x+xl,   y+yl, dark);   // M D D D D D
            rf(x,      y+yl-1, x+1,    y+yl, medium); // ^
            rf(x+xl-1, y,      x+xl,   y+1,  medium); //           ^
        }

        void drawCube(in int x, in int y,
            in Alcol light, in Alcol medium, in Alcol dark
        ) {
            alias l = Cuber.cubeSize;
            assert (l >= 10);
            rf(x, y, x+l, y+l, medium);

            void symmetrical(in int ax,  in int ay,
                             in int axl, in int ayl, in Alcol col)
            {
                rf(x + ax, y + ay, x + ax + axl, y + ay + ayl, col);
                rf(x + ay, y + ax, x + ay + ayl, y + ax + axl, col);
            }
            symmetrical(0, 0, l-1, 1, light);
            symmetrical(0, 1, l-2, 1, light);

            symmetrical(2, l-2, l-2, 1, dark);
            symmetrical(1, l-1, l-1, 1, dark);

            enum o  = 4; // offset of inner relief square from edge
            enum ol = l - 2*o - 1; // length of a single inner relief line
            symmetrical(o,   o,     ol, 1, dark);
            symmetrical(o+1, l-o-1, ol, 1, light);
        }

        // the first row of recol contains the file colors, then come several
        // rows, one per style < MAX.
        for (int i = 0; i < Style.max && i < recol.yl + 1; ++i) {
            Alcol getCol(in int x)
            {
                // DALLEGCONST: Function is not const-correct, we have to cast.
                return al_get_pixel(cast (Albit) recol, x, i+1);
            }
            drawBrick(i * builderBrickXl, 0, builderBrickXl,
                getCol(recol.xl - 3),
                getCol(recol.xl - 2),
                getCol(recol.xl - 1));
            drawBrick(i * platformLongXl, brickYl, platformLongXl,
                getCol(recol.xl - 3),
                getCol(recol.xl - 2),
                getCol(recol.xl - 1));
            drawBrick(i * platformShortXl, 2 * brickYl, platformShortXl,
                getCol(recol.xl - 3),
                getCol(recol.xl - 2),
                getCol(recol.xl - 1));
            drawCube(i * Cuber.cubeSize, cubeY,
                getCol(recol.xl - 3),
                getCol(recol.xl - 2),
                getCol(recol.xl - 1));
        }

        // digger swing
        rf(0, remY, Digger.tunnelWidth, remY + remYl, color.white);
        _subAlbits[Type.dig] = al_create_sub_bitmap(
            _mask, 0, remY, Digger.tunnelWidth, remY + remYl);

        void drawPixel(in int x, in int y, in Alcol col)
        {
            rf(x, y, x + 1, y + 1, col);
        }

        // basher and miner swings
        void drawSwing(in int startX, in int startY, in Type type)
        {
            foreach     (int y; 0 .. masks[type].solid.yl)
                foreach (int x; 0 .. masks[type].solid.xl)
                    if (masks[type].solid.get(x, y))
                        drawPixel(startX + x, startY + y, color.white);

            assert (_subAlbits[type] is null);
            _subAlbits[type] = al_create_sub_bitmap(_mask, startX, startY,
                               masks[type].solid.xl, masks[type].solid.yl);
            assert (_subAlbits[type] !is null);
        }
        drawSwing(bashX,              remY, Type.bashRight);
        drawSwing(bashX +     bashXl, remY, Type.bashLeft);
        drawSwing(bashX + 2 * bashXl, remY, Type.bashNoRelicsRight);
        drawSwing(bashX + 3 * bashXl, remY, Type.bashNoRelicsLeft);
        drawSwing(mineX,              remY, Type.mineRight);
        drawSwing(mineX + mineXl,     remY, Type.mineLeft);

        // imploder, exploder
        drawSwing(implodeX, ploY, Type.implode);
        drawSwing(explodeX, ploY, Type.explode);
    }

}
