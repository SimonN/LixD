module game.core.speed;

static import basics.globals;

import basics.alleg5;
import net.repdata; // Phyu
import basics.user; // pausedAssign
import game.core.game;
import game.core.active; // findAgainHighlitLixAfterPhyu
import game.panel.base;
import hardware.mouse;
import hardware.sound;

package:

void updatePhysicsAccordingToSpeedButtons(Game game) { with (game)
{
    import game.model.cache : DuringTurbo;
    void upd(in int howmany = 1, in DuringTurbo duringTurbo = DuringTurbo.no)
    {
        immutable before = nurse.upd;
        // Don't send undispatched via network, we did that earlier already.
        // Some from undispatchedAssignments have even come from the net.
        nurse.addReplayDataMaybeGoBack(undispatchedAssignments);
        undispatchedAssignments = null;
        nurse.updateTo(Phyu(before + howmany), duringTurbo);
        game.findAgainHighlitLixAfterPhyu();
        game.setLastPhyuToNow();
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
        if (pan.speedIsNormal) {
            if (game.shallWeUpdateAtAdjustedNormalSpeed())
                upd();
        }
        else if (pan.speedIsTurbo)
            upd(updatesDuringTurbo, DuringTurbo.yes);
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
    with (LoadStateRAII(game)) {
        game.nurse.framestepBackBy(by);
        if (! replayAfterFrameBack.value)
            game.cancelReplay();
    }
}

// The server tells us the milliseconds since game start, and the net client
// has added our lag. We think in Phyus or Allegro ticks, not in millis,
// therefore convert millis to Phyus.
void adjustToMatchMillisecondsSinceGameStart(Game game, in int suggMillis)
{ with (game) with (game.nurse)
{
    // How many ticks have elapsed since game start? This is the number of
    // completed Phyus converted to ticks, plus leftover ticks that didn't
    // yet make a complete Phyu.
    immutable ourTicks = updatesSinceZero * ticksNormalSpeed
                            + (timerTicks - altickLastPhyu);
    immutable suggTicks = suggMillis * basics.globals.ticksPerSecond / 1000;
    game._alticksToAdjust = suggTicks - ourTicks;
}}

private:

struct LoadStateRAII
{
    private Game _game;
    this(Game g) { _game = g; _game.saveResult(); }
    ~this()      { _game.setLastPhyuToNow();    }
}

// Combat the network time-lag, affect _alticksToAdjust.
// _alticksToAdjust is < 0 if we have to slow down, > 0 if we have to speed up.
bool shallWeUpdateAtAdjustedNormalSpeed(Game game) { with (game)
{
    immutable long updAgo = timerTicks - game.altickLastPhyu;
    immutable long adjust = _alticksToAdjust < -20 ? 2
                        :   _alticksToAdjust <   0 ? 1
                        :   _alticksToAdjust >  20 ? -2
                        :   _alticksToAdjust >   0 ? -1 : 0;
    if (updAgo >= ticksNormalSpeed + adjust) {
        _alticksToAdjust += adjust;
        return true;
    }
    return false;
}}
