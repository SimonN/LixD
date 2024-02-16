module game.core.speed;

import std.algorithm;
import core.time;

import basics.alleg5;
static import basics.globals;
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
    if (pan.rewindPrevPly) {
        game.nurse.framestepBackBy(game.numPhyusToBackstepToPrevPly);
        game.finishFramestepping(AndThen.pauseUnlessAtBeginning);
    }
    else if (pan.rewindOneSecond) {
        game.nurse.framestepBackBy(Game.updatesBackMany);
        game.finishFramestepping(AndThen.pause);
    }
    if (pan.rewindOneTick) {
        game.nurse.framestepBackBy(1);
        game.finishFramestepping(AndThen.pause);
    }
    else if (pan.restart) {
        game.nurse.restartLevel();
        game.finishFramestepping(AndThen.unpause);
    }
    else if (pan.saveState) {
        nurse.saveUserState();
        _effect.quicksave();
        // Don't play Sound.DISKSAVE: The savestate isn't written to disk
        hardware.sound.playQuiet(Sound.CLOCK);
    }
    else if (pan.loadState) {
        if (nurse.userStateExists) {
            nurse.loadUserState();
            _effect.quickload();
            game.finishFramestepping(AndThen.pause);
        }
    }
    else if (pan.skipOneTick) {
        game.upd(1, DuringTurbo.no);
        game.pan.pause = true;
    }
    else if (pan.skipTenSeconds) {
        game.upd(updatesAheadMany, DuringTurbo.no);
        // Don't pause. Don't unpause either. Keep pause as-is.
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

enum AndThen {
    pause,
    pauseUnlessAtBeginning,
    unpause
}

void finishFramestepping(Game game, in AndThen andThen)
{
    game.setLastPhyuToNow();
    final switch (andThen) {
        case AndThen.pause: game.pan.pause = true; return;
        case AndThen.unpause: game.pan.pause = false; return;
        case AndThen.pauseUnlessAtBeginning:
            game.pan.pause = (game.nurse.updatesSinceZero != 0);
            return;
    }
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

int numPhyusToBackstepToPrevPly(Game game)
{
    immutable Phyu now = game.nurse.now;
    immutable Phyu target = game.replay.allPlies
        .filter!(ply => ply.when <= now)
        .map!(ply => ply.when)
        .fold!max(Phyu(now - game.nurse.updatesSinceZero));
    return now - target + 1; // The +1 goes back to the phyu before that ply.
}
