module game.core.scrstart;

/* Determine the screen start position from the hatches.
 * In a multiplayer game, we use only the hatches of the local player here.
 */

import std.algorithm;
import std.range;
import std.conv;
import std.math;

import basics.help; // len
import game.core.game;
import graphic.gadget.hatch;

package:

void centerCameraOnHatchAverage(Game game)
{
    assert (game.map);
    with (game.map) {
        cameraX = torusAvg(xl, torusX, (a, b) => distanceX(a, b),
            game.ourHatches().map!(h => h.x +  h.tile.triggerX
                                            + (h.spawnFacingLeft ? -64 : 64)));
        cameraY = torusAvg(yl, torusY, (a, b) => distanceY(a, b),
            game.ourHatches().map!(h => h.y + h.tile.triggerY + 32));
    }
}

private:

const(Hatch)[] ourHatches(Game game) { with (game)
{
    assert (tribeLocal);
    auto st = nurse.stateOnlyPrivatelyForGame;
    assert (st.hatches.length > 0);
    assert (tribeLocal.hatchNextSpawn < st.hatches.length);
    const(Hatch)[] ret;
    for (int next = tribeLocal.hatchNextSpawn;
            next != tribeLocal.hatchNextSpawn || ret.length == 0;
            next  = (next + st.tribes.len) % st.hatches.len
    ) {
        ret ~= st.hatches[next];
    }
    return ret;
}}

int torusAvg(Range)(
    in int  screenLen,
    in bool torus,
    int delegate(int, int) dist,
    Range hatchPoints
) {
    immutable int len = hatchPoints.walkLength.to!int;
    immutable int avg = hatchPoints.sum / len;
    if (! torus)
        return avg;
    auto distToAllHatches(in int point)
    {
        return hatchPoints.map!(h => dist(point, h).abs).sum;
    }
    int closestPoint(in int a, in int b)
    {
        return distToAllHatches(a) <= distToAllHatches(b) ? a : b;
    }
    auto possiblePointsOnTorus = sequence!((unused, n) =>
        (avg + n.to!int * screenLen/len) % screenLen).takeExactly(len);
    static assert (is (typeof(possiblePointsOnTorus[0]) == int));
    return possiblePointsOnTorus.reduce!closestPoint;
}

unittest
{
    // On a non-torus map (2nd arg is false), return the unmodified average
    // of the range passed in the final argument.
    assert (torusAvg(10, false, (a, b) => b - a, [1, 2, 3, 4, 5, 6, 7]) == 4);
    // Need to write a unittest with nontrivial distance function from Map.
}
