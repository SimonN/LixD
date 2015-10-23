module menu.preview;

/* A GUI element that displays a level thumbnail.
 * Part of package menu, not gui, because only the large menus use it.
 */

import basics.alleg5;
import basics.globals;
import basics.help; // rounding
import gui;
import graphic.color;
import graphic.graphic;
import graphic.gralib;
import graphic.torbit;
import level.level;

class Preview : Frame {

public:

    this(Geom g)
    {
        super(g);
        _status = LevelStatus.BAD_EMPTY;
        auto cb = getInternal(fileImagePreviewIcon);
        iconStatus = new Graphic(cb, guiosd);
        iconTorus  = new Graphic(cb, guiosd);
        undrawColor  = color.guiM;
        iconTorus.yf = 1;
    }

    ~this()
    {
        if (torbit) destroy(torbit);
        torbit = null;
    }

    @property LevelStatus status() { return _status; }

//  @property void level(in Level); -- to clear, set it to null

private:

    LevelStatus _status;
    Torbit  torbit; // the little canvas, sized like (this), to draw on
    Graphic iconStatus;
    Graphic iconTorus;



public @property void
level(in Level level)
{
    if (torbit) destroy(torbit);
    if (level !is null) {
        torbit  = level.create_preview(
            (xs + xls).roundInt - xs.roundInt,
            (ys + yls).roundInt - ys.roundInt, color.guiM);
        _status = level.status;
        iconStatus.xf = status;
        iconTorus .xf = level.torusX + 2 * level.torusY;
        if (_status == LevelStatus.BAD_EMPTY)
            iconStatus.xf = 0;
    }
    else {
        torbit = null;
        iconStatus.xf = 0;
        iconTorus .xf = 0;
    }
    reqDraw();
}



protected override void
drawSelf()
{
    super.drawSelf();

    if (torbit)
        guiosd.drawFrom(torbit.albit, xs.roundInt, ys.roundInt);
    else
        // target is guiosd already, because we're in an Element's draw
        al_draw_filled_rectangle(xs, ys, xs + xls, ys + yls, undrawColor);

    iconStatus.set_xy(xs, ys);                iconStatus.draw();
    iconStatus.y = ys + yls - iconStatus.yl; iconStatus.draw();
    iconStatus.x = xs + xls - iconStatus.xl; iconStatus.draw();
    iconStatus.y = ys;                        iconStatus.draw();

    iconTorus.set_xy(xs, ys);
    iconTorus.draw();
}

}
// end class Preview
