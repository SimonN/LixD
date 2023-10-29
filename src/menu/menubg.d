module menu.menubg;

import std.algorithm : max;
import std.conv : to;

import basics.rect;
import basics.alleg5;
import graphic.internal;
import gui;

class MenuWithBackground : Window {
public:
    this(Geom g, string ti = "") { super(g, ti); }

protected:
    override void drawSelf()
    {
        auto bg = InternalImage.menuBackground.toCutbit;
        if (bg && bg.valid) {
            immutable bgRect = Rect(0, 0, bg.xl, bg.yl);
            immutable screenRect = Rect(0, 0,
                gui.screenXls.to!int, gui.screenYls.to!int);
            immutable goal = bgRect.scaleUntilItCoversAtLeast(screenRect);
            al_draw_scaled_bitmap(cast (Albit) bg.albit,
                0, 0, bg.xl, bg.yl,
                goal.x, goal.y, goal.xl, goal.yl, 0);
        }
        else {
            torbit.clearToBlack();
        }
        super.drawSelf();
    }
}

private:

void assertSmaller(T)(in T a, in T b, in string name)
{
    assert (a <= b,
        "Failed " ~ name ~ ": " ~ a.to!string ~ " <= " ~ b.to!string);
}

Rect scaleUntilItCoversAtLeast(
    in Rect toScale,
    in Rect toCover) pure @safe
in {
    assert (toScale.xl > 0, "Can't scale 0 width to cover more than 0");
    assert (toScale.yl > 0, "Can't scale 0 height to cover more than 0");
}
out (ret) {
    assertSmaller(ret.x, toCover.x, ".x");
    assertSmaller(ret.y, toCover.y, ".y");
}
do {
    immutable double scalingFactor
        = max(1.0 * toCover.xl / toScale.xl, 1.0 * toCover.yl / toScale.yl);
    immutable Point retLength = Point(
        (toScale.xl * scalingFactor).to!int,
        (toScale.yl * scalingFactor).to!int);
    assertSmaller(toCover.xl, retLength.x, ".xl");
    assertSmaller(toCover.yl, retLength.y, ".yl");
    return Rect(toCover.center - retLength / 2, retLength.x, retLength.y);
}

unittest {
    void testWithSourceSquare(int n) {
        Rect a = Rect(0, 0, n, n);
        assert (a.scaleUntilItCoversAtLeast(a) == a);

        Rect b = Rect(99, 99, 200, 100);
        /*
         * To cover b, a must be aspect-scaled 2x to match the xl; aScaled will
         * then have yl = 200. Because b.yl is only 100, we'll show the center
         * yl range = [50, 150], i.e., we'll have to move aScaled up by 50.
         */
        Rect aCoveringB = Rect(99, 99 - 50, 200, 200);
        assert (a.scaleUntilItCoversAtLeast(b) == aCoveringB);

        Rect c = Rect(99, 99, 100, 200);
        Rect aCoveringC = Rect(99 - 50, 99, 200, 200);
        assert (a.scaleUntilItCoversAtLeast(c) == aCoveringC);
    }
    testWithSourceSquare(25);
    testWithSourceSquare(100);
    testWithSourceSquare(1000);
}
