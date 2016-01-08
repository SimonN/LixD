module game.core.speed;

import basics.alleg5;
import game.core;

package void
setLastUpdateToNow(Game game)
{
    game.altickLastUpdate = al_get_timer_count(basics.alleg5.timer);
}

package void
updatePhysicsAccordingToSpeedButtons(Game game) { with (game)
{
    void upd(int howmany = 1)
    {
        if (howmany-- > 0)
            game.syncNetworkThenUpdateOnce();
        while (howmany-- > 0)
            game.updateOnceWithoutSyncingNetwork();
        game.setLastUpdateToNow();
    }

    // We don't set/unset pause based on the buttons here. This is done by
    // the panel itself, in Panel.calcSelf().
    if (   pan.speedBack.executeLeft
        || pan.speedBack.executeRight
    ) {
        int whatUpdateToLoad
            = pan.speedBack.executeLeft  ? cs.update - 1
            : pan.speedBack.executeRight ? cs.update - Game.updatesBackMany
            : 0;
        auto state = (whatUpdateToLoad <= 0)
                   ? stateManager.zeroState
                   : stateManager.autoBeforeUpdate(whatUpdateToLoad + 1);
        assert (state, "we should get at laest some state here");
        assert (stateManager.zeroState, "zero state is bad");
        game.loadStateFramestepping(state, whatUpdateToLoad);
        upd(whatUpdateToLoad - cs.update);
    }
    else if (pan.restart.execute) {
        game.restartLevel();
    }
    else if (pan.speedAhead.executeLeft) {
        upd();
    }
    else if (pan.speedAhead.executeRight) {
        upd(updatesAheadMany);
    }
    else if (! pan.pause.on) {
        long updAgo = al_get_timer_count(timer) - game.altickLastUpdate;
        if (! pan.speedFast.on) {
            if (updAgo >= ticksNormalSpeed)
                upd();
        }
        else {
            upd(pan.speedFast.xf == Panel.frameTurbo
                ? updatesDuringTurbo : 1);
        }
    }

}}
// end with (game), end function updatePhysicsAccordingToSpeedButtons



private void
loadStateFramestepping(Game game, in GameState state, in int toUpdate)
{
    if (state) {
        game.cs = state.clone();
        game.physicsDrawer.rebind(game.cs.land, game.cs.lookup);
        game.effect.deleteAfter(toUpdate);
    }
}

package void
loadStateDuringPhysicsUpdate(Game game, in GameState state)
{
    if (state)
        loadStateFramestepping(game, state, state.update);
}

// package (instead of private), because this is not only called from state
// save/load buttons, but also from game.core.calc's modalWindow that requests
// restarting.
// DTODO: maybe use this even for the speed buttons for framestepping? Test!
package void
loadStateManually(Game game, in GameState state) { with (game)
{
    if (state) {
        game.loadStateDuringPhysicsUpdate(state);
        game.finalizeUpdateAnimateGadgets();
        game.setLastUpdateToNow();
    }
}}

package void
restartLevel(Game game) { with (game)
{
    assert (stateManager.zeroState, "want to load zero state, but cannot");
    game.loadStateManually(stateManager.zeroState);
    replay.eraseEarlySingleplayerNukes();
    pan.setSpeedToNormal();
}}
