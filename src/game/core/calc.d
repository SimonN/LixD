module game.core.calc;

import std.algorithm; // all

import basics.user;
import basics.cmdargs;
import game.core;
import game.gui.wduring;
import gui;
import hardware.keyboard;

package void
implGameCalc(Game game)
{
    assert (game.runmode == Runmode.INTERACTIVE);
    if (game.modalWindow) {
        game.calcModalWindow;
    }
    else if (keyTapped(keyGameExit)) {
        game.createModalWindow;
    }
    else {
        game.calcPassive();
        game.calcActive();
        game.updatePhysicsAccordingToSpeedButtons();
        if (game.isFinished)
            game.createModalWindow;
    }
}

package Result
implEvaluateReplay(Game game) { with (game)
{
    assert (runmode == Runmode.VERIFY);
    assert (cs);
    assert (replay);
    bool isRunningForever()
    {
        // allow 5 minutes after the last replay data before cancelling
        return cs.update > replay.latestUpdate + 5 * (60 * 15);
    }
    while (! game.isFinished && ! isRunningForever)
        game.updateOnceNoninteractively;
    assert (tribeLocal);
    auto result = new Result();
    result.lixSaved = tribeLocal.lixSaved;
    result.skillsUsed = tribeLocal.skillsUsed;
    result.updatesUsed = tribeLocal.updatePreviousSave;
    return result;
}}

private bool
isFinished(const(Game) game) { with (game)
{
    assert (cs);
    if (runmode == Runmode.VERIFY)
        return cs.tribes.all!(a => ! a.stillPlaying);
    else
        return cs.tribes.all!(a => ! a.stillPlaying)
            && cs.traps .all!(a => ! a.isEating(cs.update))
            && effect.nothingGoingOn;
}}

private void
createModalWindow(Game game)
{
    game.modalWindow =
        // multiplayer && ! replaying ? : ? : ? :
        game.isFinished
        ? new WindowEndSingle(game.tribeLocal, game.replay, game.level)
        : new WindowDuringOffline(game.replay, game.level);
    addFocus(game.modalWindow);
}

private void
calcModalWindow(Game game) { with (game)
{
    void killWindow()
    {
        rmFocus(modalWindow);
        modalWindow = null;
        game.setLastUpdateToNow();
    }
    assert (modalWindow);
    if (modalWindow.resume) {
        killWindow();
    }
    else if (modalWindow.restart) {
        game.restartLevel();
        killWindow();
    }
    else if (modalWindow.exitGame) {
        _gotoMainMenu = true;
        killWindow();
    }
}}
