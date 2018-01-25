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

import basics.alleg5;
import game.score.score;
import graphic.color;
import graphic.internal : getAlcol3DforStyle;
import gui;

package:

class ScoreBar : Element {
private:
    Score _score;
    int _maxPotential;

public:
    this(Geom g) { super(g); }
    @property Style style() const { return _score.style; }
    @property Score score() const { return _score; }
    @property int maxPotential() const { return _maxPotential; }

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
        if (_score.prefersGameToEnd)
            drawNukeOverlay();
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

    // When a player nukes or has finished playing, mark bar with a square
    void drawNukeOverlay()
    {
        Alcol grey(in float f) pure { return Alcol(f, f, f, 1); }
        draw3DButton(xs, ys, yls, yls, // draw a square
            grey(0.95f), grey(0.8f), grey(0.65f));
        draw3DButton(xs + gui.thicks, ys + gui.thicks,
            yls - 2*gui.thicks, yls - 2*gui.thicks,
            grey(0.00f), grey(0.15f), grey(0.3f));
    }
}
