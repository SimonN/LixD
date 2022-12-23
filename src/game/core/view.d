module game.core.view;

/* The idea of View is to collect all possible behavioral differences of
 * the Game class in one place. Game behaves differently based on how many
 * players are there, whether we play, replay, or observe live, etc.
 */

import net.client.client;
import net.profile;

enum View {
    solveAlone, // one player solves/replays a puzzle
    solveTogether, // many players solve/replay via network a puzzle
    observeSolving, // observe via network other(s) solve/replay a puzzle

    battle, // many players compete against each other
    observeBattle, // observe via network others battling each other
    replayBattle, // one player watches the replay of a a multiplayer battle
}

// netClient may be null.
View createView(in int numPlayers, in INetClient netClient) pure
{
    if (netClient && netClient.connected) {
        return netClient.ourProfile.feeling == Profile.Feeling.observing
            ? View.observeBattle : View.battle;
    }
    else {
        return numPlayers >= 2 ? View.replayBattle : View.solveAlone;
    }
}

unittest {
    assert (createView(3, null) != createView(1, null));
}

pure nothrow @safe @nogc:

bool canInterruptReplays(in View v)
{
    return v == View.solveAlone || v == View.solveTogether;
}

bool canAssignSkills(in View v)
{
    return v.canInterruptReplays || v == View.battle;
}

bool startZoomedOutToSeeEntireMap(in View v)
{
    return v == View.observeBattle || v == View.observeSolving;
}

bool showReplaySign(in View v)
{
    return v.canInterruptReplays || v == View.replayBattle;
}

bool showScoreGraph(in View v)
{
    return v == View.battle || v == View.observeBattle
        || v == View.replayBattle;
}

bool showTapeRecorderButtons(in View v)
{
    return v == View.solveAlone || v == View.solveTogether
        || v == View.replayBattle;
}

bool printResultToConsole(in View v)
{
    return v == View.battle || v == View.observeBattle
        || v == View.solveTogether;
}
