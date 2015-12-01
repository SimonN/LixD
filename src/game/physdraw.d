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
 */

import std.array;
import std.algorithm;
import std.conv;
import std.functional;
import std.range;
import std.string;

static import game.mask;

import basics.alleg5;
import basics.cmdargs;
import game.lookup;
import graphic.color;
import graphic.torbit;
import graphic.gralib; // must be initialized first
import hardware.display; // displayStartupMessage
import hardware.tharsis;
import lix.enums;
import lix.digger; // diggerTunnelWidth

void initialize(Runmode mode) { PhysicsDrawer.initialize(mode); }
void deinitialize()           { PhysicsDrawer.deinitialize();   }

struct TerrainChange {

    enum Type {
        build,
        platform,
        cubeSlice0,
        cubeSlice1,
        cubeSlice2,
        cubeTopHalf,

        implode,
        explode,
        bashLeft,
        bashRight,
        mineLeft,
        mineRight,
        dig
    }

    int   update;
    Type  type;
    Style style; // for additions
    int x;
    int y;
    int yl; // for digger swing

    @property bool isAddition() const { return type < Type.implode; }
    @property bool isDeletion() const { return ! isAddition; }
}

private struct FlaggedChange
{
    TerrainChange terrainChange;
    alias terrainChange this;

    bool needsRedraw; // if there was land under a land addition,
                      // or steel amidst a land removal
}





class PhysicsDrawer {

    this(Torbit land, Lookup lookup)
    {
        _land   = land;
        _lookup = lookup;
        assert (_lookup, "_land may be null, but not _lookup");
    }

    void
    add(in TerrainChange tc)
    {
        if (tc.isAddition) _addsForLookup ~= tc;
        else               _delsForLookup ~= tc;
    }

    // This should be called when loading a savestate, to throw away any
    // queued drawing changes to the land. The savestate comes with a fresh
    // copy of the land that must be registered here.
    void
    rebind(Torbit newLand, Lookup newLookup)
    in {
        assert (_land,
            "You want to reset the draw-to-land queues, but you haven't "
            "registered a land to draw to during construction "
            "of PhysicsDrawer.");
        assert (newLand);
        assert (newLookup);
        assert (_addsForLookup == null);
        assert (_delsForLookup == null);
    }
    body {
        _land        = newLand;
        _lookup      = newLookup;
        _addsForLand = null;
        _delsForLand = null;
    }

    void
    applyChangesToLookup()
    {
        deletionsToLookup();
        additionsToLookup();
    }

    @property bool
    anyChangesToLand()
    {
        return _delsForLand != null || _addsForLand != null;
    }

    // The single public function for any drawing to the land.
    // Should be understandable from the many asserts, otherwise ask me.
    // You should know what a lookup map is (class Lookup from game.lookup).
    // _land is the torus bitmap onto which we draw the terrain, but this
    // is never queried for physics -- that's what the lookup map is for.
    // int upd: Pass current update of the game to this.
    void
    applyChangesToLand(in int upd)
    in {
        assert (_land);
        enum msg = "I don't believe you should draw to land when you still "
            "have changes to be drawn to the lookup map. You may want to call "
            "applyChangesToLookup() more often.";
        assert (_delsForLookup == null, msg);
        assert (_addsForLookup == null, msg);
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
            immutable int earliestUpdate
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

    Torbit _land;
    Lookup _lookup;

    TerrainChange[] _delsForLookup;
    TerrainChange[] _addsForLookup;

    FlaggedChange[] _delsForLand;
    FlaggedChange[] _addsForLand;

    enum buiY  = 0;
    enum buiYl = 4;
 	enum remY  = buiY + buiYl;
 	enum remYl = 32;

    enum bashX  = 20;
    enum bashXl = game.mask.bashRight.xl;

    static void
    deinitialize()
    {
        if (_mask) {
            al_destroy_bitmap(_mask);
            _mask = null;
        }
    }

    mixin template AdditionsDefs() {
        immutable build = (tc.type == TerrainChange.Type.build);
        immutable yl    = lix.enums.brickYl;
        immutable y     = build ? 0              : brickYl;
        immutable xl    = build ? builderBrickXl : platformerBrickXl;
        immutable x     = xl * tc.style;
    }

    void assertCalledEachUpdate(TerrainChange[] arr)
    {
        // don't let data of different updates accumulate here
        foreach (const tc; arr)
            assert (tc.update == arr[0].update);
    }

    void assertChangesForLand(FlaggedChange[] arr, in int upd)
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

    FlaggedChange[] splitOffFromArray(ref FlaggedChange[] arr, in int upd)
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
    deletionsToLookup()
    in {
        assertCalledEachUpdate(_delsForLookup);
    }
    out {
        assert (_delsForLookup == null);
    }
    body {
        scope (exit)
            _delsForLookup = null;

        foreach (const tc; _delsForLookup) {
            assert (tc.isDeletion);
            int steelHit = 0;

            switch (tc.type) {
            case TerrainChange.Type.dig:
                assert (tc.yl > 0);
                steelHit += _lookup.rectSum!(Lookup.setAirCountSteel)
                    (tc.x, tc.y, Digger.tunnelWidth, tc.yl);
                break;
            default:
                assert (false, "skill not yet implemented");
            }

            if (_land)
                _delsForLand ~= FlaggedChange(tc, steelHit > 0);
        }
    }



    void
    deletionsToLandForUpdate(in int upd)
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
            foreach (const tc; processThese) {
                assert (tc.isDeletion);
                auto zone = Zone(profiler, "PhysDraw delete 1");

                Albit sprite = null;
                scope (exit) {
                    assert (sprite !is null);
                    al_destroy_bitmap(sprite);
                }

                switch (tc.type) {
                case TerrainChange.Type.dig:
                    assert (tc.yl > 0);
                    sprite = al_create_sub_bitmap(_mask,
                        0, remY, Digger.tunnelWidth, tc.yl);
                    break;
                default:
                    assert (false, "skill isn't implemented yet");
                }
                _land.drawFrom(sprite, tc.x, tc.y);
            }
        }
        if (processThese.any!(tc => tc.needsRedraw)) {
            // DTODOVRAM: draw the steel on top of _land?
        }
    }



