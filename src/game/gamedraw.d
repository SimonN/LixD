module game.gamedraw;

import basics.alleg5;
import game.game;
import graphic.gadget;
import graphic.map;
import graphic.torbit;
import hardware.display;

package void
impl_game_draw(Game game) { with (game)
{
    map.clear_screen_rectangle(AlCol(game.level.bg_red,
                                     game.level.bg_green,
                                     game.level.bg_blue, 1.0));

    cs.foreach_gadget((Gadget g) {
        g.draw();
    });

    map.load_camera_rectangle(game.cs.land);

    // DTODO: draw lix and other things here that go in front of the land

    map.draw_camera(al_get_backbuffer(hardware.display.display));



    // debugging
    import graphic.textout;
    draw_text(djvu_m, "Press [ESC] to go back to the menu.", 10, 10,
        graphic.color.color.white);
    draw_text(djvu_m, "Press [P] to save the map bitmaps to files.", 10, 40,
        graphic.color.color.white);
    draw_text(djvu_m, std.string.format("Frames per second: %d", display_fps),
        10, 70,
        graphic.color.color.white);

    static if (true) {
        if (hardware.keyboard.key_once(ALLEGRO_KEY_P)) {
            import file.filename;

            cs.land.save_to_file(new Filename("./debug-land.png"));
            map    .save_to_file(new Filename("./debug-map-directsave.png"));
            Torbit debug_output = new Torbit(display_xl, display_yl);
            debug_output.clear_to_color(graphic.color.color.gui_d);
            scope (exit)
                destroy(debug_output);
            map.draw_camera(debug_output.albit);
            debug_output.save_to_file(new Filename("./debug-map-drawsave.png"));
        }
    }

}}
// end with(game), end impl_game_draw()
