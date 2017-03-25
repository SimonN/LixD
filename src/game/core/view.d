module game.core.view;

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

bool showReplaySign(in View v) { return v.showTapeRecorderButtons; }
bool showTapeRecorderButtons(in View v)
{
    return v.canInterruptReplays || v == View.replayBattle;
}

bool continuePhysicsDuringModalWindow(in View v)
{
    return v == View.solveTogether || v == View.observeBattle
        || v == View.battle        || v == View.observeSolving;
}

unittest {
    assert (createView(3, null) != createView(1, null));
}
