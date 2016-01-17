module game.physdraw;

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
import basics.nettypes;
import game.phymap;
import game.mask;
import game.terchang;
import graphic.color;
import graphic.torbit;
import graphic.gralib; // must be initialized first
import hardware.display; // displayStartupMessage
import hardware.tharsis;
import lix.enums;
import lix.skill.cuber; // Cuber.cubeSize
import lix.skill.digger; // diggerTunnelWidth

void initialize(Runmode mode) { PhysicsDrawer.initialize(mode); }
void deinitialize()           { PhysicsDrawer.deinitialize();   }



class PhysicsDrawer {

    this(Torbit land, Phymap lookup)
    {
        _land   = land;
        _phymap = lookup;
        assert (_phymap, "_land may be null, but not _phymap");
    }

    void
    add(in TerrainChange tc)
    {
        if (tc.isAddition) _addsForPhymap ~= tc;
        else               _delsForPhymap ~= tc;
    }

    // This should be called when loading a savestate, to throw away any
    // queued drawing changes to the land. The savestate comes with a fresh
    // copy of the land that must be registered here.
    void
    rebind(Torbit newLand, Phymap newPhymap)
    in {
        assert (_land,
            "You want to reset the draw-to-land queues, but you haven't "
            "registered a land to draw to during construction "
            "of PhysicsDrawer.");
        assert (newLand);
        assert (newPhymap);
        assert (_addsForPhymap == null);
        assert (_delsForPhymap == null);
    }
    body {
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
    // You should know what a lookup map is (class Phymap from game.phymap).
    // _land is the torus bitmap onto which we draw the terrain, but this
    // is never queried for physics -- that's what the lookup map is for.
    // in Update upd: Pass current update of the game to this.
    void
    applyChangesToLand(in Update upd)
    in {
        assert (_land);
        enum msg = "I don't believe you should draw to land when you still "
            "have changes to be drawn to the lookup map. You may want to call "
            "applyChangesToPhymap() more often.";
        assert (_delsForPhymap == null, msg);
        assert (_addsForPhymap == null, msg);
        enum msg2 = "applyChangesToLand() doesn't get called each update. "
            "But there should never be something in there that isn't to be "
            "processed during this call.";
        assert (_delsForLand == null || _delsForLand[$-1].update <= upd, msg2);
        assert (_addsForLand == null || _addsForLand[$-1].update <= upd, msg2);
    }
    out {
        assert (_delsForLand == null);
        assert (_addsForLand == null);
    }
    body {
        if (! anyChangesToLand)
            return;

        auto zone   = Zone(profiler, "applyChangesToLand >= 1");
        auto target = DrawingTarget(_land.albit);

        while (_delsForLand != null || _addsForLand != null) {
            // Do deletions for the first update, then additions for that,
            // then deletions for the next update, then additions, ...
            immutable Update earliestUpdate
                = _delsForLand != null && _addsForLand != null
                ? min(_delsForLand[0].update, _addsForLand[0].update)
                : _delsForLand != null
                ? _delsForLand[0].update : _addsForLand[0].update;

            deletionsToLandForUpdate(earliestUpdate);
            additionsToLandForUpdate(earliestUpdate);
        }
    }



// ############################################################################
// ############################################################################
// ############################################################################



private:

    static Albit _mask;

    // this enumap is used by the terrain removers, not by the styled adders
    static Enumap!(TerrainChange.Type, Albit) _subAlbits;

    Torbit _land;
    Phymap _phymap;

    TerrainChange[] _delsForPhymap;
    TerrainChange[] _addsForPhymap;

    FlaggedChange[] _delsForLand;
    FlaggedChange[] _addsForLand;

    enum buiY  = 0;
    enum cubeY = 2 * lix.enums.brickYl;
    enum remY  = cubeY + Cuber.cubeSize;
 	enum remYl = 32;
    enum ploY  = remY + remYl;
    enum ploYl = game.mask.masks[TerrainChange.Type.implode].solid.yl;

    enum bashX  = Digger.tunnelWidth + 1;
    enum bashXl = game.mask.masks[TerrainChange.Type.bashRight].solid.xl + 1;
    enum mineX  = bashX + 4 * bashXl; // 4 basher masks
    enum mineXl = game.mask.masks[TerrainChange.Type.mineRight].solid.xl + 1;

    enum implodeX = 0;
    enum explodeX = game.mask.masks[TerrainChange.Type.implode].solid.xl + 1;

    static struct FlaggedChange
    {
        TerrainChange terrainChange;
        alias terrainChange this;

        bool mustDrawPerPixel; // if there was land under a land addition,
                               // or steel amidst a land removal
    }

    static void
    deinitialize()
    {
        foreach (enumVal, ref Albit sub; _subAlbits)
            if (sub !is null) {
                al_destroy_bitmap(sub);
                sub = null;
            }
        if (_mask) {
            al_destroy_bitmap(_mask);
            _mask = null;
        }
    }

    mixin template AdditionsDefs() {
        immutable build = (tc.type == TerrainChange.Type.build);
        immutable platf = (tc.type == TerrainChange.Type.platform);
        immutable yl    = (build || platf) ? lix.enums.brickYl : tc.yl;
        immutable y     = build ? 0
                        : platf ? lix.enums.brickYl
                        :         cubeY + Cuber.cubeSize - yl;
        immutable xl    = build ? lix.enums.builderBrickXl
                        : platf ? lix.enums.platformerBrickXl
                        :         Cuber.cubeSize;
        immutable x     = xl * tc.style;
    }

    void assertCalledEachUpdate(TerrainChange[] arr)
    {
        // don't let data of different updates accumulate here
        foreach (const tc; arr)
            assert (tc.update == arr[0].update);
    }

    void assertChangesForLand(FlaggedChange[] arr, in Update upd)
    {
        // Functions calling assertChangesForLand need not be called on each
        // update, but only if the land must be drawn like it should appear
        // now. In noninteractive mode, this shouldn't be called at all.
        assert (_land);
        assert (_mask);
        assert (isSorted!"a.update < b.update"(arr));
        assert (arr == null || arr[0].update >= upd, format(
            "There are additions to the land that should be drawn in "
            "the earlier update %d. Right now we have update %d. "
            "If this happens after loading a savestate, "
            "make sure to empty all queued additions/deletions.",
            arr[0].update, upd));
        assert (al_get_target_bitmap() == _land.albit,
            "For performance, set the drawing target to _land "
            "outside of *ToLandForUpdate(). Slow performance is "
            "considered a logic bug!");
    }

    FlaggedChange[] splitOffFromArray(ref FlaggedChange[] arr, in Update upd)
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



    void
    deletionsToPhymap()
    in {
        assertCalledEachUpdate(_delsForPhymap);
    }
    out {
        assert (_delsForPhymap == null);
    }
    body {
        auto zone = Zone(profiler, format("PhysDraw del lookup %dx",
            _delsForPhymap.len));
        scope (exit)
            _delsForPhymap = null;

        foreach (const tc; _delsForPhymap) {
            assert (tc.isDeletion);
            auto zone2 = Zone(profiler, format("PhysDraw lookup %s",
                tc.type.to!string));

            int steelHit = 0;
            alias Type = TerrainChange.Type;

            if (tc.type == Type.dig) {
                assert (tc.yl > 0);
                steelHit += _phymap.rectSum!(Phymap.setAirCountSteel)
                    (tc.x, tc.y, Digger.tunnelWidth, tc.yl);
            }
            else
                steelHit += _phymap.setAirCountSteelEvenWhereMaskIgnores(
                            tc.x, tc.y, masks[tc.type]);
            if (_land)
                _delsForLand ~= FlaggedChange(tc, steelHit > 0);
        }
    }



    void
    deletionsToLandForUpdate(in Update upd)
    in {
        assertChangesForLand(_delsForLand, upd);
    }
    out {
        assert (_delsForLand == null
            ||  _delsForLand[0].update > upd);
    }
    body {
        auto processThese = splitOffFromArray(_delsForLand, upd);
        if (processThese == null)
            return;

        auto zone = Zone(profiler, format("PhysDraw del land %dx",
            processThese.len));

        // Terrain-removing masks are drawn with an opaque white pixel
        // (alpha = 1.0) where a deletion should occur on the land, and
        // transparent (alpha = 0.0) where no deletion should happen.
        // Therefore, choose a nonstandard blender that does:
        // target is opaque => deduct source alpha
        // target is transp => leave as-is, can't deduct any more alpha anyway
        with (Blender(
            ALLEGRO_BLEND_OPERATIONS.ALLEGRO_DEST_MINUS_SRC,
            ALLEGRO_BLEND_MODE.ALLEGRO_ONE, // subtract all of the source...
            ALLEGRO_BLEND_MODE.ALLEGRO_ONE) // ...from the target
        ) {
            foreach (const tc; processThese)
                deletionToLand(tc);
        }
    }

    void deletionToLand(in FlaggedChange tc)
    {
        assert (tc.isDeletion);
        auto zone2 = Zone(profiler, format("PhysDraw land %s",
            tc.type.to!string));
        Albit sprite;
        switch (tc.type) {
        case TerrainChange.Type.dig:
            // digging height is variable length
            assert (tc.yl > 0);
            sprite = al_create_sub_bitmap(_mask,
                0, remY, Digger.tunnelWidth, tc.yl);
            spriteToLandAccordingToFlag(tc, sprite);
            al_destroy_bitmap(sprite);
            break;
        default:
            sprite = _subAlbits[tc.type];
            spriteToLandAccordingToFlag(tc, sprite);
            break;
        }
    }

    void spriteToLandAccordingToFlag(in FlaggedChange tc, Albit sprite)
    {
        if (! tc.mustDrawPerPixel)
            _land.drawFrom(sprite, tc.x, tc.y);
        else {
            // magic!
        }
    }

// ############################################################################
// ############################################################################
// ############################################################################



    void
    additionsToPhymap()
    in {
        assertCalledEachUpdate(_addsForPhymap);
    }
    out {
        assert (_addsForPhymap == null);
    }
    body {
        foreach (const tc; _addsForPhymap) {
            auto zone = Zone(profiler, "PhysDraw lookupmap "
                                       ~ tc.type.to!string);
            mixin AdditionsDefs;
            assert (yl > 0, format("%s queued with yl <= 0; yl = %d",
                tc.type.to!string, yl));
            scope (success)
                _phymap.rect!(Phymap.setSolid)(tc.x, tc.y, xl, yl);

            if (_land) {
                // If land exists, remember the changes to be able to draw them
                // later. No land in noninteractive mode => needn't save this.
                auto fc = FlaggedChange(tc);
                fc.mustDrawPerPixel = _phymap.rectSum!(Phymap.getSolid)
                                        (tc.x, tc.y, xl, yl) != 0;
                _addsForLand ~= fc;
            }
        }
        _addsForPhymap = null;
    }



    void
    additionsToLandForUpdate(in Update upd)
    in {
        assertChangesForLand(_addsForLand, upd);
    }
    out {
        assert (_addsForLand == null
            ||  _addsForLand[0].update > upd);
    }
    body {
        auto processThese = splitOffFromArray(_addsForLand, upd);
        if (processThese == null)
            return;

        foreach (const tc; processThese) {
            mixin AdditionsDefs;
            Albit sprite = al_create_sub_bitmap(_mask, x, y, xl, yl);
            scope (exit)
                al_destroy_bitmap(sprite);
            _land.drawFrom(sprite, tc.x, tc.y);
            // DTODOVRAM: Do something about the bricks overwriting existing
            // terrain. I've tried it with blenders, I don't think I can
            // get something useful without changing the target bitmap,
            // which is too expensive. Look into shaders with Allegro 5.1.
            // Right now, I'm using Allegro 5.0.11.
        }
    }



// ############################################################################
// ############################################################################
// ############################################################################



    static void
    initialize(Runmode mode)
    {
        auto zoneInitialize = Zone(profiler, "physDraw initialize");

        assert (! _mask);
        assert (mode == Runmode.INTERACTIVE || mode == Runmode.VERIFY);
        if (mode == Runmode.VERIFY)
            return;

        alias Type = TerrainChange.Type;
        alias rf   = al_draw_filled_rectangle;

        // Otherwise, create the mask to blit nice sprites on the land
        displayStartupMessage("Creating physics mask...");

        assert (builderBrickXl >= platformerBrickXl);
        _mask = albitCreate(0x100, 0x80);
        assert (_mask, "couldn't create mask bitmap");

        auto drawingTarget = DrawingTarget(_mask);
        al_clear_to_color(color.transp);

        Albit recol = getInternal(basics.globals.fileImageStyleRecol).albit;
        assert (recol, "we lack the recoloring bitmap");
        immutable int recolXl = al_get_bitmap_width (recol);
        immutable int recolYl = al_get_bitmap_height(recol);
        assert (recolXl >= 3);

        auto lockRecol = LockReadOnly(recol);

        void drawBrick(in int x, in int y, in int xl,
            in AlCol light, in AlCol medium, in AlCol dark
        ) {
            alias yl = brickYl;
            rf(x,      y,      x+xl-1, y+1,  light);  // L L L L L M
            rf(x+1,    y+yl-1, x+xl,   y+yl, dark);   // M D D D D D
            rf(x,      y+yl-1, x+1,    y+yl, medium); // ^
            rf(x+xl-1, y,      x+xl,   y+1,  medium); //           ^
        }

        void drawCube(in int x, in int y,
            in AlCol light, in AlCol medium, in AlCol dark
        ) {
            alias l = Cuber.cubeSize;
            assert (l >= 10);
            rf(x, y, x+l, y+l, medium);

            void symmetrical(in int ax,  in int ay,
                             in int axl, in int ayl, in AlCol col)
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
        for (int i = 0; i < Style.max && i < recolYl + 1; ++i) {
            immutable int y = i + 1;
            drawBrick(i * builderBrickXl, 0, builderBrickXl,
                al_get_pixel(recol, recolXl - 3, y),
                al_get_pixel(recol, recolXl - 2, y),
                al_get_pixel(recol, recolXl - 1, y));
            drawBrick(i * platformerBrickXl, brickYl, platformerBrickXl,
                al_get_pixel(recol, recolXl - 3, y),
                al_get_pixel(recol, recolXl - 2, y),
                al_get_pixel(recol, recolXl - 1, y));
            drawCube(i * Cuber.cubeSize, cubeY,
                al_get_pixel(recol, recolXl - 3, y),
                al_get_pixel(recol, recolXl - 2, y),
                al_get_pixel(recol, recolXl - 1, y));
        }

        // digger swing
        rf(0, remY, Digger.tunnelWidth, remY + remYl, color.white);
        _subAlbits[TerrainChange.Type.dig] = al_create_sub_bitmap(
            _mask, 0, remY, Digger.tunnelWidth, remY + remYl);

        void drawPixel(in int x, in int y, in AlCol col)
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
