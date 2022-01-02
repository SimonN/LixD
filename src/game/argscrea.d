module game.argscrea;

import optional;

import file.filename;
import file.replay;
import file.trophy;
import level.level;

/*
 * Args to create a local singleplayer game.
 * Networking games are created differently.
 */
struct ArgsToCreateGame {
    const(Level) level;
    Filename levelFilename;
    Optional!(immutable Replay) loadedReplay;

    TrophyKey trophyKey() const pure nothrow
    {
        return TrophyKey(
            levelFilename.fileNoExtNoPre,
            level.md.nameEnglish,
            level.author);
    }
}

