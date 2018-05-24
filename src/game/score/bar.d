module game.score.bar;

/*
 * A single score bar, showing score and potential.
 * Many of these are drawn by the ScoreBoard or ScoreGraph.
 * We will even clear our background to black, it's more OO-like.
 *
 * Set us to the maximum width that we can ever draw, and keep it fixed.
 * Depending on how big our score is in relation to the maximum possible,
 * we won't draw all the way to the right anyway.
 */

import std.algorithm;

import basics.alleg5;
import game.score.score;
import graphic.color;
import graphic.internal : getAlcol3DforStyle;
import gui;

package:

interface ScoreBar {
    @property Score score() const;
    @property Score score(in Score sco)
    out { assert (score.potential <= maxPotential); }

    @property int maxPotential() const;
    @property int maxPotential(in int maxPot)
    in { assert (maxPot >= score.potential); }
    out { assert (score.potential <= maxPotential); }

    final @property Style style() const { return score.style; }
}

void updateMaxPotentials(T)(T[] arr)
    if (is (T : ScoreBar))
{
    if (arr.length == 0)
        return;
    immutable int maxPot = arr.map!(bar => bar.score.potential).fold!max;
    arr.each!(bar => bar.maxPotential = maxPot);
}

class SimpleBar : Element, ScoreBar {
private:
    Score _score;
    int _maxPotential;

public:
    this(Geom g) { super(g); }

    @property int maxPotential() const { return _maxPotential; }
    @property int maxPotential(in int mp)
    {
        if (mp == _maxPotential)
            return _maxPotential;
        reqDraw();
        return _maxPotential = mp;
    }

    @property Score score() const { return _score; }
    @property Score score(in Score sc)
    {
        if (sc == _score)
            return _score;
        reqDraw();
        _maxPotential = max(sc.potential, _maxPotential);
        return _score = sc;
    }

    void update(in Score sco, in int maxPot)
    in {
        assert (maxPot >= sco.current, "maxPotential lower than score");
        assert (maxPot >= sco.potential, "maxPotential lower than potential");
    }
    body {
        if (sco == _score && maxPot == _maxPotential)
            return;
        reqDraw();
        _score = sco;
        _maxPotential = maxPot;
    }

protected:
    override void drawSelf()
    {
        al_draw_filled_rectangle(xs, ys, xs + xls, ys + yls, color.black);
        drawOneBar(1f / 3f, _score.potential);
        drawOneBar(1f, _score.current);
    }

private:
    void drawOneBar(in float ylFactor, in int scoreValue)
    {
        assert (ylFactor >= 0 && ylFactor <= 1, "bad ylFactor");
        assert (maxPotential >= scoreValue, "current score too large");
        if (scoreValue <= 0)
            return;
        immutable Alcol3D cols = getAlcol3DforStyle(score.style);
        draw3DButton(xs,
            ys + (yls * (1f - ylFactor)) / 2f,
            xls * scoreValue / maxPotential,
            yls * ylFactor,
            cols.l, cols.m, cols.d);
    }
}
