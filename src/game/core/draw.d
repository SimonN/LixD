module game.core.draw;

import std.algorithm;
import std.conv; // replay sign
import std.math; // sin, for replay sign
import std.range : retro;
import std.string; // format
import std.typecons;

import basics.alleg5;
import basics.globals : ticksPerSecond;
import file.option : showFPS;
import game.core.assignee;
import game.core.game;
import game.panel.tooltip;
import graphic.camera.mapncam;
import graphic.color;
import graphic.cutbit; // replay sign
import physics.gadget;
import graphic.internal;
import graphic.torbit;
import hardware.display;
import hardware.music;
import hardware.tharsis;
import physics.tribe;
import physics.lixxie.fuse : drawAbilities; // onto opponents, behind our own
import tile.draw : drawAllTriggerAreas;

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
            game.drawGadgetExtrasOnTopOfPing();
        }
        else {
            _splatRuler.considerBackgroundColor(level.bgColor);
            _splatRuler.determineSnap(cs.lookup, map.mouseOnLand);
            _splatRuler.drawBelowLand(map.torbit);
            game.drawLand();
            game.pingOwnGadgets();
            game.drawGadgetExtrasOnTopOfPing();
            _splatRuler.drawAboveLand(map.torbit);
        }
        assert (_effect);
        _effect.draw(_chatArea.console);
        _effect.calc(); // --timeToLive, moves. No physics, so OK to calc here.

        game.drawAllLixes();

        if (pan.splatRulerIsOn) {
            drawAllTriggerAreas(level.gadgets, map.torbit);
        }
    }
    game.describeHoveredGadgetInPanel();
    game.drawMapToA5Display();
    game.ensureMusic();
}}
// end with(game), end implGameDraw()

private:

void drawGadgets(Game game)
{
    version (tharsisprofiling)
        auto zone = Zone(profiler, "game draws gadgets");
    foreach (g; game.cs.allConstGadgets) {
        g.draw(game.cs.age, game.localTribe.style);
    }
}

void drawLand(Game game)
{
    version (tharsisproftsriling)
        auto zone = Zone(profiler, "game draws land to map");
    game.map.loadCameraRect(game.cs.land);
}

void pingOwnGadgets(Game game)
{
    if (game.cs.isPuzzle)
        return;
    immutable remains = game._altickHighlightGoalsUntil - timerTicks;
    if (remains < 0) {
        return;
    }
    // Draw the glaring black-and-white rectangles.
    immutable int period = ticksPerSecond / 4;
    assert (period > 0);
    if (remains % period < period / 2)
        return;
    immutable sty = game.localTribe.style;
    foreach (g; game.nurse.gadgetsOfTeam(sty)) {
        enum th = 5; // thickness of the border
        immutable Rect inner = g.occ.selboxOnMap;
        immutable Rect outer = Rect(inner.topLeft - Point(th, th),
            inner.xl + 2*th, inner.yl + 2*th);
        game.map.torbit.drawFilledRectangle(outer, color.white);
        game.map.torbit.drawFilledRectangle(inner, color.black);
        g.draw(game.cs.age, sty);
    }
}

void drawGadgetExtrasOnTopOfPing(Game game)
{
    immutable sty = game.localTribe.style;
    foreach (g; game.nurse.gadgetsOfTeam(sty)) {
        g.drawExtrasOnTopOfLand(sty);
    }
    if (game.cs.nukeIsAssigningExploders && ! game.nurse.everybodyOutOfLix) {
        foreach (g; game.cs.goals) {
            g.drawNoSign();
        }
    }
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
        foreach (otherTribe; cs.tribes.allTribesEvenNeutral)
            if (otherTribe !is game.localTribe)
                drawTribe(otherTribe);
        foreach (li; localTribe.lixvec.retro) {
            li.drawAbilities();
        }
        drawTribe(localTribe);
    }
    const underCursor = game.findUnderCursor(game.pan.chosenSkill);
    game.describeHoveredLixInPanel(underCursor);
    // We'll show these tooltips in _panelExplainer. Better semantically is
    // _mapClickExplainer, but that will be big and glaring. Good or annoying?
    game._panelExplainer.suggestTooltip(underCursor.goodTooltips);
    if (! underCursor.best.empty && underCursor.best.front.facingOkay) {
        underCursor.best.front.lixxie.drawAgainHighlit();
    }
}

void describeHoveredLixInPanel(Game game, in UnderCursor underCursor)
{
    if (underCursor.numLix == 0) {
        game.pan.describeNoLixxie();
        return;
    }
    assert (! underCursor.best.empty);
    assert (underCursor.best.front.lixxie !is null);
    game.pan.describeLixxie(
        underCursor.best.front.lixxie,
        underCursor.best.front.passport,
        underCursor.numLix);
}

void describeHoveredGadgetInPanel(Game game)
{
    if (game.isMouseOnLand) {
        const(Gadget) best = game.bestGadgetToDescribeOrNull();
        if (best !is null) {
            game.pan.describeGadget(game.cs.age, game.localTribe, best);
            return;
        }
    }
    game.pan.describeNoGadget();
}

private const(Gadget) bestGadgetToDescribeOrNull(Game game)
{
    immutable mol = game.map.mouseOnLand;
    Rebindable!(const(Gadget)) mediocreResult = null;

    foreach (g; game.cs.allConstGadgets) {
        if (! game.map.torbit.isPointInRectangle(mol, g.occ.selboxOnMap)) {
            continue;
        }
        immutable Rect trigA = g.tile.triggerArea + g.loc;
        if (game.map.torbit.isPointInRectangle(mol, trigA)) {
            return g; // An ideal result.
        }
        mediocreResult = g;
    }
    return mediocreResult;
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
    game._panelExplainer.suggestTooltip(game.pan.hoveredSkillOnlyForTooltip);
    if (game.pan.isSuggestingTooltip) {
        game._panelExplainer.suggestTooltip(game.pan.suggestedTooltip);
    }
}

void ensureMusic(const(Game) game)
{
    if (! isMusicPlaying && game.cs.age >= Tribe.firstSpawnWithoutHandicap)
        playMusic(someRandomMusic);
}
