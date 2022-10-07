module game.core.calc;

import std.algorithm; // all

import file.option;
import basics.cmdargs;
import game.core.game;
import game.core.active;
import game.core.passive;
import game.core.speed;
import game.exitwin;
import game.panel.tooltip;
import gui;
import hardware.keyset;
import physics.score;

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
        game.dispatchTweaks(); // Not yet impl'ed: feed into net
        noninputCalc();
        game.considerToEndGame();
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

void considerToEndGame(Game game)
{
    if (game.nurse.doneAnimating()) {
        game.calcEndOfPhysicsWhileEffectsAreStillGoingOn();
        if (game._effect.nothingGoingOn) {
            game.calcEndOfPhysicsAndEndOfEffects();
        }
    }
}

void calcEndOfPhysicsWhileEffectsAreStillGoingOn(Game game) { with (game)
{
    immutable singleplayerHasLost = ! multiplayer && ! singleplayerHasWon;
    if (singleplayerHasLost) {
        // We check the nuke button here in addition to checking it during
        // physics in game.core.active. In game.core.active, it generates
        // the nuke input for the replay, but we won't process any further
        // replay updates after all lixes have died. Thus, after all lixes
        // have died, cancel the game immediately here without affecting
        // physics.
        if (pan.nukeDoubleclicked || ! view.canInterruptReplays) {
            /*
             * view.canInterruptReplays can only be false here while we don't
             * have proper multiplayer puzzle solving. Meanwhile, we're reusing
             * View.battle for that half-baked feature.
             */
            _gotoMainMenu = true;
        }
        else
            pan.suggestTooltip(Tooltip.ID.framestepOrQuit);
    }
}}

void calcEndOfPhysicsAndEndOfEffects(Game game) { with (game)
{
    if (multiplayer || singleplayerHasWon || singleplayerHasNuked)
        _gotoMainMenu = true;
    if (view.printResultToConsole)
        _chatArea.printScores(nurse.scores, nurse.constReplay, localStyle);
}}
