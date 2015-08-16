module game.gamedraw;

import std.string; // format

import basics.alleg5;
import game.game;
import graphic.gadget;
import graphic.map;
import graphic.torbit;
import hardware.display;
import hardware.tharsis;

private string _gadget_count_str = "hallo";

package void
impl_game_draw(Game game) { with (game)
{
    auto zo = Zone(profiler, "game entire impl_game_draw()");
    with     (Zone(profiler, "game entire drawing to map"))
    {
        // speeding up drawing by setting the drawing target now.
        // This RAII struct is used in each innermost loop, too, but it does
        // nothing except comparing two pointers there if we've set stuff here.
        DrawingTarget drata = DrawingTarget(map.albit);

        with (Zone(profiler, "game clear screen to color"))
            map.clear_screen_rectangle(AlCol(game.level.bg_red,
                                             game.level.bg_green,
                                             game.level.bg_blue, 1.0));

        if (_profiling_gadget_count == 0)
            with (Zone(profiler, "game counts gadgets, basic loop")) {
                cs.foreach_gadget((Gadget g) { ++_profiling_gadget_count; } );
                _gadget_count_str = format("game %d gadgets, %s",
                                       _profiling_gadget_count, level.name);
            }

        with (Zone(profiler, _gadget_count_str))
            cs.foreach_gadget((Gadget g) {
                with (Zone(profiler, "game draws one gadget"))
                    g.draw();
            });

        with (Zone(profiler, "game draws land to map"))
            map.load_camera_rectangle(game.cs.land);
    }
    // end drawing target = map

    with (Zone(profiler, "game draws map to screen"))
        map.draw_camera(al_get_backbuffer(hardware.display.display));

    // debugging
    with (Zone(profiler, "game draws debugging text")) {
        import graphic.textout;
        draw_text(djvu_m, "Press [ESC] to go back to the menu.",
            10, 10, graphic.color.color.white);
        draw_text(djvu_m, "Press [P] to save the map bitmaps to files.",
            10, 40, graphic.color.color.white);
        draw_text(djvu_m, std.string.format("Frames per second: %d",
            display_fps), 10, 70, graphic.color.color.white);
    }

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
