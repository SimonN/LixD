module game.core.draw;

import std.algorithm;
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
import hardware.music;
import hardware.tharsis;
import lix.skill.faller; // pixelsSafeToFall

package void
implGameDraw(Game game) { with (game)
{
    version (tharsisprofiling)
        auto zo = Zone(profiler, "game entire implGameDraw()");
    nurse.applyChangesToLand();
    {
        version (tharsisprofiling)
            auto zo2 = Zone(profiler, "game entire drawing to map");
        // speeding up drawing by setting the drawing target now.
        // This RAII struct is used in each innermost loop, too, but it does
        // nothing except comparing two pointers there if we've set stuff here.
        auto drata = TargetTorbit(map);
        with (level)
            map.clearScreenRect(color.makecol(bgRed, bgGreen, bgBlue));
        game.drawGadgets();
        game.drawLand();
        game.drawSplatRuler();
        game.pingOwnGadgets();

        assert (_effect);
        _effect.draw(_chatArea.console);
        _effect.calc(); // --timeToLive, moves. No physics, so OK to calc here.
        game.drawAllLixes();
    }
    pan.showInfo(localTribe);
    pan.update(nurse.scores);
    pan.age = nurse.constStateForDrawingOnly.update;
    game.showSpawnIntervalOnHatches();

    auto drata = TargetBitmap(al_get_backbuffer(display));
    {
        version (tharsisprofiling)
            auto zo2 = Zone(profiler, "game draws map to screen");
        map.drawCamera();
    }
    game.drawReplaySign();
    with (game.nurse.constStateForDrawingOnly)
        if (! isMusicPlaying && update >= updateFirstSpawn)
            suggestRandomMusic();
}}
// end with(game), end implGameDraw()

private:

void drawGadgets(Game game)
{
    version (tharsisprofiling)
        auto zone = Zone(profiler, "game draws gadgets");
    game.nurse.drawAllGadgets();
}

void pingOwnGadgets(Game game) { with (game)
{
    immutable remains = _altickPingGoalsUntil - timerTicks;
    if (remains < 0 || ! multiplayer)
        // Usually, we haven't clicked the cool shades button. Do nothing then.
        // Never ping hatches/exits in singleplayer either.
        return;
    immutable int period = ticksPerSecond / 2;
    assert (period > 0);
    if (remains % period < period / 2)
        return; // draw nothing extra during the off-part of flashing
    foreach (g; nurse.gadgetsOfTeam(localTribe.style)) {
        enum th = 3; // thickness of the border
        Rect outer = Rect(g.loc - Point(th, th), g.xl + 2*th, g.yl + 2*th);
        Rect inner = Rect(g.loc, g.xl, g.yl);
        map.drawFilledRectangle(outer, color.white);
        map.drawFilledRectangle(inner, color.black);
        g.draw();
    }
}}

void drawLand(Game game)
{
    version (tharsisproftsriling)
        auto zone = Zone(profiler, "game draws land to map");
    game.map.loadCameraRect(game.nurse.constStateForDrawingOnly.land);
}

void drawAllLixes(Game game)
{
    version (tharsisprofiling)
        auto zone = Zone(profiler, "game draws lixes");
    void drawTribe(in Tribe tr)
    {
        tr.lixvec.retro.filter!(l => ! l.marked).each!(l => l.draw);
        tr.lixvec.retro.filter!(l => l.marked).each!(l => l.draw);
    }
    with (game) {
        foreach (otherTribe; nurse.constStateForDrawingOnly.tribes)
            if (otherTribe !is game.localTribe)
                drawTribe(otherTribe);
        drawTribe(game.localTribe);
        if (_drawHerHighlit)
            _drawHerHighlit.drawAgainHighlit();
    }
}

void showSpawnIntervalOnHatches(Game game)
{
    game.pan.dontShowSpawnInterval();
    if (game.nurse.constStateForDrawingOnly.hatches.any!(h =>
        game.map.isPointInRectangle(game.map.mouseOnLand, h.rect)))
        game.pan.showSpawnInterval(game.localTribe.spawnint);
}

void drawReplaySign(Game game)
{
    if (game.replaying && game.view.showReplaySign) {
        const(Cutbit) rep = getInternal(fileImageGameReplay);
        rep.drawToCurrentAlbitNotTorbit(Point(0,
            (rep.yl/5 * (1 + sin(timerTicks * 0.08f))).to!int));
    }
}

///////////////////////////////////////////////////////////////////////////////
// Splat ruler ////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

void drawSplatRuler(Game game)
{
    if (game.modalWindow || ! game.pan.coolShadesAreOn)
        return;
    immutable snap = game.splatRulerSnap();
    game.drawSplatRulerBarBelowGivenStartOfFall(snap);
}

Point splatRulerSnap(in Game game)
{
    Point ret = game.map.mouseOnLand;
    bool solid()
    {
        return game.nurse.constStateForDrawingOnly.lookup.getSolidEven(ret);
    }
    // Find walkable terrain reasonably close under or over mouse cursor.
    // Walkable terrain is terrain with air at the pixel above.
    int upOrDown = solid() ? -1 : 1;
    foreach (int iters; 0 .. Faller.pixelsSafeToFall) {
        if (iters == Faller.pixelsSafeToFall - 1)
            return game.map.mouseOnLand; // nothing to snap to
        ret += Point(0, upOrDown);
        if (solid() == (upOrDown == 1))
            break;
    }
    if (! solid())
        ret += Point(0, 1);
    return ret;
}

void drawSplatRulerBarBelowGivenStartOfFall(Game game, Point startOfFall)
{
    enum wh = 40; // wh = width half, half of the line's x-length
    Point lower = startOfFall + Point(-wh, Faller.pixelsSafeToFall);
    Point ledge = startOfFall + Point(-wh, 0);
    Point upper = startOfFall + Point(-wh, -Faller.pixelsSafeToFall);

    void f(in Point p, in int plusY, in Alcol col)
    {
        game.map.drawFilledRectangle(Rect(p + Point(0, plusY), 2*wh, 1), col);
    }
    // draw vertical line
    foreach (int plusX; -1 .. 2) {
        float shade = plusX == -1 ? 0.3f : plusX == 0 ? 0.4f : 0.15f;
        game.map.drawFilledRectangle(
            Rect(upper + Point(wh + plusX, 0), 1, 2 * Faller.pixelsSafeToFall),
            Alcol(shade, shade, shade, shade));
    }
    // draw colored bars
    foreach (int plusY; 0 .. 5) {
        float shade = (1 - 0.2f * plusY);
        // shade *= 0.3f + 0.7f * (timerTicks * 0.03f).sin.abs; // no time-dep
        f(upper, plusY, game.level.bgBlue > 0xA0 // some by Rubix: bright bg
            ? Alcol(0, 0, 0, shade)
            : Alcol(shade * 0.2f, shade * 0.4f, shade, shade)); // blue
        f(ledge, plusY, Alcol(0, shade * 0.8f, 0, 0.8f * shade));
        f(lower, plusY, Alcol(shade, shade * 0.2f, shade * 0.2f, shade));
    }
}
