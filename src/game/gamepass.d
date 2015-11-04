module game.gamepass;

/* This was gamepl_c.cpp in old Lix.
 * These calculations are performed even while a replay is running
 */

import basics.alleg5;
import game;
import hardware.keyboard;
import hardware.mousecur;

package void
calcPassive(Game game) { with (game)
{
    if (keyTapped(ALLEGRO_KEY_ESCAPE))
        game._gotoMenu = true;

    mouseCursor.xf = 0;
    mouseCursor.yf = 0;

    map.calcScrolling();
    if (map.scrollingNow)
        mouseCursor.xf = 3;



    if (pan.restart.execute)
        game.loadStateManually(stateManager.zero);

}}
// end with (game), end function calcPassive
