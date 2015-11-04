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
    long updAgo = al_get_timer_count(timer) - game.altickLastUpdate;

    void upd(int howmany = 1)
    {
        if (howmany-- > 0)
            game.syncNetworkThenUpdateOnce();
        while (howmany--)
            game.updateOnceWithoutSyncingNetwork();
        altickLastUpdate = al_get_timer_count(basics.alleg5.timer);
    }

    if (pan.speedAhead.executeLeft) {
        upd();
    }
    else if (pan.speedAhead.executeRight) {
        upd(updatesAheadMany);
    }
    else if (! pan.pause.on) {
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
