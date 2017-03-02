module game.core.passive;

/* Stuff that needs to be done each calc() of the game, but that is not
 * about assignments or nukes at all. Even cancelling the replay upon LMB
 * is not here, it's in calcActive.
 *
 * calcPassive (the stuff in here) runs before calcActive (new assignments)
 * and game.physseq (updating physics with replayed and new assignments).
 */

import basics.alleg5;
import game.core.game;
import hardware.keyboard;
import hardware.mousecur;

package void
calcPassive(Game game) { with (game)
{
    if (pan.zoomIn)
        map.zoomIn();
    if (pan.zoomOut)
        map.zoomOut();

    mouseCursor.xf = 0;
    mouseCursor.yf = 0;

    map.calcScrolling();
    if (map.scrollingNow)
        mouseCursor.xf = 3;
}}
