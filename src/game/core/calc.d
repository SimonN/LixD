module game.core.calc;

import std.algorithm; // all

import basics.user;
import basics.cmdargs;
import game.core.game;
import game.window.base;
import game.core.active;
import game.core.passive;
import game.core.speed;
import game.panel.tooltip;
import game.score.score;
import gui;
import hardware.keyset;

package void
implGameCalc(Game game) { with (game)
{
    void noninputCalc()
    {
        if (_netClient)
            _netClient.calc();
        game.updatePhysicsAccordingToSpeedButtons();
    }
    if (modalWindow) {
        game.calcModalWindow;
        noninputCalc();
    }
    else if (keyGameExit.keyTapped) {
        if (multiplayer) {
            modalWindow = new ReallyExitWindow();
            addFocus(game.modalWindow);
        }
        else {
            _gotoMainMenu = true;
        }
    }
    else {
        game.calcPassive();
        game.calcActive();
        noninputCalc();
        game.atEndOfGame();
    }
}}

private:

void calcModalWindow(Game game) { with (game)
{
    assert (modalWindow);
    if (modalWindow.exitGame) {
        _gotoMainMenu = true;
    }
    if (modalWindow.exitGame || modalWindow.resume) {
        rmFocus(modalWindow);
        modalWindow = null;
        game.setLastPhyuToNow();
    }
}}

void atEndOfGame(Game game) { with (game)
{
    if (! nurse.doneAnimating())
        return;
    // Physics are finished
    if (! multiplayer && ! singleplayerHasWon)
        pan.suggestTooltip(Tooltip.ID.framestepOrQuit);

    if (! _effect.nothingGoingOn)
        return;
    // Physics and animations are finished, there is nothing else to see
    if (multiplayer || singleplayerHasWon || singleplayerHasNuked)
        _gotoMainMenu = true;
    if (view.printResultToConsole)
        _chatArea.printScores(nurse.scores, nurse.constReplay, localStyle);
}}
