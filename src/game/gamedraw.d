module game.gamedraw;

import std.range : retro;
import std.string; // format

import basics.alleg5;
import game;
import graphic.gadget;
import graphic.map;
import graphic.torbit;
import hardware.display;
import hardware.tharsis;

private string _gadgetCountStr = "hallo";

package void
implGameDraw(Game game) { with (game)
{
    auto zo = Zone(profiler, "game entire implGameDraw()");

    if (physicsDrawer.anyChangesToLand) {
        assert (cs.land);
        assert (cs.land.albit);
        with (Zone(profiler, "game physDraw 1 or more")) {
            DrawingTarget target = cs.land.albit;
            physicsDrawer.applyChangesToLand(cs.update);
        }
        assert (! physicsDrawer.anyChangesToLand);
    }

    with (Zone(profiler, "game entire drawing to map"))
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
                _gadgetCountStr = format("game %d gadgets, %s",
                                       _profilingGadgetCount, level.name);
            }

        with (Zone(profiler, _gadgetCountStr))
            cs.foreachGadget((Gadget g) {
                with (Zone(profiler, "game draws one gadget"))
                    g.draw(map);
            });

        with (Zone(profiler, "game draws land to map"))
            map.loadCameraRectangle(game.cs.land);

        with (Zone(profiler, "game draws lixes")) {
            void drawAllLixes(Tribe tr)
            {
                foreach (lix; tr.lixvec.retro) if (! lix.marked) lix.draw();
                foreach (lix; tr.lixvec.retro) if (  lix.marked) lix.draw();
            }
            foreach (otherTribe; cs.tribes)
                if (otherTribe !is tribeLocal)
                    drawAllLixes(otherTribe);
            drawAllLixes(tribeLocal);
        }
    }
    // end drawing target = map

    with (Zone(profiler, "game draws map to screen"))
        map.drawCamera(al_get_backbuffer(hardware.display.display));

    with (Zone(profiler, "game draws ingame text")) {
        import graphic.textout;
        drawText(djvuM, "[ESC] aborts. Please don't hit [ESC] during benchmarking.",
            10, 10, graphic.color.color.white);
        drawText(djvuM, std.string.format("Frames per second: %d",
            displayFps), 10, 40, graphic.color.color.white);
        drawText(djvuM, effect.toString(),
            10, 70, graphic.color.color.white);
    }

    static if (false) {
        if (hardware.keyboard.keyTapped(ALLEGRO_KEY_P)) {
            import file.filename;

            cs.land.saveToFile(new Filename("./debug-land.png"));
            map    .saveToFile(new Filename("./debug-map-directsave.png"));
            Torbit debugOutput = new Torbit(displayXl, displayYl);
            debugOutput.clearToColor(graphic.color.color.guiD);
            scope (exit)
                destroy(debugOutput);
            map.drawCamera(debugOutput.albit);
            debugOutput.saveToFile(new Filename("./debug-map-drawsave.png"));
        }
    }

}}
// end with(game), end implGameDraw()
