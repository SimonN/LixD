module game.core.calc;

import std.algorithm; // all

import basics.user;
import game.core;
import game.gui.wduring;
import gui;
import hardware.keyboard;

package void
implGameCalc(Game game)
{
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

private bool
isFinished(const(Game) game)
{
    assert (game.cs);
    return game.cs.tribes.all!(a => ! a.stillPlaying)
        && game.cs.traps .all!(a => ! a.isEating(game.cs.update))
        && game.effect.nothingGoingOn;
}

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
