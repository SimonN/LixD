module game.gamecalc;

import basics.alleg5;
import game;

package void
implGameCalc(Game game)
{
    // As always, get user input that affect physics first, then process it,
    // then update physics based on that
    game.calcPassive();
    game.calcActive();
    game.updatePhysicsAccordingToSpeedButtons();
}



private void
updatePhysicsAccordingToSpeedButtons(Game game) { with (game)
{
    void upd(int howmany = 1)
    {
        if (howmany-- > 0)
            game.syncNetworkThenUpdateOnce();
        while (howmany--)
            game.updateOnceWithoutSyncingNetwork();
        altickLastUpdate = al_get_timer_count(basics.alleg5.timer);
    }

    // We don't set/unset pause based on the buttons here. This is done by
    // the panel itself, in Panel.calcSelf().
    if (   pan.speedBack.executeLeft
        || pan.speedBack.executeRight
        || pan.restart.execute
    ) {
        int whatUpdateToLoad
            = pan.speedBack.executeLeft  ? cs.update - 1
            : pan.speedBack.executeRight ? cs.update - Game.updatesBackMany
            : 0;
        GameState state = (whatUpdateToLoad <= 0)
                        ? stateManager.zero
                        : stateManager.autoBeforeUpdate(whatUpdateToLoad + 1);
        assert (state, "at least the zero state should be good here");
        game.loadStateAffectAltickLastUpdate(state);
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



package void
loadStateWithoutAffectingAltickLastUpdate(Game game, GameState state)
{
    if (state) {
        game.cs = state.clone();
        game.pan.setLikeTribe(game.tribeLocal);
        game.effect.deleteAfter(game.cs.update);
    }
}



package void
loadStateAffectAltickLastUpdate(Game game, GameState state) { with (game)
{
    if (state) {
        game.loadStateWithoutAffectingAltickLastUpdate(state);
        altickLastUpdate = al_get_timer_count(basics.alleg5.timer);
        foreach (hatch; cs.hatches)
            hatch.animate(effect, cs.update);
    }
}}
