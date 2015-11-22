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

import std.conv;

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
        (tc.isAddition ? _additions : _deletions) ~= tc;
    }

    void
    processDeletions()
    {
        // DTODO: set blender to deleting blender
        foreach (const tc; _deletions) {
            assert (tc.isDeletion);
        }
        _deletions = null;
        // DTODO: set blender to normal blender by RAII
    }

    void
    processAdditions()
    in {
        if (_land)
            assert (_mask);
    }
    body {
        foreach (const tc; _additions) {
            Zone zone = Zone(profiler, "PhysDraw " ~ tc.type.to!string);

            immutable build = (tc.type == TerrainChange.Type.builderBrick);
            assert   (build || tc.type == TerrainChange.Type.platformerBrick);

            immutable yl = brickYl;
            immutable y  = build ? 0              : brickYl;
            immutable xl = build ? builderBrickXl : platformerBrickXl;
            immutable x  = xl * tc.style;

            with (Zone(profiler, "PhysDraw lookupmap " ~ tc.type.to!string))
                _lookup.addRectangle(tc.x, tc.y, xl, yl, Lookup.bitTerrain);

            if (_land) {
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
        _additions = null;
    }



private:

    static Albit _mask;

    Torbit _land;
    Lookup _lookup;

    TerrainChange[] _additions;
    TerrainChange[] _deletions;

    static void
    deinitialize()
    {
        if (_mask) {
            al_destroy_bitmap(_mask);
            _mask = null;
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
