module game.gamecalc;

import basics.alleg5;
import game.game;
import game.gamepass;
import game.gameupd;

package void
impl_game_calc(Game game)
{
    // As always, get user input that affect physics first, then process it in
    // case we'll be doing calc_update() further down.
    game.impl_calc_passive();
    game.impl_calc_active();

    long upd_ago = al_get_timer_count(timer) - game.altick_last_update;

    void upd(int howmany = 1)
    {
        while (howmany--)
            game.impl_calc_update();
        game.altick_last_update = al_get_timer_count(basics.alleg5.timer);
    }

    if (upd_ago >= game.ticks_normal_speed)
        upd();
}
// end impl_game_calc()



package void
impl_calc_active(Game game)
{
}
// end clac_active()
