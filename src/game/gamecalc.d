module game.gamecalc;

import basics.alleg5;
import game.game;
import graphic.color;
import hardware.keyboard;

package void
impl_game_calc(Game game)
{
    if (key_once(ALLEGRO_KEY_ESCAPE))
        game._goto_menu = true;

    // As always, get user input that affect physics first, then process it in
    // case we'll be doing calc_update() further down.
    game.calc_active();

    long upd_ago = al_get_timer_count(timer) - game.altick_last_update;
    if (upd_ago >= game.ticks_normal_speed) {
        game.calc_update();
    }

}
// end calc()



package void
impl_calc_update(Game game)
{
    scope (exit)
        game.altick_last_update = al_get_timer_count(basics.alleg5.timer);

    // do stuff here
}
// end calc_update()



package void
impl_calc_active(Game game)
{
}
// end clac_active()
