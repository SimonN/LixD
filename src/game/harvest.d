module game.harvest;

/*
 * Harvest: A collection of results from an interactive Game.
 * When we return to a menu from the Game, the menu can then display
 * statistics based on these stats.
 */

import optional;

import basics.trophy;
import game.replay;
import level.level;

struct Harvest {
    const(Level) level;
    const(Replay) replay;
    const(Trophy) trophy; // of the local team, designed for singleplayer.

    // Harvest gets a Trophy even if Game forbids to save the Trophy.
    // Saving the trophy is forbidden when the level doesn't match what's
    // saved at the replay's pointed-to filename.
    // Game got told this bool, then Game tells us this bool:
    const bool maySaveTrophy;
}
