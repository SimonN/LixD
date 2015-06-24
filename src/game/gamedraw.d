module game.gamedraw;

import basics.alleg5;
import game.game;
import graphic.map;
import graphic.torbit;
import hardware.display;

package void
impl_game_draw(Game game) { with (game)
{
    map.clear_screen_rectangle(AlCol(game.level.bg_red,
                                     game.level.bg_green,
                                     game.level.bg_blue, 1.0));

    // DTODO: draw gadgets here if they go behind the land

    map.load_camera_rectangle(game.cs.land);

    // DTODO: draw gadgets here that go in front of the land

    map.draw_camera(al_get_backbuffer(hardware.display.display));


    // debugging
    import graphic.textout;
    draw_text(djvu_m, "Press [ESC] to go back to the menu.", 10, 10,
        graphic.color.color.white);

    static if (false) {
        if (my_debugging_counter == 0) {
            import file.filename;

            my_debugging_counter = 1;
            cs.land.save_to_file(new Filename("./debug-land.png"));
            map    .save_to_file(new Filename("./debug-map-directsave.png"));
            Torbit debug_output = new Torbit(display_xl, display_yl);
            scope (exit)
                destroy(debug_output);
            map.draw_camera(debug_output.albit);
            debug_output.save_to_file(new Filename("./debug-map-drawsave.png"));
        }
    }

}}
// end with(game), end impl_game_draw()
