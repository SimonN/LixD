module gui.cutbitel;

import std.conv; // to!int

import graphic.cutbit;
import gui.element;
import gui.geometry;
import gui.root; // where to draw the cutbit

class CutbitElement : Element {

    this(Geom g, const(Cutbit) cb)
    {
        super(g);
        _cutbit = cb;
    }

    mixin (GetSetWithReqDraw!"xf");
    mixin (GetSetWithReqDraw!"yf");
    @property auto xfs()    const { return _cutbit.xfs; }
    @property auto yfs()    const { return _cutbit.yfs; }
    @property auto cutbit() const { return _cutbit;     }

private:

    const(Cutbit) _cutbit;
    int           _xf;
    int           _yf;

protected:

    override void drawSelf()
    {
        // draw the cutbit to the center of this's Element area, no matter
        // what this.geom.from says. The cutbits can't scale, they're loaded
        // from file in an approximately correct size.
        immutable cbX = to!int(xs + xls / 2f - _cutbit.xl / 2f);
        immutable cbY = to!int(ys + yls / 2f - _cutbit.yl / 2f);
        _cutbit.draw(guiosd, cbX, cbY, _xf, _yf);
    }
}
