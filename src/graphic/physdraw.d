module graphic.physdraw;

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

import std.algorithm;
import std.conv;
import std.string;

import basics.alleg5;
import basics.cmdargs;
import game.lookup;
import graphic.color;
import graphic.torbit;
import graphic.gralib; // must be initialized first
import hardware.display; // displayStartupMessage
import hardware.tharsis;
import lix.enums;

void initialize(Runmode mode) { PhysicsDrawer.initialize(mode); }
void deinitialize()           { PhysicsDrawer.deinitialize();   }

struct TerrainChange {

    enum Type {
        builderBrick,
        platformerBrick,

        imploderCrater,
        exploderCrater,
        basherSwing,
        minerSwing,
        diggerSwing
    }

    int   update;
    Type  type;
    Style style;
    int x;
    int y;

    @property bool isAddition() const { return type <= Type.platformerBrick; }
    @property bool isDeletion() const { return ! isAddition; }

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

    // pass current update of the game to this
    void
    applyChangesToLand(in int upd)
    in {
        // This doesn't get called each update. But there should never be
        // something in there that isn't to be processed during this call.
        assert (_delsForLand == null || _delsForLand[$-1].update <= upd);
        assert (_addsForLand == null || _addsForLand[$-1].update <= upd);
    }
    out {
        assert (_delsForLand == null);
        assert (_addsForLand == null);
    }
    body {
        while (_delsForLand != null || _addsForLand != null) {
            // Do deletions for the first update, then additions for that,
            // then deletions for the next update, then additions, ...
            int earliestUpdate
                = _delsForLand != null && _addsForLand != null
                ? min(_delsForLand[0].update, _addsForLand[0].update)
                : _delsForLand != null
                ? _delsForLand[0].update : _addsForLand[0].update;
            deletionsToLandForUpdate(earliestUpdate);
            additionsToLandForUpdate(earliestUpdate);
        }
    }



private:

    static Albit _mask;

    Torbit _land;
    Lookup _lookup;

    TerrainChange[] _addsForLookup;
    TerrainChange[] _delsForLookup;

    TerrainChange[] _addsForLand;
    TerrainChange[] _delsForLand;

    static void
    deinitialize()
    {
        if (_mask) {
            al_destroy_bitmap(_mask);
            _mask = null;
        }
    }

    mixin template AdditionsDefs() {
        immutable build = (tc.type == TerrainChange.Type.builderBrick);
        immutable yl    = brickYl;
        immutable y     = build ? 0              : brickYl;
        immutable xl    = build ? builderBrickXl : platformerBrickXl;
        immutable x     = xl * tc.style;
    }

    void
    deletionsToLookup()
    {
        _delsForLand ~= _delsForLookup;
        _delsForLookup = null;
    }



    void
    deletionsToLandForUpdate(in int upd)
    {
        _delsForLand = null;
    }



    void
    additionsToLookup()
    in {
        // This should be called on each update. Don't let data of different
        // updates accumulate here.
        foreach (const tc; _addsForLookup)
            assert (tc.update == _addsForLookup[0].update);
    }
    out {
        assert (_addsForLookup == null);
    }
    body {
        foreach (const tc; _addsForLookup) {
            auto zone = Zone(profiler, "PhysDraw lookupmap "
                                       ~ tc.type.to!string);
            mixin AdditionsDefs;
            assert (build || tc.type == TerrainChange.Type.platformerBrick);
            _lookup.addRectangle(tc.x, tc.y, xl, yl, Lookup.bitTerrain);
        }
        if (_land)
            // If land exists, remember the changes to be able to draw them
            // later. If there is no land in noninteractive mode, throw away.
            _addsForLand ~= _addsForLookup;
        _addsForLookup = null;
    }



    void
    additionsToLandForUpdate(in int upd)
    in {
        // This neend not be called on each update, but only if the land
        // must be drawn like it should appear now. In noninteractive mode,
        // this shouldn't be called at all.
        assert (_land);
        assert (_mask);
        assert (isSorted!"a.update < b.update"(_addsForLand));
        assert (_addsForLand == null || _addsForLand[0].update >= upd, format(
            "There are additions to the land that should be drawn in "
            "the earlier update %d. Right now we have update %d. "
            "If this happens after loading a savestate, "
            "make sure to empty all queued additions/deletions.",
            _addsForLand[0].update, upd));
        assert (al_get_target_bitmap() == _land.albit,
            "For performance, set the drawing target to _land "
            "outside of additionsToLandForUpdate(). Slow performance is "
            "considered a logic bug!");
    }
    out {
        assert (_addsForLand == null
            ||  _addsForLand[0].update > upd);
    }
    body {
        while (_addsForLand != null && _addsForLand[0].update == upd) {
            scope (exit)
                _addsForLand = _addsForLand[1 .. $];
            auto tc = _addsForLand[0];

            mixin AdditionsDefs;

            Albit sprite;
            with (Zone(profiler, "PhysDraw subbitmap create "
                                 ~ tc.type.to!string))
                sprite = al_create_sub_bitmap(_mask, x, y, xl, yl);
            scope (exit)
                with (Zone(profiler, "PhysDraw subbitmap destroy "
                                     ~ tc.type.to!string))
                    al_destroy_bitmap(sprite);
            with (Zone(profiler, "PhysDraw subbitmap draw "
                                 ~ tc.type.to!string))
                _land.drawFrom(sprite, tc.x, tc.y);
        }
    }



    static void
    initialize(Runmode mode)
    {
        assert (! _mask);
        assert (mode == Runmode.INTERACTIVE || mode == Runmode.VERIFY);
        if (mode == Runmode.VERIFY)
            return;

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
            alias rf = al_draw_filled_rectangle;
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

        static if (false) {
            import std.string;
            al_save_bitmap("./physicsmask.png".toStringz, _mask);
        }
    }

}
