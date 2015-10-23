module game.gamecalc;

import basics.alleg5;
import game;

package void
implGameCalc(Game game)
{
    // As always, get user input that affect physics first, then process it in
    // case we'll be doing calc_update() further down.
    game.implCalcPassive();
    game.implCalcActive();

    long updAgo = al_get_timer_count(timer) - game.altickLastUpdate;

    void upd(int howmany = 1)
    {
        while (howmany--)
            game.updateOnce();
        game.altickLastUpdate = al_get_timer_count(basics.alleg5.timer);
    }

    if (updAgo >= game.ticksNormalSpeed)
        upd();
}
// end implGameCalc()



package void
implCalcActive(Game game)
{
}
// end clac_active()