// ############################################################################
// ############################################################################
// ############################################################################



    void
    additionsToLookup()
    in {
        assertCalledEachUpdate(_addsForLookup);
    }
    out {
        assert (_addsForLookup == null);
    }
    body {
        foreach (const tc; _addsForLookup) {
            auto zone = Zone(profiler, "PhysDraw lookupmap "
                                       ~ tc.type.to!string);
            mixin AdditionsDefs;
            assert (build || tc.type == TerrainChange.Type.platform,
                "cuber isn't implemented yet");
            scope (success)
                _lookup.rect!(Lookup.setSolid)(tc.x, tc.y, xl, yl);

            if (_land) {
                // If land exists, remember the changes to be able to draw them
                // later. No land in noninteractive mode => needn't save this.
                auto fc = FlaggedChange(tc);
                fc.needsRedraw = _lookup.rectSum!(Lookup.getSolid)
                                 (tc.x, tc.y, xl, yl) != 0;
                _addsForLand ~= fc;
            }
        }
        _addsForLookup = null;
    }



    void
    additionsToLandForUpdate(in int upd)
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
        assert (! _mask);
        assert (mode == Runmode.INTERACTIVE || mode == Runmode.VERIFY);
        if (mode == Runmode.VERIFY)
            return;

        alias rf = al_draw_filled_rectangle;

        // Otherwise, create the mask to blit nice sprites on the land
        displayStartupMessage("Creating physics mask...");

        assert (builderBrickXl >= platformerBrickXl);
        _mask = albitCreate(Style.MAX * lix.enums.builderBrickXl, 0x80);
        assert (_mask, "couldn't create mask bitmap");

        auto drawingTarget = DrawingTarget(_mask);

        void drawBrick(in int x, in int y, in int xl,
            in AlCol light, in AlCol medium, in AlCol dark
        ) {
            alias yl = brickYl;
            rf(x,      y,      x+xl-1, y+1,  light);  // L L L L L M
            rf(x+1,    y+yl-1, x+xl,   y+yl, dark);   // M D D D D D
            rf(x,      y+yl-1, x+1,    y+yl, medium); // ^
            rf(x+xl-1, y,      x+xl,   y+1,  medium); //           ^
        }

        Albit recol = getInternal(basics.globals.fileImageStyleRecol).albit;
        assert (recol, "we lack the recoloring bitmap");
        immutable int recolXl = al_get_bitmap_width (recol);
        immutable int recolYl = al_get_bitmap_height(recol);
        assert (recolXl >= 3);

        auto lockRecol = LockReadOnly(recol);

        // the first row of recol contains the file colors, then come several
        // rows, one per style < MAX.
        for (int i = 0; i < Style.MAX && i < recolYl + 1; ++i) {
            immutable int y = i + 1;
            drawBrick(i * builderBrickXl, 0, builderBrickXl,
                al_get_pixel(recol, recolXl - 3, y),
                al_get_pixel(recol, recolXl - 2, y),
                al_get_pixel(recol, recolXl - 1, y));
            drawBrick(i * platformerBrickXl, brickYl, platformerBrickXl,
                al_get_pixel(recol, recolXl - 3, y),
                al_get_pixel(recol, recolXl - 2, y),
                al_get_pixel(recol, recolXl - 1, y));
        }

        // digger swing
        rf(0, remY, Digger.tunnelWidth, remY + remYl, color.white);

        static if (true) {
            import std.string;
            al_save_bitmap("./physicsmask.png".toStringz, _mask);
        }
    }

}
