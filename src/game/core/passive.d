module game.core.passive;

/* This was gamepl_c.cpp in old Lix.
 * These calculations are performed even while a replay is running
 */

import basics.alleg5;
import game.core;
import hardware.keyboard;
import hardware.mousecur;

package void
calcPassive(Game game) { with (game)
{
    if (pan.zoom.execute)
        map.zoom = (map.zoom < 4) ? (map.zoom * 2) : 1;

    mouseCursor.xf = 0;
    mouseCursor.yf = 0;

    map.calcScrolling();
    if (map.scrollingNow)
        mouseCursor.xf = 3;
}}
// end with (game), end function calcPassive
