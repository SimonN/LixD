module game.gameupd;

/* Updating the game physics. This usually happens 15 times per second.
 * With fast forward, it's called more often; during pause, never.
 */

import game.game;
import game.state;
import graphic.gadget;

package void
impl_calc_update(Game game)
{
    update_once(game);
}
// end calc_update()



// ############################################################################
// ############################################################################
// ############################################################################



private void update_once(Game game) { with (game.cs)
{
    ++update;

    // Animate after we had the traps eat lixes. Eating a lix sets a flag
    // in the trap to run through the animation, showing the first killing
    // frame after this next call to animate().
    foreach (hatch; hatches)
        hatch.animate(game.effect, update);

    foreach_gadget((Gadget g) {
        g.animate();
    });
}}
// end with (game.cs), end update_once()
