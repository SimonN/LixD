module game.core.passive;

/* Stuff that needs to be done each calc() of the game, but that is not
 * about assignments or nukes at all. Even cancelling the replay upon LMB
 * is not here, it's in calcActive.
 *
 * calcPassive (the stuff in here) runs before calcActive (new assignments)
 * and game.physseq (updating physics with replayed and new assignments).
 */

import optional;

import basics.alleg5;
import basics.globals;
import game.core.assignee;
import game.core.game;
import game.panel.tooltip;
import graphic.camera.mapncam;
import gui;
import hardware.keyboard;
import hardware.mousecur;
import hardware.sound;
import physics.lixxie.fields;

package void
calcPassive(
    Game game,
    in UnderCursor underCursor,
) { with (game)
{
    map.calcZoomAndScrolling();
    game.activateOrDeactivateTweaker(underCursor.best.empty
        ? no!Passport : some(underCursor.best.front.passport));

    mouseCursor.yf = underCursor.numLix >= 1;
    mouseCursor.xf
        = game.map.isHoldScrolling ? 3
        : forcingLeft ? 1
        : forcingRight ? 2 : mouseCursor.xf;

    if (map.suggestHoldScrollingTooltip)
        game._panelExplainer.suggestTooltip(Tooltip.ID.holdToScroll);

    if (pan.highlightGoalsExecute) {
        _altickHighlightGoalsUntil = timerTicks + ticksPerSecond * 3 / 2;
    }
}}

private:

void activateOrDeactivateTweaker(Game game, in Optional!Passport toHighlight)
{
    if (game.pan.tweakerIsOn) {
        game._tweaker.shown = true;
        game._tweaker.formatButtonsAccordingTo(
            game.nurse.constReplay.allPlies,
            game.nurse.now, toHighlight);
    }
    else if (game._tweaker.shown) {
        game._tweaker.shown = false;
        gui.requireCompleteRedraw();
    }
    game.map.choose(game._tweaker.shown ? MapAndCamera.CamSize.withTweaker
        : MapAndCamera.CamSize.fullWidth);
}
