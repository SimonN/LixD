module graphic.torbit.targtorb;

/* TargetTorbit is a wrapper around basics.alleg5.DrawingTarget.
 * Some drawing methods are only possible on the target torbit for efficiency.
 * (And it allows the level exporter to hijack the GUI drawing code, without
 * changing the GUI code or introducing extra arguments to that. >_>)
 */

import basics.alleg5;
import graphic.torbit;

// thread-local drawing target, like Allegro 5's target bitmap
private Torbit _targetTorbit = null;

bool isTargetTorbit(in Torbit tb)
{
    return tb is _targetTorbit;
}

void drawToTargetTorbit(in Albit src, in Point toCorner = Point(0, 0),
    in bool mirrY = false, in double rotCw = 0, in double scal = 0)
{
    assert (_targetTorbit);
    _targetTorbit.drawFrom(src, toCorner, mirrY, rotCw, scal);
}

void singlePixelToTargetTorbit(in Albit fromBmp, Point fromP, Point toP)
{
    assert (_targetTorbit);
    _targetTorbit.drawFromPixel(fromBmp, fromP, toP);
}

struct TargetTorbit {
private:
    Torbit _oldTarget;
    basics.alleg5.TargetBitmap _drawingTarget;

public:
    this(Torbit tb)
    {
        assert (tb);
        assert (tb.albit);
        _oldTarget = _targetTorbit;
        _drawingTarget = TargetBitmap(tb.albit);
        _targetTorbit = tb;
    }

    ~this()
    {
        _targetTorbit = _oldTarget;
    }
    @disable this();
    @disable this(this);
}
