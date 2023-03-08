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
        _nowText = new Label(new Geom(butXlg, 0, textXlg(g), ylg),
            Lang.tweakerLineNow.transl);
        addChild(_nowText);
    }

    static float textXlg(in Geom fullLineGeom)
    {
        return fullLineGeom.xlg - phyuXlg - 3 * butXlg;
    }
}
