module gui.score.bar;

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
import graphic.color;
import graphic.internal : getAlcol3DforStyle;
import gui;
import physics.fracint;
import physics.score;

package:

interface ScoreBar {
    Score score() const;
    void score(in Score sco)
    out { assert (score.potential <= maxPotential); }

    FracInt maxPotential() const;
    void maxPotential(in FracInt maxPot)
    in { assert (maxPot >= score.potential); }
    out { assert (score.potential <= maxPotential); }

    final Style style() const { return score.style; }
}

void updateMaxPotentials(T)(T[] arr)
    if (is (T : ScoreBar))
{
    if (arr.length == 0)
        return;
    immutable FracInt maxPot = arr.map!(bar => bar.score.potential).fold!max;
    arr.each!(bar => bar.maxPotential = maxPot);
}

class SimpleBar : Element, ScoreBar {
private:
    Score _score;
    FracInt _maxPotential;

public:
    this(Geom g) { super(g); }

    FracInt maxPotential() const { return _maxPotential; }
    void maxPotential(in FracInt mp)
    {
        if (mp == _maxPotential)
            return;
        reqDraw();
        _maxPotential = mp;
    }

    Score score() const { return _score; }
    void score(in Score sc)
    {
        if (sc == _score)
            return;
        reqDraw();
        _score = sc;
        _maxPotential = max(sc.potential, _maxPotential);
    }

    void update(in Score sco, in FracInt maxPot)
    in {
        assert (maxPot >= sco.lixSaved, "Need maxPot >= lixSaved w/ handi");
        assert (maxPot >= sco.potential, "Need maxPot >= potential w/ handi");
    }
    do {
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
        drawOneBar(1f, _score.lixSaved);
    }

private:
    void drawOneBar(
        in float ylFactor,
        in FracInt barLen, // barLen == maxPotential means full horz span
    ) {
        assert (ylFactor >= 0 && ylFactor <= 1, "bad ylFactor");
        assert (maxPotential >= barLen, "current score too large");
        if (barLen <= 0)
            return;
        immutable Alcol3D cols = getAlcol3DforStyle(score.style);
        draw3DButton(xs,
            ys + (yls * (1f - ylFactor)) / 2f,
            xls * barLen.as!double / maxPotential.as!double,
            yls * ylFactor,
            cols.l, cols.m, cols.d);
    }
}
