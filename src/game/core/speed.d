module game.core.speed;

import basics.alleg5;
import basics.nettypes; // Update
import game.core.game;
import game.core.active; // findAgainHighlitLixAfterUpdate
import game.gui.panel;
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

    // We don't set/unset pause based on the buttons here. This is done by
    // the panel itself, in Panel.calcSelf().
    if (   pan.speedBack.executeLeft
        || pan.speedBack.executeRight
    ) {
        with (LoadStateRAII(game))
            nurse.framestepBackBy(
                  pan.speedBack.executeLeft  ? 1
                : pan.speedBack.executeRight ? Game.updatesBackMany : 0);
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
        else
            with (LoadStateRAII(game))
                if (nurse.loadUserStateDoesItMismatch)
                    hardware.sound.playLoud(Sound.SCISSORS);
    }
    else if (pan.speedAhead.executeLeft) {
        upd();
    }
    else if (pan.speedAhead.executeRight) {
        upd(updatesAheadMany);
    }
    else if (pan.pause.on && ! pan.isMouseHere && mouseClickLeft) {
        // Clicking into the non-panel screen advances physics once.
        // This happens either because you've assigned something, or because
        // you have cancelled the replay.
        upd();
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
    with (LoadStateRAII(game))
        game.nurse.restartLevel();
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
