module game.core.scrstart;

/* Determine the screen start position from the hatches.
 * In a multiplayer game, we use only the hatches of the local player here.
 */

import std.algorithm;
import std.conv;

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
    if (cameraXl * cameraYl > 640 * 300 * 3)
        zoom = 2;
    else
        zoom = 1;
}}

private:

const(GadOcc)[] ourHatches(const(Game) game) { with (game)
{
    assert (localTribe);
    auto st = nurse.stateOnlyPrivatelyForGame;
    assert (st.hatches.len > 0);
    assert (localTribe.nextHatch < st.hatches.len);
    const(GadOcc)[] ret;
    for (int next = localTribe.nextHatch;
            next != localTribe.nextHatch || ret.len == 0;
            next  = (next + st.numTribes) % st.hatches.len
    ) {
        ret ~= level.gadgets[GadType.HATCH][next];
    }
    return ret;
}}
