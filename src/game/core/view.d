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
    solotestBattle, // one player watches the replay of a a multiplayer battle
                    // or one player playtests all sides of a multiplayer map
}

// netClient may be null.
View createView(
    in int numPlayers,
    in INetClient netClient) pure nothrow @safe @nogc
{
    if (netClient && netClient.connected) {
        return netClient.ourProfile.feeling == Profile.Feeling.observing
            ? View.observeBattle : View.battle;
    }
    else {
        return numPlayers >= 2 ? View.solotestBattle : View.solveAlone;
    }
}

unittest {
    assert (createView(3, null) != createView(1, null));
}

pure nothrow @safe @nogc:

bool canInterruptReplays(in View v)
{
    return v == View.solveAlone || v == View.solveTogether
        || v == View.solotestBattle;
}

bool canAssignSkills(in View v)
{
    return v.canInterruptReplays || v == View.battle;
}

bool canSeeEverybodysSkillsets(in View v)
{
    return v == View.observeSolving
        || v == View.observeBattle
        || v == View.solotestBattle;
}

bool startZoomedOutToSeeEntireMap(in View v)
{
    return v == View.observeBattle || v == View.observeSolving;
}

bool showReplaySign(in View v)
{
    return v.canInterruptReplays;
}

bool showScoreGraph(in View v)
{
    return v == View.battle || v == View.observeBattle
        || v == View.solotestBattle;
}

bool showTapeRecorderButtons(in View v)
{
    return v == View.solveAlone || v == View.solveTogether
        || v == View.solotestBattle;
}

bool showSkillsInPanelAfterNuking(in View v)
{
    return v == View.solveAlone || v == View.solveTogether
        || v == View.observeSolving;
}

bool askBeforeExitingGame(in View v)
{
    return v == View.battle || v == View.observeBattle
        || v == View.observeSolving || v == View.solveTogether;
}

bool printResultToConsole(in View v)
{
    return v == View.battle || v == View.observeBattle
        || v == View.solveTogether;
}
