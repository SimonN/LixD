module game.repedit.repedit;

/*
 * The replay editor that appears when we press the film-strip button.
 */

import game.repedit.oneline;
import graphic.color;
import gui;

class ReplayEditor : Element {
private:
    OneLine[] _entries;

public:
    this(Geom g)
    {
        super(g);
        /*
         * We don't undraw the ReplayEditor when we hide it.
         * color.transp means don't undraw. (Bad convention?)
         * Instead of undrawing, the Game will redraw all GUI, a hack.
         */
        import graphic.color;
        undrawColor = color.transp;

        import net.repdata; // debugging
        import net.ac; // debugging
        _entries ~= new OneLine(new Geom(10, 10, xlg-20, 20),
            function Ply() {
                Ply ret;
                ret.player = PlNr(0);
                ret.action = RepAc.ASSIGN_LEFT;
                ret.skill = Ac.builder;
                ret.update = Phyu(100);
                ret.toWhichLix = 3;
                return ret;
            }());
        addChild(_entries[0]);
    }

protected:
    override void drawSelf()
    {
        draw3DButton(xs, ys, xls, yls, color.guiL, color.guiM, color.guiD);
    }
}
