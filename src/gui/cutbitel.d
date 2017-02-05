module gui.cutbitel;

/* cutbit may be null */

import std.algorithm;
import std.conv;

import graphic.cutbit;
import gui.element;
import gui.geometry;

class CutbitElement : Element {
private:
    int _xf;
    int _yf;
    bool _shrink; // when cutbit too large, shring to this's geom

public:
    const(Cutbit) cutbit;

    this(Geom g, const(Cutbit) cb) { super(g); cutbit = cb; }

    @property auto xfs() const { return cutbit ? cutbit.xfs : 0; }
    @property auto yfs() const { return cutbit ? cutbit.yfs : 0; }
    mixin (GetSetWithReqDraw!"xf");
    mixin (GetSetWithReqDraw!"yf");
    mixin (GetSetWithReqDraw!"shrink");

protected:
    override void drawSelf()
    {
        if (! cutbit)
            return;
        float cbX = xs + (xls - cutbit.xl) / 2f;
        float cbY = ys + (yls - cutbit.yl) / 2f;
        auto scal = min(xls / cutbit.xl, yls / cutbit.yl); // Shrink, preserving the aspect ratio.
        static assert (is (typeof(scal) == float));
        if (! _shrink || (cbX > xs && cbY > ys))
            // Draw the cutbit to the center of this's Element area.
            // Allow upscaling only by an integer factor, otherwise
            // they look ugly if scaled up. GUI elements are loaded in an
            // appropriate size from disk.
            scal = max(1, cast(int)scal);
        cbX = xs + (xls - cutbit.xl * scal) / 2f;
        cbY = ys + (yls - cutbit.yl * scal) / 2f;
        cutbit.draw(Point(cbX.to!int, cbY.to!int), _xf, _yf, 0, 0, scal == 1 ? 0 : scal);
    }
}
