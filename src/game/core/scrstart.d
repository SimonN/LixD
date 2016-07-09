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
    float fillableScreenArea()      { return cameraXl * cameraYl; }
    float areaFilledByUnloopedMap() { return min(xl * zoom^^2, cameraXl)
                                           * min(yl * zoom^^2, cameraYl); }
    assert (fillableScreenArea > 0);
    while (areaFilledByUnloopedMap / fillableScreenArea < 0.7f && zoom < 8)
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
