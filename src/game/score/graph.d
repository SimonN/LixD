module game.score.graph;

/* ScoreGraph: The UI element in multiplayer games that displays lovely
 * bar graphs of the current score and the potential score.
 * Sorted by current score.
 * This is a smaller version of a ScoreBoard. ScoreBoard has names and extra
 * numbers, ScoreGraph is only colored bars, no symbols to read.
 */

import std.algorithm;
import std.conv;

import game.score.bar;
import game.score.score;
import graphic.color;
import gui;

class ScoreGraph : Element {
private:
    ScoreBar[] bars; // not an associative array because we want to sort it
    Style _ourStyle; // tiebreak in favor of this for sorting

public:
    this(Geom g) { super(g); }

    void update(Score updatedScore)
    {
        auto found = bars.find!(bar => bar.style == updatedScore.style);
        if (found.length > 0 && found[0].score == updatedScore)
            return;

        ScoreBar toUpdate = found.length > 0 ? found[0] : newScoreBar();
        toUpdate.update(updatedScore, bars.map!(bar => bar.score.potential)
                                          .fold!max(updatedScore.potential));
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
    ScoreBar newScoreBar()
    {
        bars ~= new ScoreBar(new Geom());
        addChild(bars[$-1]);
        foreach (bar; bars)
            bar.resize(xlg - 4 * gui.thickg,
            (ylg - 4*gui.thickg) / bars.length);
        return bars[$-1];
    }

    void sortScores()
    {
        reqDraw();
        bars.sort!((a, b)
            => betterThanPreferringTeam(a.score, b.score, _ourStyle));
        foreach (int i, ScoreBar bar; bars)
            bar.move(2 * gui.thickg,
                2 * gui.thickg + (ylg - 4 * gui.thickg) * i / bars.length);
    }
}
