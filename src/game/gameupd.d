module game.gameupd;

/* Updating the game physics. This usually happens 15 times per second.
 * With fast forward, it's called more often; during pause, never.
 */

import game.game;
import game.state;
import graphic.gadget;

package void
impl_calc_update(Game game) { with (game)
{
    cs.foreach_gadget((Gadget g) {
        g.animate();
    });
}}
// end with (game), end calc_update()
