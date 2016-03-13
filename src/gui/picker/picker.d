module gui.picker.picker;

import gui;
import gui.picker;

class Picker(T) : Frame
    if (is (T : Tiler))
{
    Ls _ls;
    Tiler _tiler;
    Scrollbar _scrollbar;

    this(Geom g)
    {
        assert (g.xl >= 20);
        super(g);
        _tiler     = new T        (new Geom(0, 0, g.xl - 20, g.yl));
        _scrollbar = new Scrollbar(new Geom(0, 0, 20, g.yl, From.RIGHT));
        _ls        = new Ls;
        addChildren(_tiler, _scrollbar);
        _scrollbar.totalLen = 10;
        _scrollbar.pageLen  =  5;
    }
}
