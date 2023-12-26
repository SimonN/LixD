module game.core.draw;

import std.algorithm;
import std.conv; // replay sign
import std.math; // sin, for replay sign
import std.range : retro;
import std.string; // format

import basics.alleg5;
import basics.globals : ticksPerSecond;
import file.option : showFPS;
import game.core.assignee;
import game.core.game;
import game.panel.tooltip;
import graphic.camera.mapncam;
import graphic.color;
import graphic.cutbit; // replay sign
import graphic.gadget;
import graphic.internal;
import graphic.torbit;
import hardware.display;
import hardware.music;
import hardware.tharsis;
import physics.tribe;
import physics.lixxie.fuse : drawAbilities; // onto opponents, behind our own

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
        auto drata = TargetTorbit(map.torbit);
        map.clearSourceThatWouldBeBlitToTarget(level.bgColor);
        game.drawGadgets();

        if (modalWindow || ! pan.splatRulerIsOn || ! isMouseOnLand) {
            game.drawLand();
            game.pingOwnGadgets();
        }
        else {
            _splatRuler.considerBackgroundColor(level.bgColor);
            _splatRuler.determineSnap(nurse.constStateForDrawingOnly.lookup,
                map.mouseOnLand);
            _splatRuler.drawBelowLand(map.torbit);
            game.drawLand();
            game.pingOwnGadgets();
            _splatRuler.drawAboveLand(map.torbit);
        }
        assert (_effect);
        _effect.draw(_chatArea.console);
        _effect.calc(); // --timeToLive, moves. No physics, so OK to calc here.
        game.drawAllLixes();
    }
    pan.showInfo(localTribe);
    foreach (sc; nurse.scores)
        pan.update(sc);
    pan.age = nurse.constStateForDrawingOnly.age;

    game.showSpawnIntervalOnHatches();
    game.drawMapToA5Display();
    game.ensureMusic();
}}
// end with(game), end implGameDraw()

private:

void drawGadgets(Game game) { with (game)
{
    version (tharsisprofiling)
        auto zone = Zone(profiler, "game draws gadgets");
    auto cs = nurse.constStateForDrawingOnly;

    cs.foreachConstGadget(delegate void (const(Gadget) g) {
        g.draw(localTribe.style);
    });
    if (cs.nukeIsAssigningExploders
		&& ! cs.tribes.byValue.all!(tr => tr.outOfLix)
	) {
        foreach (g; cs.goals)
            g.drawNoSign();
    }
}}

void pingOwnGadgets(Game game) { with (game)
{
    if (! multiplayer)
        return;
    immutable remains = _altickHighlightGoalsUntil - timerTicks;
    if (remains < 0) {
        // Usually, we haven't clicked the cool shades button.
        // Merely draw the own goals with semi-transparent extra lixes.
        foreach (g; nurse.gadgetsOfTeam(localTribe.style))
            g.drawExtrasOnTopOfLand(localTribe.style);
    }
    else {
        // Draw the glaring black-and-white rectangles.
        immutable int period = ticksPerSecond / 4;
        assert (period > 0);
        if (remains % period < period / 2)
            return; // draw nothing extra during the off-part of flashing
        foreach (g; nurse.gadgetsOfTeam(localTribe.style)) {
            enum th = 5; // thickness of the border
            Rect outer = Rect(g.loc - Point(th, th), g.xl + 2*th, g.yl + 2*th);
            Rect inner = Rect(g.loc, g.xl, g.yl);
            map.torbit.drawFilledRectangle(outer, color.white);
            map.torbit.drawFilledRectangle(inner, color.black);
            g.draw(localTribe.style);
        }
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
        foreach (li; localTribe.lixvec.retro) {
            li.drawAbilities();
        }
        drawTribe(localTribe);
    }
    const underCursor = game.findUnderCursor(game.pan.chosenSkill);
    game.describeInPanel(underCursor);
    // We'll show these tooltips in _panelExplainer. Better semantically is
    // _mapClickExplainer, but that will be big and glaring. Good or annoying?
    game._panelExplainer.suggestTooltip(underCursor.goodTooltips);
    if (! underCursor.best.empty && underCursor.best.front.facingOkay) {
        underCursor.best.front.lixxie.drawAgainHighlit();
    }
}

void describeInPanel(Game game, in UnderCursor underCursor)
{
    if (underCursor.numLix == 0) {
        game.pan.dontDescribeTarget();
        return;
    }
    assert (! underCursor.best.empty);
    assert (underCursor.best.front.lixxie !is null);
    game.pan.describeTarget(
        underCursor.best.front.lixxie,
        underCursor.best.front.passport,
        underCursor.numLix);
}

void showSpawnIntervalOnHatches(Game game)
{
    game.pan.dontShowSpawnInterval();
    if (game.nurse.constStateForDrawingOnly.hatches.any!(h =>
        game.map.torbit.isPointInRectangle(game.map.mouseOnLand, h.rect)))
        game.pan.showSpawnInterval(game.localTribe.rules.spawnInterval);
}

void drawMapToA5Display(Game game)
{
    auto drata = TargetBitmap(al_get_backbuffer(theA5display));
    {
        version (tharsisprofiling)
            auto zo2 = Zone(profiler, "game draws map to screen");
        game.map.drawCamera();
    }
    game.drawReplaySign();
    game.drawTooltips();
}

void drawReplaySign(Game game)
{
    if (! game.nurse.hasFuturePlies || ! game.view.showReplaySign) {
        return;
    }
    const(Cutbit) rep = InternalImage.gameReplay.toCutbit;
    rep.drawToCurrentAlbitNotTorbit(Point(0,
        (rep.yl/5 * (1 + sin(timerTicks * 0.08f))).to!int));
}

void drawTooltips(Game game)
{
    game._panelExplainer.move(game._tweaker.shown
        ? game._tweaker.xlg : 0, game._panelExplainer.geom.y);
    game._mapClickExplainer.move(game._panelExplainer.geom.x, 0);
    if (game.canWeClickAirNowToCutGlobalFuture && game.isMouseOnLand) {
        game._mapClickExplainer.suggestTooltip(Tooltip.ID.clickToCancelReplay);
    }
    game._panelExplainer.suggestTooltip(game.pan.hoveredSkillOnlyForTooltip);
    if (game.pan.isSuggestingTooltip) {
        game._panelExplainer.suggestTooltip(game.pan.suggestedTooltip);
    }
}

void ensureMusic(const(Game) game)
{
    with (game.nurse.constStateForDrawingOnly) {
        if (! isMusicPlaying && age >= Tribe.firstSpawnWithoutHandicap)
            playMusic(someRandomMusic);
    }
}
