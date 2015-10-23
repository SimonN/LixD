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
implGameDraw(Game game) { with (game)
{
    auto zo = Zone(profiler, "game entire implGameDraw()");
    with     (Zone(profiler, "game entire drawing to map"))
    {
        // speeding up drawing by setting the drawing target now.
        // This RAII struct is used in each innermost loop, too, but it does
        // nothing except comparing two pointers there if we've set stuff here.
        DrawingTarget drata = DrawingTarget(map.albit);

        with (Zone(profiler, "game clear screen to color"))
            map.clear_screen_rectangle(AlCol(game.level.bgRed,
                                             game.level.bgGreen,
                                             game.level.bgBlue, 1.0));

        if (_profilingGadgetCount == 0)
            with (Zone(profiler, "game counts gadgets, basic loop")) {
                cs.foreachGadget((Gadget g) { ++_profilingGadgetCount; } );
                _gadget_count_str = format("game %d gadgets, %s",
                                       _profilingGadgetCount, level.name);
            }

        with (Zone(profiler, _gadget_count_str))
            cs.foreachGadget((Gadget g) {
                with (Zone(profiler, "game draws one gadget"))
                    g.draw();
            });

        with (Zone(profiler, "game draws land to map"))
            map.loadCameraRectangle(game.cs.land);
    }
    // end drawing target = map

    with (Zone(profiler, "game draws map to screen"))
        map.draw_camera(al_get_backbuffer(hardware.display.display));

    with (Zone(profiler, "game draws ingame text")) {
        import graphic.textout;
        drawText(djvuM, "Use the mouse to scroll around, as in the old Lix.",
            10, 10, graphic.color.color.white);
        drawText(djvuM, "[ESC] aborts. Please don't hit [ESC] during benchmarking.",
            10, 40, graphic.color.color.white);
        drawText(djvuM, std.string.format("Frames per second: %d",
            display_fps), 10, 70, graphic.color.color.white);
    }

    static if (false) {
        if (hardware.keyboard.keyTapped(ALLEGRO_KEY_P)) {
            import file.filename;

            cs.land.saveToFile(new Filename("./debug-land.png"));
            map    .saveToFile(new Filename("./debug-map-directsave.png"));
            Torbit debug_output = new Torbit(displayXl, displayYl);
            debug_output.clear_to_color(graphic.color.color.guiD);
            scope (exit)
                destroy(debug_output);
            map.draw_camera(debug_output.albit);
            debug_output.saveToFile(new Filename("./debug-map-drawsave.png"));
        }
    }

}}
// end with(game), end implGameDraw()
