module game.core.calc;

import std.algorithm; // all

import optional;

import file.option;
import basics.cmdargs;
import game.core.assignee;
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
    if (modalWindow) {
        game.calcModalWindow;
        game.noninputCalc();
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
        auto potAss = game.findAndDescribePotentialAssignee();
        game.calcPassive(potAss.oc.passport.toOptional);
        if (game.view.canAssignSkills) {
            game.calcNukeButton();
            game.calcClicksIntoMap(potAss);
        }
        game.dispatchTweaks(); // Not yet impl'ed: feed into net
        game.noninputCalc();
        game.considerToEndGame();
    }
}}

private:

void noninputCalc(Game game)
{
    if (game._netClient)
        game._netClient.calc();
    game.updatePhysicsAccordingToSpeedButtons();
}

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
    if (multiplayer || singleplayerHasWon) {
        return; // Singleplayer has not lost.
    }
    /*
     * We check the nuke button here in addition to checking it during
     * physics in game.core.active. In game.core.active, it generates
     * the nuke input for the replay, but we won't process any further
     * replay updates after all lixes have died. Thus, after all lixes
     * have died, quit the game now here without affecting physics.
     *
     * pan.nukeDoubleclicked does _not_ tell us if the single player has
     * nuked in the past (= if the nuke button is red). It tells us if
     * he's doubleclicking. singleplayerHasNuked tells us about the past.
     */
    if (pan.nukeDoubleclicked || ! view.canInterruptReplays) {
        /*
         * view.canInterruptReplays can only be false here while we don't
         * have proper multiplayer puzzle solving. Meanwhile, we're reusing
         * View.battle for that half-baked feature.
         */
        _gotoMainMenu = true;
    }
    else if (! singleplayerHasNuked) {
        _mapClickExplainer.suggestTooltip(Tooltip.ID.framestepOrQuit);
    }
}}

void calcEndOfPhysicsAndEndOfEffects(Game game) { with (game)
{
    if (multiplayer || singleplayerHasWon || singleplayerHasNuked)
        _gotoMainMenu = true;
    if (view.printResultToConsole)
        _chatArea.printScores(nurse.scores, nurse.constReplay, localStyle);
}}
