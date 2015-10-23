module game.gameupd;

/* Updating the game physics. This usually happens 15 times per second.
 * With fast forward, it's called more often; during pause, never.
 */

import game;
import graphic.gadget;

package void
updateOnce(Game game)
{
    game.finalizeInputBeforeUpdate();
    ++game.cs.update;
    game.updateOnceGadgets();
}
// end calc_update()



private void
finalizeInputBeforeUpdate(Game game)
{
    // put spawn interval into replay
    // get network data and put it into replay vector
}




// ############################################################################
// ############################################################################
// ############################################################################



private void
updateOnceGadgets(Game game) {
    with (game)
    with (game.cs)
{
    // Animate after we had the traps eat lixes. Eating a lix sets a flag
    // in the trap to run through the animation, showing the first killing
    // frame after this next call to animate().
    foreach (hatch; hatches)
        hatch.animate(effect, update);

    foreachGadget((Gadget g) {
        g.animate();
    });
}}
// end with (game.cs), end update_once()
