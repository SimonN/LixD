module menu.menubg;

import basics.alleg5;
import graphic.internal;
import gui;

class MenuWithBackground : Window {
public:
    this(Geom g, string ti = "") { super(g, ti); }

protected:
    override void drawSelf()
    {
        auto bg = InternalImage.menuBackground.toCutbit;
        if (bg && bg.valid)
            // DALLEGCONST: We have to cast
            al_draw_scaled_bitmap(cast (Albit) bg.albit, 0, 0, bg.xl, bg.yl,
                0, 0, gui.screenXls, gui.screenYls, 0);
        else
            torbit.clearToBlack();
        super.drawSelf();
    }
}
