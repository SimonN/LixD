module tile.draw;

/* This belonged to Level originally. But it's useful everywhere, so it is
 * a global function now. This centralizes knowledge about TerOcc and Torbit.
 * TerOcc doesn't need to know about Torbit.
 */

import basics.alleg5; // blender
import graphic.torbit;
import hardware.tharsis;
import tile.occur;
import tile.phymap;

void drawOccurrence(
    in TerOcc occ,
    Torbit ground,
    in Point offset = Point(0, 0)
) {
    immutable Point pt = occ.loc + offset;
    if (! occ.dark) {
        version (tharsisprofiling)
            auto zone = Zone(profiler, "Level.drawPos VRAM normal");
        assert (occ.tile.cb);
        assert (occ.tile.cb.xfs == 1 && occ.tile.cb.yfs == 1);
        // We subvert the Cutbit drawing function for speed.
        // Terrain is guaranteed to have only one frame anyway.
        ground.drawFrom(occ.tile.cb.albit, pt, occ.mirrY, occ.rotCw);
    }
    else {
        version (tharsisprofiling)
            auto zone = Zone(profiler, "Level.drawPos VRAM dark");
        assert (occ.tile);
        assert (occ.tile.dark);
        with (BlenderMinus)
            ground.drawFrom(occ.tile.dark.albit, pt, occ.mirrY, occ.rotCw);
    }
}

void drawOccurrence(in TerOcc occ, Phymap lookup)
in {
    assert (lookup);
    assert (! occ.noow, "replace noow with groups before drawing");
}
body {
    version (tharsisprofiling)
        auto zone = Zone(profiler, "Level.drawPos RAM ");
    // The lookup map could contain additional info about trigger areas,
    // but drawPosGadget doesn't draw those onto the lookup map.
    // That's done by the game class.
    immutable xl = (occ.rotCw & 1) ? occ.tile.cb.yl : occ.tile.cb.xl;
    immutable yl = (occ.rotCw & 1) ? occ.tile.cb.xl : occ.tile.cb.yl;
    foreach (int y; occ.loc.y .. (occ.loc.y + yl))
        foreach (int x; occ.loc.x .. (occ.loc.x + xl)) {
            immutable p = Point(x, y);
            immutable bits = occ.phybitsOnMap(p);
            if (! bits)
                continue;
            else if (occ.dark)
                lookup.rm(p, Phybit.terrain | Phybit.steel);
            else {
                lookup.add(p, bits);
                if (! (bits & Phybit.steel))
                    lookup.rm(p, Phybit.steel);
            }
        }
}
