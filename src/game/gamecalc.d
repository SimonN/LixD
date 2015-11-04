module game.gamecalc;

import basics.alleg5;
import game;

package void
implGameCalc(Game game) { with (game)
{
    // As always, get user input that affect physics first, then process it in
    // case we'll be doing calc_update() further down.
    game.implCalcPassive();
    game.implCalcActive();

    long updAgo = al_get_timer_count(timer) - game.altickLastUpdate;

    void upd(int howmany = 1)
    {
        if (howmany-- > 0)
            game.syncNetworkThenUpdateOnce();
        while (howmany--)
            game.updateOnceWithoutSyncingNetwork();
        game.altickLastUpdate = al_get_timer_count(basics.alleg5.timer);
    }

    if (! pan.pause.on) {
        if (! pan.speedFast.on) {
            if (updAgo >= game.ticksNormalSpeed)
                upd();
        }
        else {
            upd(pan.speedFast.xf == Panel.frameTurbo ? 8 : 1);
        }
    }
    else {
        assert (pan.pause.on);
        if (pan.speedAhead.executeLeft) {
            upd();
        }
        else if (pan.speedAhead.executeRight) {
            upd(updatesAheadMany);
        }
    }
}}
// end with (game), end implGameCalc()



package void
implCalcActive(Game game)
{
}
// end clac_active()
