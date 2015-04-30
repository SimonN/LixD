module menu.preview;

/* A GUI element that displays a level thumbnail.
 * Part of package menu, not gui, because only the large menus use it.
 */

import std.conv; // convert float to int when creating torbit fitting the gui

import basics.alleg5;
import basics.globals;
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
        auto cb = get_internal(file_bitmap_preview_icon);
        icon_status = new Graphic(cb, guiosd);
        icon_torus  = new Graphic(cb, guiosd);
        undraw_color  = color.gui_m;
        icon_torus.yf = 1;
    }

    ~this()
    {
        if (torbit) destroy(torbit);
        destroy(icon_status);
        destroy(icon_torus);
    }

    @property LevelStatus status() { return _status; }

//  @property void level(in Level); -- to clear, set it to null

private:

    LevelStatus _status;
    Torbit  torbit; // the little canvas, sized like (this), to draw on
    Graphic icon_status;
    Graphic icon_torus;



public @property void
level(in Level level)
{
    if (torbit) destroy(torbit);
    if (level !is null) {
        torbit  = level.create_preview(xls.to!int, yls.to!int, color.gui_m);
        _status = level.status;
        icon_status.xf = status;
        icon_torus .xf = level.torus_x + 2 * level.torus_y;
        if (_status == LevelStatus.BAD_EMPTY)
            icon_status.xf = 0;
    }
    else {
        torbit = null;
        icon_status.xf = 0;
        icon_torus .xf = 0;
    }
    req_draw();
}



protected override void
draw_self()
{
    super.draw_self();

    if (torbit)
        guiosd.draw_from(torbit.get_albit(), xs.to!int, ys.to!int);
    else
        // target is guiosd already, because we're in an Element's draw
        al_draw_filled_rectangle(xs, ys, xs + xls, ys + yls, undraw_color);

    icon_torus.set_xy(xls, yls);
    icon_torus.draw();

    icon_status.set_xy(xs, ys);             icon_status.draw();
    icon_status.y = ys + yls-icon_status.y; icon_status.draw();
    icon_status.x = xs + xls-icon_status.x; icon_status.draw();
    icon_status.y = ys;                     icon_status.draw();
}

}
// end class Preview
