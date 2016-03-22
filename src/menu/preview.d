module menu.preview;

/* A GUI element that displays a level thumbnail.
 * Part of package menu, not gui, because only the large menus use it.
 */

import basics.alleg5;
import basics.globals;
import basics.help; // rounding
import gui;
import graphic.graphic;
import graphic.internal;
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
    if (torbit)
        destroy(torbit);
    torbit        = null;
    iconStatus.xf = 0;
    iconTorus .xf = 0;

    if (level !is null) {
        torbit  = level.create_preview(
            (xs + xls).roundInt - xs.roundInt,
            (ys + yls).roundInt - ys.roundInt, undrawColor);
        _status = level.status;
        iconStatus.xf = status;
        iconTorus .xf = level.topology.torusX + 2 * level.topology.torusY;
        if (_status == LevelStatus.BAD_EMPTY)
            iconStatus.xf = 0;
    }
    reqDraw();
}



protected override void
drawSelf()
{
    super.drawSelf();

    if (torbit)
        guiosd.drawFrom(torbit.albit, Point(xs.roundInt, ys.roundInt));
    else
        // target is guiosd already, because we're in an Element's draw
        al_draw_filled_rectangle(xs, ys, xs + xls, ys + yls, undrawColor);

    void stampAt(in float x, in float y)
    {
        iconStatus.loc = Point(x.roundInt, y.roundInt);
        iconStatus.draw(guiosd);
    }
    stampAt(xs,                       ys);
    stampAt(xs,                       ys + yls - iconStatus.yl);
    stampAt(xs + xls - iconStatus.xl, ys);
    stampAt(xs + xls - iconStatus.xl, ys + yls - iconStatus.yl);

    iconTorus.loc = Point(xs.roundInt, ys.roundInt);
    iconTorus.draw(guiosd);
}

}
// end class Preview
