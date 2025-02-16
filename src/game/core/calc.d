module game.core.calc;

import optional;

import file.option;
import game.core.assignee;
import game.core.game;
import game.core.active;
import game.core.passive;
import game.core.speed;
import game.exitwin;
import game.panel.tooltip;
import gui;

package void implGameCalc(Game game)
{
    void netSendReceive() {
        if (game._netClient) {
            game._netClient.calc();
        }
    }
    netSendReceive();
    game.implGameCalc2();
    netSendReceive();
}

private:

void implGameCalc2(Game game) { with (game)
{
    if (modalWindow) {
        game.calcModalWindow;
        game.maybeUpdatePhysics();
    }
    else if (keyGameExit.wasTapped) {
        if (game.view.askBeforeExitingGame) {
            modalWindow = new ReallyExitWindow();
            addFocus(game.modalWindow);
        }
        else {
            _gotoMainMenu = true;
        }
    }
    else {
        auto underCursor = game.findUnderCursor(game.pan.chosenSkill);
        game.calcPassive(underCursor);
        if (game.view.canAssignSkills) {
            game.calcNukeButton();
        }
        game.calcClicksIntoMap(underCursor);
        game.dispatchTweaks(); // Not yet impl'ed: feed into net
        game.maybeUpdatePhysics();
        game.considerToEndGame();
    }
}}

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
    if (! game.nurse.doneAnimating()) {
        return;
    }
    game.calcEndOfPhysicsWhileEffectsAreStillGoingOn();
    if (game._effect.nothingGoingOn) {
        if (game.cs.isBattle
            || game.cs.isSolvedPuzzle
            || game.singleplayerHasNuked
        ) {
            game._gotoMainMenu = true;
        }
        if (game.view.printResultToConsole) {
            game._chatArea.printScores(
                game.nurse.scores, game.nurse.constReplay, game.localStyle);
        }
    }
}

void calcEndOfPhysicsWhileEffectsAreStillGoingOn(Game game) { with (game)
{
    if (game.cs.isBattle || game.cs.isSolvedPuzzle) {
        return; // Singleplayer has not lost yet. Nothing to do here.
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
