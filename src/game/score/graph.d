module game.score.graph;

/* ScoreGraph: The UI element in multiplayer games that displays lovely
 * bar graphs of the current score and the potential score.
 * Sorted by current score.
 * This is a smaller version of a ScoreBoard. ScoreBoard has names and extra
 * numbers, ScoreGraph is only colored bars, no symbols to read.
 */

import std.algorithm;
import std.range;

public import physics.score;

import basics.alleg5 : al_map_rgb_f;
import game.score.bar;
import graphic.color;
import gui;

class ScoreGraph : Element {
private:
    NukeBoxBar[] _bars; // not an AA because we want to sort it
    Style _ourStyle; // tiebreak in favor of this for sorting

public:
    this(Geom g) { super(g); }

    void update(Score updatedScore)
    {
        auto found = _bars.find!(bar => bar.style == updatedScore.style);
        if (found.length > 0 && found[0].score == updatedScore)
            return;
        NukeBoxBar toUpdate = found.length > 0 ? found[0] : newScoreBar();
        toUpdate.score = updatedScore;
        updateMaxPotentials(_bars);
        sortScores();
    }

    @property Style ourStyle(in Style st)
    {
        if (_ourStyle == st)
            return _ourStyle;
        _ourStyle = st;
        sortScores();
        return _ourStyle;
    }

protected:
    override void drawSelf()
    {
        alias th = gui.thicks;
        assert (xls >= 4*th);
        assert (yls >= 4*th);
        draw3DFrame(xs, ys, xls, yls, color.guiL, color.guiM, color.guiD);
        draw3DFrame(xs + th, ys + th, xls - 2*th, yls - 2*th,
            color.guiD, color.guiM, color.guiL);
    }

private:
    NukeBoxBar newScoreBar()
    {
        _bars ~= new NukeBoxBar(new Geom());
        addChild(_bars[$-1]);
        foreach (bar; _bars)
            bar.resize(xlg - 4 * gui.thickg,
            (ylg - 4*gui.thickg) / _bars.length);
        return _bars[$-1];
    }

    void sortScores()
    {
        reqDraw();
        _bars.sort!((a, b)
            => betterThanPreferringTeam(a.score, b.score, _ourStyle));
        _bars.enumerate!int.each!((i, Element bar) {
            bar.move(2 * gui.thickg,
                2 * gui.thickg + (ylg - 4 * gui.thickg) * i / _bars.length);
            });
    }
}

class NukeBoxBar : SimpleBar {
public:
    this(Geom g) { super(g); }

protected:
    override void drawSelf()
    {
        super.drawSelf();
        if (score.prefersGameToEnd)
            drawNukeOverlay();
    }

private:
    // When a player nukes or has finished playing, mark bar with a square
    void drawNukeOverlay()
    {
        Alcol grey(in float f) { return al_map_rgb_f(f, f, f); }
        immutable float boxXl = 10 * stretchFactor;
        draw3DButton(xs, ys, boxXl, yls, // draw a square
            grey(0.95f), grey(0.8f), grey(0.65f));
        draw3DButton(xs + gui.thicks, ys + gui.thicks,
            boxXl - 2*gui.thicks, yls - 2*gui.thicks,
            grey(0.00f), grey(0.15f), grey(0.3f));
    }
}
