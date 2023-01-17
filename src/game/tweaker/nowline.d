module game.tweaker.nowline;

/*
 * The single line that tells us the current physics update (phyu).
 */

import file.language;
import gui;
import game.tweaker.oneline;
import net.phyu;

class NowLine : OneLine {
private:
    Label _nowText;
    Phyu _now;

public:
    this(Geom g)
    {
        super(g);
        _nowText = new Label(new Geom(
            butXlg + textButtonDistXg(g), 0, textXlg(g), ylg),
            Lang.tweakerLineNow.transl);
        addChild(_nowText);
    }

    static float textButtonDistXg(in Geom fullLineGeom)
    {
        // Space between the leftmost button (X) and the "Now" text.
        return thickg;
    }

    static float textXlg(in Geom fullLineGeom)
    {
        return fullLineGeom.xlg
            - textButtonDistXg(fullLineGeom) - phyuXlg - 3 * butXlg;
            //+ 10f; // Add back a little to allow some overlap with phyu.
    }
}
