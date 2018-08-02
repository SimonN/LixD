module game.core.speed;

static import basics.globals;

import basics.alleg5;
import net.repdata; // Phyu
import file.option; // replayAfterFrameBack
import game.core.game;
import game.core.active; // findAgainHighlitLixAfterPhyu
import game.model.cache : DuringTurbo;
import game.panel.base;
import hardware.mouse;
import hardware.sound;

package:

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
        game.upd();
    }
    else if (pan.framestepAheadMany) {
        game.upd(updatesAheadMany);
    }
    else if (pan.paused && ! pan.isMouseHere && mouseClickLeft) {
        // Clicking into the non-panel screen advances physics once.
        // This happens both when we unpause on assignment and when we
        // merely advance 1 frame, but keep the game paused, on assignment.
        // This happens either because you've assigned something, or because
        // you have cancelled the replay.
        game.upd();
    }
    else if (! pan.paused) {
        if (pan.speedIsNormal) {
            if (game.shallWeUpdateAtAdjustedNormalSpeed())
                game.upd();
        }
        else if (pan.speedIsTurbo)
            game.upd(updatesDuringTurbo, DuringTurbo.yes);
        else {
            assert (pan.speedIsFast);
            game.upd();
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
    this(Game g) { _game = g; }
    ~this()      { _game.setLastPhyuToNow();    }
}

// Combat the network time-lag, affect _alticksToAdjust.
// _alticksToAdjust is < 0 if we have to slow down, > 0 if we have to speed up.
private bool shallWeUpdateAtAdjustedNormalSpeed(Game game) { with (game)
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

// Call upd() only during updatePhysicsAccordingToSpeedButtons()
// Dispatch new assignments, then move forward in the gametime
void upd(Game game, in int howmany = 1,
    in DuringTurbo duringTurbo = DuringTurbo.no) { with (game)
{
    if (nurse.doneAnimating())
        return;
    immutable before = nurse.upd;
    // Don't send undispatched via network, we did that earlier already.
    // Some from undispatchedAssignments have even come from the net.
    nurse.addReplayDataMaybeGoBack(undispatchedAssignments);
    undispatchedAssignments = null;
    nurse.updateTo(Phyu(before + howmany), duringTurbo);
    game.findAgainHighlitLixAfterPhyu();
    game.setLastPhyuToNow();
}}
