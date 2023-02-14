module game.core.speed;

import core.time;
static import basics.globals;

import basics.alleg5;
import file.option; // replayAfterFrameBack
import game.core.game;
import game.nurse.cache : DuringTurbo;
import game.panel.base;
import hardware.mouse;
import hardware.sound;
import net.repdata;

package:

void dispatchTweaks(Game game)
{
    if (! game._tweaker.suggestsChange) {
        return;
    }
    /*
     * We pause here from Game code. Reason: _tweaker is not related to
     * pan. Comapre: We don't pause manually here e.g. when framestepping
     * because framestepping is triggered from pan itself, which pauses
     * (also responsibility of pan).
     */
    game.pan.pause(true);
    game.nurse.tweakReplayRecomputePhysics(game._tweaker.suggestedChange);
    game.setLastPhyuToNow(); // Updates skill numbers in panel.
}

void updatePhysicsAccordingToSpeedButtons(Game game) { with (game)
{
    if (pan.framestepBackOne) {
        with (LoadStateRAII(game))
            game.nurse.framestepBackBy(1);
    }
    else if (pan.framestepBackMany) {
        with (LoadStateRAII(game))
            game.nurse.framestepBackBy(Game.updatesBackMany);
    }
    else if (pan.restart) {
        game.restartLevel();
    }
    else if (pan.saveState) {
        nurse.saveUserState();
        _effect.quicksave();
        // Don't play Sound.DISKSAVE: The savestate isn't written to disk
        hardware.sound.playQuiet(Sound.CLOCK);
    }
    else if (pan.loadState) {
        if (nurse.userStateExists)
            with (LoadStateRAII(game)) {
                nurse.loadUserState();
                _effect.quickload();
            }
    }
    else if (pan.framestepAheadOne) {
        game.upd(1, DuringTurbo.no);
    }
    else if (pan.framestepAheadMany) {
        game.upd(updatesAheadMany, DuringTurbo.no);
    }
    else if (pan.paused && isMouseOnLand && mouseClickLeft) {
        // Clicking into the non-panel screen advances physics once.
        // This happens both when we unpause on assignment and when we
        // merely advance 1 frame, but keep the game paused, on assignment.
        // This happens either because you've assigned something, or because
        // you have cancelled the replay.
        game.upd(1, DuringTurbo.no);
    }
    else if (! pan.paused) {
        if (pan.speedIsNormal) {
            if (game.shallWeUpdateAtAdjustedNormalSpeed())
                game.upd(1, DuringTurbo.no);
        }
        else if (pan.speedIsTurbo)
            game.upd(9, DuringTurbo.yes);
        else {
            assert (pan.speedIsFast);
            game.upd(1, DuringTurbo.no);
        }
    }
}}
// end with (game), end function updatePhysicsAccordingToSpeedButtons

void restartLevel(Game game)
{
    game.pan.setSpeedNormal();
    with (LoadStateRAII(game))
        game.nurse.restartLevel();
}

// The server tells us the milliseconds since game start, and the net client
// has added our lag. We think in Phyus or Allegro ticks, not in millis,
// therefore convert millis to Phyus.
void recordServersWishSinceGameStart(
    Game game,
    in Duration sinceServerStartedGame
) {
    /*
     * How many alticks have elapsed on our side since game start?
     * This is the number of completed Phyus converted to ticks,
     * plus leftover ticks that didn't yet make a complete Phyu.
     */
    immutable long ourTicks
        = game.nurse.updatesSinceZero * game.ticksNormalSpeed
        + (timerTicks - game.altickLastPhyu);
    /*
     * How many ticks does the server wish to have elapsed on our side
     * since game start?
     */
    enum Duration durOneTick = 1.seconds / basics.globals.ticksPerSecond;
    immutable long suggTicks = sinceServerStartedGame / durOneTick;
    game._alticksToAdjust = suggTicks - ourTicks;
}

///////////////////////////////////////////////////////////////////////////////
private: //////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

struct LoadStateRAII
{
    private Game _game;
    this(Game g) { _game = g; }
    ~this() { _game.setLastPhyuToNow(); }
}

// Combat the network time-lag, affect _alticksToAdjust.
// _alticksToAdjust is < 0 if we have to slow down, > 0 if we have to speed up.
bool shallWeUpdateAtAdjustedNormalSpeed(Game game)
{
    immutable long updAgo = timerTicks - game.altickLastPhyu;
    immutable long adjust
        = game._alticksToAdjust < -20 ? 2
        : game._alticksToAdjust <   0 ? 1
        : game._alticksToAdjust >  20 ? -2
        : game._alticksToAdjust >   0 ? -1 : 0;
    if (updAgo < game.ticksNormalSpeed + adjust) {
        return false; // Caller shouldn't update physics yet.
    }
    game._alticksToAdjust += adjust;
    return true;
}

// Call upd() only during updatePhysicsAccordingToSpeedButtons()
// Dispatch new assignments, then move forward in the gametime
private void upd(Game game, in int howmany, in DuringTurbo duringTurbo)
{
    if (game.nurse.doneAnimating())
        return;
    immutable before = game.nurse.now;
    // Don't send undispatched via network, we did that earlier already.
    // Some from undispatchedAssignments have even come from the net.
    game.nurse.addPlyMaybeGoBack(game.undispatchedAssignments);
    game.undispatchedAssignments = null;
    game.nurse.updateTo(Phyu(before + howmany), duringTurbo);
    game.setLastPhyuToNow();
}
