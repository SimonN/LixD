module gui.cutbitel;

/* cutbit may be null */

import std.conv;

import graphic.cutbit;
import gui.element;
import gui.geometry;
import gui.root; // where to draw the cutbit

class CutbitElement : Element {
private:
    int _xf;
    int _yf;

public:
    const(Cutbit) cutbit;

    this(Geom g, const(Cutbit) cb) { super(g); cutbit = cb; }

    @property auto xfs() const { return cutbit ? cutbit.xfs : 0; }
    @property auto yfs() const { return cutbit ? cutbit.yfs : 0; }
    mixin (GetSetWithReqDraw!"xf");
    mixin (GetSetWithReqDraw!"yf");

protected:
    override void drawSelf()
    {
        if (! cutbit)
            return;
        // draw the cutbit to the center of this's Element area, no matter
        // what this.geom.from says. The cutbits can't scale, they're loaded
        // from file in an approximately correct size.
        immutable cbX = to!int(xs + xls / 2f - cutbit.xl / 2f);
        immutable cbY = to!int(ys + yls / 2f - cutbit.yl / 2f);
        cutbit.draw(guiosd, cbX, cbY, _xf, _yf);
    }
}
