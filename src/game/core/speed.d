module game.core.speed;

import basics.alleg5;
import net.repdata; // Update
import basics.user; // pausedAssign
import game.core.game;
import game.core.active; // findAgainHighlitLixAfterUpdate
import game.panel.base;
import hardware.mouse;
import hardware.sound;

package:

void updatePhysicsAccordingToSpeedButtons(Game game) { with (game)
{
    void upd(bool duringTurbo = false)(in int howmany = 1)
    {
        game.putUndispatchedAssignmentsIntoReplay();
        game.putNetworkDataIntoReplay();
        static if (duringTurbo)
            nurse.updateToDuringTurbo(Update(nurse.upd + howmany));
        else
            nurse.updateTo(Update(nurse.upd + howmany));
        game.findAgainHighlitLixAfterUpdate();
        game.setLastUpdateToNow();
    }

    if (pan.framestepBackOne) {
        game.framestepBackBy(1);
    }
    else if (pan.framestepBackMany) {
        game.framestepBackBy(Game.updatesBackMany);
    }
    else if (pan.restart) {
        game.restartLevel();
    }
    else if (pan.saveState) {
        nurse.saveUserState();
        hardware.sound.playLoud(Sound.DISKSAVE);
    }
    else if (pan.loadState) {
        if (! nurse.userStateExists)
            hardware.sound.playLoud(Sound.PANEL_EMPTY);
        else
            with (LoadStateRAII(game))
                if (nurse.loadUserStateDoesItMismatch)
                    hardware.sound.playLoud(Sound.SCISSORS);
    }
    else if (pan.framestepAheadOne) {
        upd();
    }
    else if (pan.framestepAheadMany) {
        upd(updatesAheadMany);
    }
    else if (pan.paused && ! pan.isMouseHere && mouseClickLeft
        && basics.user.pausedAssign.value > 0) {
        // Clicking into the non-panel screen advances physics once.
        // This happens either because you've assigned something, or because
        // you have cancelled the replay.
        upd();
    }
    else if (! pan.paused) {
        long updAgo = timerTicks - game.altickLastUpdate;
        if (pan.speedIsNormal) {
            if (updAgo >= ticksNormalSpeed)
                upd();
        }
        else if (pan.speedIsTurbo)
            upd!true(updatesDuringTurbo);
        else {
            assert (pan.speedIsFast);
            upd();
        }
    }
}}
// end with (game), end function updatePhysicsAccordingToSpeedButtons

void restartLevel(Game game)
{
    with (LoadStateRAII(game))
        game.nurse.restartLevel();
}

void framestepBackBy(Game game, in int by)
{
    game.pan.pause(true);
    with (LoadStateRAII(game))
        game.nurse.framestepBackBy(by);
}

private:

struct LoadStateRAII
{
    private Game _game;
    this(Game g) { _game = g; _game.saveResult(); }
    ~this()      { _game.setLastUpdateToNow();    }
}

void putUndispatchedAssignmentsIntoReplay(Game game) { with (game)
{
    foreach (data; undispatchedAssignments) {
        nurse.addReplayData(data);
        // DTODONETWORK
        // Network::send_replay_data(data);
        // or even better: network-send this data as soon as it is
        // generated in game.gameacti, not only when the update happens,
        // to combat lag wherever possible
    }
    undispatchedAssignments = null;
}}

void putNetworkDataIntoReplay(Game game) { }
