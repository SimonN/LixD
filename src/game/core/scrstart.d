module game.core.scrstart;

/* Determine the screen start position from the hatches.
 * In a multiplayer game, we use only the hatches of the local player here.
 */

import std.algorithm;

import basics.help; // len
import game.core.game;
import tile.gadtile;
import tile.pos;

package:

void centerCameraOnHatchAverage(Game game)
{
    assert (game.map);
    game.map.centerOnAverage(game.ourHatches().map!(h => h.centerOnX),
                             game.ourHatches().map!(h => h.centerOnY));
}

private:

const(GadPos)[] ourHatches(const(Game) game) { with (game)
{
    assert (tribeLocal);
    auto st = nurse.stateOnlyPrivatelyForGame;
    assert (st.hatches.length > 0);
    assert (tribeLocal.hatchNextSpawn < st.hatches.length);
    const(GadPos)[] ret;
    for (int next = tribeLocal.hatchNextSpawn;
            next != tribeLocal.hatchNextSpawn || ret.length == 0;
            next  = (next + st.tribes.len) % st.hatches.len
    ) {
        ret ~= level.pos[GadType.HATCH][next];
    }
    return ret;
}}
