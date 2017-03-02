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
        immutable before = nurse.upd;
        // Don't send undispatched via network, we did that earlier already.
        // Some from undispatchedAssignments have even come from the net.
        nurse.addReplayDataMaybeGoBack(undispatchedAssignments);
        undispatchedAssignments = null;

        static if (duringTurbo)
            nurse.updateToDuringTurbo(Update(before + howmany));
        else
            nurse.updateTo(Update(before + howmany));
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
