module game.core.draw;

import std.conv; // replay sign
import std.math; // sin, for replay sign
import std.range : retro;
import std.string; // format

import basics.alleg5;
import basics.globals; // replay sign
import game.core.game;
import game.tribe;
import graphic.color;
import graphic.cutbit; // replay sign
import graphic.gadget;
import graphic.internal;
import graphic.map;
import graphic.torbit;
import hardware.display;
import hardware.tharsis;

package void
implGameDraw(Game game) { with (game)
{
    auto zo = Zone(profiler, "game entire implGameDraw()");
    physicsDrawer.applyChangesToLand(cs.update);

    with (Zone(profiler, "game entire drawing to map"))
    {
        // speeding up drawing by setting the drawing target now.
        // This RAII struct is used in each innermost loop, too, but it does
        // nothing except comparing two pointers there if we've set stuff here.
        DrawingTarget drata = DrawingTarget(map.albit);

        map.clear_screen_rectangle(color.makecol(
            level.bgRed, level.bgGreen, level.bgBlue));
        game.drawGadgets();
        game.drawLand();
        effect.draw(map);
        effect.calc(); // --timeToLive, moves. No physics, so OK to calc here.
        game.drawAllLixes();
        pan.stats.showTribe(tribeLocal);
    }
    DrawingTarget drata = DrawingTarget(al_get_backbuffer(display));
    with (Zone(profiler, "game draws map to screen"))
        map.drawCamera();
    game.drawReplaySign();
}}
// end with(game), end implGameDraw()

private:

void drawGadgets(Game game)
{
    auto zone = Zone(profiler, "game draws gadgets");
    game.cs.foreachGadget((Gadget g) {
        with (Zone(profiler, "game draws one gadget"))
            g.draw(game.map, game.cs);
    });
}

void drawLand(Game game)
{
    auto zone = Zone(profiler, "game draws land to map");
    game.map.loadCameraRectangle(game.cs.land);
}

void drawAllLixes(Game game)
{
    auto zone = Zone(profiler, "game draws lixes");
    void drawAllLixesOfTribe(Tribe tr)
    {
        foreach (lix; tr.lixvec.retro)
            if (! lix.marked) {
                lix.prepareDraw();
                lix.draw(game.map);
            }
        foreach (lix; tr.lixvec.retro)
            if (lix.marked) {
                lix.prepareDraw();
                lix.draw(game.map);
            }
    }
    foreach (otherTribe; game.cs.tribes)
        if (otherTribe !is game.tribeLocal)
            drawAllLixesOfTribe(otherTribe);
    drawAllLixesOfTribe(game.tribeLocal);
}

void drawReplaySign(Game game)
{
    if (! game.replaying)
        return;
    const(Cutbit) rep = getInternal(fileImageGameReplay);
    rep.drawToCurrentTarget(0,
        (rep.yl/5 * (1 + sin(timerTicks * 0.08f))).to!int
    );
}
