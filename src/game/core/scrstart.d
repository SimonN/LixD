module game.core.scrstart;

/* Determine the screen start position from the hatches.
 * In a multiplayer game, we use only the hatches of the local player here.
 */

import std.algorithm;

import basics.help; // len
import game.core.game;
import tile.gadtile;
import tile.occur;

package:

void centerCameraOnHatchAverage(Game game)
{
    assert (game.map);
    game.chooseGoodZoom();
    game.map.centerOnAverage(game.ourHatches().map!(h => h.screenCenter.x),
                             game.ourHatches().map!(h => h.screenCenter.y));
    game.map.snapToBoundary();
}

void chooseGoodZoom(Game game) {
    with (game.map)
{
    assert (game.map);
    assert (zoom == 1);
    // When exactly one of the two directions is torus, then we consider
    // only the non-torus direction for the zoom.
    float fillableScreenArea() {
        if (torusX != torusY)
            return torusX ? cameraYl : cameraXl;
        else
            return cameraXl * cameraYl;
    }
    float areaFilledByUnloopedMap()
    {
        if (torusX != torusY)
            return torusX ? min(yl * zoom, cameraYl)
                          : min(xl * zoom, cameraXl);
        else
            return min(xl * zoom, cameraXl) * min(yl * zoom, cameraYl);
    }
    float areaRatioThreshold()
    {
        return (torusX != torusY) ? 0.6f : 0.4f;
    }
    assert (fillableScreenArea > 0);
    while (areaFilledByUnloopedMap / fillableScreenArea < areaRatioThreshold)
        zoom = zoom * 2;
}}

private:

const(GadOcc)[] ourHatches(const(Game) game) { with (game)
{
    assert (tribeLocal);
    auto st = nurse.stateOnlyPrivatelyForGame;
    assert (st.hatches.length > 0);
    assert (tribeLocal.hatchNextSpawn < st.hatches.length);
    const(GadOcc)[] ret;
    for (int next = tribeLocal.hatchNextSpawn;
            next != tribeLocal.hatchNextSpawn || ret.length == 0;
            next  = (next + st.tribes.len) % st.hatches.len
    ) {
        ret ~= level.gadgets[GadType.HATCH][next];
    }
    return ret;
}}
