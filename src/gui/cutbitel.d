module gui.cutbitel;

/* cutbit may be null */

import std.algorithm;
import std.conv;
import std.math;

public import graphic.cutbit;

import gui.element;
import gui.geometry;

class CutbitElement : Element {
private:
    int _xf;
    int _yf;

    // When cutbit is too large, always shring to this's geom.
    // When the cutbit is too small, do we upscale or leave blank room?
    bool _allowUpscaling = true;

public:
    const(Cutbit) cutbit;

    this(Geom g, const(Cutbit) cb) { super(g); cutbit = cb; }

    @property auto xfs() const { return cutbit ? cutbit.xfs : 0; }
    @property auto yfs() const { return cutbit ? cutbit.yfs : 0; }
    mixin (GetSetWithReqDraw!"xf");
    mixin (GetSetWithReqDraw!"yf");
    mixin (GetSetWithReqDraw!"allowUpscaling");

protected:
    override void drawSelf()
    {
        if (! cutbit)
            return;
        float cbX = xs + (xls - cutbit.xl) / 2f;
        float cbY = ys + (yls - cutbit.yl) / 2f;
        // Shrink, preserving the aspect ratio. Avoid div by 0 on !valid.
        float scal = cutbit.valid ? min(xls / cutbit.xl, yls / cutbit.yl) : 1;
        if (scal >= 1)
            // Allow upscaling only by integers for good looks, or not at all.
            scal = _allowUpscaling ? scal.floor : 1;
        if (scal < 1 && _allowUpscaling)
            // Never scale down UI, that would look sucky
            scal = 1;

        // Draw the cutbit to the center of this's Element area.
        cbX = xs + (xls - cutbit.xl * scal) / 2f;
        cbY = ys + (yls - cutbit.yl * scal) / 2f;
        cutbit.draw(Point(cbX.to!int, cbY.to!int), _xf, _yf, 0, 0,
                                                   scal == 1 ? 0 : scal);
    }
}
