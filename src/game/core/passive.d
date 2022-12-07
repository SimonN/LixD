module game.core.passive;

/* Stuff that needs to be done each calc() of the game, but that is not
 * about assignments or nukes at all. Even cancelling the replay upon LMB
 * is not here, it's in calcActive.
 *
 * calcPassive (the stuff in here) runs before calcActive (new assignments)
 * and game.physseq (updating physics with replayed and new assignments).
 */

import basics.alleg5;
import basics.globals;
import game.core.game;
import game.panel.tooltip;
import graphic.camera.mapncam;
import gui;
import hardware.keyboard;
import hardware.mousecur;
import hardware.sound;

package void
calcPassive(Game game) { with (game)
{
    if (pan.zoomIn)
        map.zoomIn();
    if (pan.zoomOut)
        map.zoomOut();
    map.calcScrolling();
    game.activateOrDeactivateTweaker();

    if (map.suggestHoldScrollingTooltip)
        game.pan.suggestTooltip(Tooltip.ID.holdToScroll);
    if (map.isHoldScrolling)
        mouseCursor.xf = 3;

    if (pan.highlightGoalsExecute) {
        _altickHighlightGoalsUntil = timerTicks + ticksPerSecond * 3 / 2;
    }
}}

private:

void activateOrDeactivateTweaker(Game game) { with (game)
{
    if (pan.tweakerIsOn) {
        _tweaker.shown = true;
        _tweaker.formatButtonsAccordingTo(
            nurse.constReplay.allPlies, nurse.upd);
    }
    else if (_tweaker.shown) {
        _tweaker.shown = false;
        gui.requireCompleteRedraw();
    }
    map.choose(_tweaker.shown ? MapAndCamera.CamSize.withTweaker
        : MapAndCamera.CamSize.fullWidth);
}}
