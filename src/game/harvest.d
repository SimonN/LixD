module game.harvest;

/*
 * Harvest: A collection of results from an interactive Game.
 * When we return to a menu from the Game, the menu can then display
 * statistics based on these stats.
 */

import file.trophy;
import game.replay;
import level.level;

struct Harvest {
    const(Level) level;
    const(Replay) replay;

    // Specify an empty trophyKey.fileNoExt if the level doesn't exist
    // anywhere in the file tree. Always specify the loaded level's key.
    // When a replay is played against an arbitrarily chosen level, specify
    // still specify the loaded level's key, not the pointed-to level's key.
    const(TrophyKey) trophyKey;
    const(Trophy) trophy; // of the local team, designed for singleplayer.
}
