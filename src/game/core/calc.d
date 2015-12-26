module game.core.calc;

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
    }
}

private void
createModalWindow(Game game)
{
    game.modalWindow =
        // multiplayer && ! replaying ? : ? : ? :
        new WindowDuringOffline();
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
        game.loadStateManually(stateManager.zeroState);
        killWindow();
    }
    else if (modalWindow.exitGame) {
        _gotoMenu = true;
        killWindow();
    }
}}
