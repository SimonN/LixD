module gui.cutbitel;

/* cutbit may be null */

import std.algorithm;
import std.conv;

import graphic.cutbit;
import gui.element;
import gui.geometry;
import gui.root; // where to draw the cutbit

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
        if (! _shrink || (cbX > xs && cbY > ys))
            // draw the cutbit to the center of this's Element area, no matter
            // what this.geom.from says. Cutbits must be drawn to scale,
            // they look ugly if scaled up. GUI elements are loaded in an
            // appropriate size from disk.
            cutbit.draw(guiosd, Point(cbX.to!int, cbY.to!int), _xf, _yf);
        else {
            // The cutbit is too large. Shrink, preserving the aspect ratio.
            immutable scal = min(xls / cutbit.xl, yls / cutbit.yl);
            static assert (is (typeof(scal) == immutable(float)));
            cbX = xs + (xls - cutbit.xl * scal) / 2f;
            cbY = ys + (yls - cutbit.yl * scal) / 2f;
            cutbit.draw(guiosd, Point(cbX.to!int, cbY.to!int),
                _xf, _yf, 0, 0, scal);
        }
    }
}
