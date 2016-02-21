module game.core.speed;

import basics.alleg5;
import basics.nettypes; // Update
import game.core.game;
import game.gui.panel;
import hardware.sound;

/* For anything that can set back a state from singleplayer-has-won to
 * singleplayer hasn't yet won, e.g., lodaing an old state:
 *  1.  Begin by calling game.saveResult().
 *      --  This prevents lost progress. I don't save an autoreplay, because
 *      --  that would generate loads of clutter.
 *  2.  Do your action.
 *  3.  End by game.setLastUpdateToNow().
 * We could refactor this keep-in-mind-list into a RAII struct.
 */

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
        game.setLastUpdateToNow();
    }

    // We don't set/unset pause based on the buttons here. This is done by
    // the panel itself, in Panel.calcSelf().
    if (   pan.speedBack.executeLeft
        || pan.speedBack.executeRight
    ) {
        game.saveResult();
        nurse.framestepBackBy(
              pan.speedBack.executeLeft  ? 1
            : pan.speedBack.executeRight ? Game.updatesBackMany : 0);
        game.setLastUpdateToNow();
    }
    else if (pan.restart.execute) {
        game.restartLevel();
    }
    else if (pan.stateSave.execute) {
        nurse.saveUserState();
        hardware.sound.playLoud(Sound.DISKSAVE);
    }
    else if (pan.stateLoad.execute) {
        if (! nurse.userStateExists)
            hardware.sound.playLoud(Sound.PANEL_EMPTY);
        else {
            game.saveResult();
            if (nurse.loadUserStateDoesItMismatch)
                hardware.sound.playLoud(Sound.SCISSORS);
            game.setLastUpdateToNow();
        }
    }
    else if (pan.speedAhead.executeLeft) {
        upd();
    }
    else if (pan.speedAhead.executeRight) {
        upd(updatesAheadMany);
    }
    else if (! pan.pause.on) {
        long updAgo = timerTicks - game.altickLastUpdate;
        if (! pan.speedFast.on) {
            if (updAgo >= ticksNormalSpeed)
                upd();
        }
        else if (pan.speedFast.xf == Panel.frameTurbo)
            upd!true(updatesDuringTurbo);
        else
            upd();
    }
}}
// end with (game), end function updatePhysicsAccordingToSpeedButtons

void restartLevel(Game game)
{
    game.saveResult();
    game.nurse.restartLevel();
    game.setLastUpdateToNow();
}

private:

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
