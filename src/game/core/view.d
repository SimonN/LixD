module game.core.view;

/* The idea of View is to collect all possible behavioral differences of
 * the Game class in one place. Game behaves differently based on how many
 * players are there, whether we play, replay, or observe live, etc.
 */

import net.iclient;
import net.structs;

enum View {
    solveAlone, // one player solves/replays a puzzle
    solveTogether, // many players solve/replay via network a puzzle
    observeSolving, // observe via network other(s) solve/replay a puzzle

    battle, // many players compete against each other
    observeBattle, // observe via network others battling each other
    replayBattle, // one player watches the replay of a a multiplayer battle
}

View createView(in int numPlayers, in INetClient netClient) pure
{
    assert (numPlayers > 0);
    if (netClient) {
        return netClient.ourProfile.feeling == Profile.Feeling.observing
            ? View.observeBattle : View.battle;
    }
    else {
        return numPlayers == 1 ? View.solveAlone : View.replayBattle;
    }
}

bool canInterruptReplays(in View v)
{
    return v == View.solveAlone || v == View.solveTogether;
}

bool canAssignSkills(in View v)
{
    return v.canInterruptReplays || v == View.battle;
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

bool continuePhysicsDuringModalWindow(in View v)
{
    return v == View.solveTogether || v == View.observeBattle
        || v == View.battle        || v == View.observeSolving;
}

bool showModalWindowAfterGame(in View v)
{
    return v.canAssignSkills || v == View.replayBattle;
}

bool printResultToConsole(in View v)
{
    return v == View.battle || v == View.observeBattle
        || v == View.solveTogether;
}

unittest {
    assert (createView(3, null) != createView(1, null));
}
