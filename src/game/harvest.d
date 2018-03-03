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
    Optional!Trophy trophy; // exists after a singleplayer game.

    // False if we started from a replay and never cancelled it. Game decides.
    bool autoReplayAllowed;

    // Still need something for multiplayer. Or have two Harvest structs?
}
