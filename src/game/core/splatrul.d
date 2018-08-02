module game.core.splatrul;

import std.algorithm;
import std.range;

import basics.alleg5;
import basics.rect;
import game.core.game;
import graphic.torbit;
import lix.skill.faller; // pixelsSafeToFall
import tile.phymap;

package:

/*
 * PreferredSplatRuler has been replaced with a hidden user option: To set it,
 * run the game to generate `data/user/yourname.txt', exit the game,
 * open that file with a text editor, change the number in the line
 * #SPLAT_RULER_DESIGN 0 to either 0, 1, or 2:
 *
 * 0: SplatRulerTwoBars   -- Always draw, both top and bottom edge snap
 * 1: SplatRuler094       -- Three-bar ruler, drawn when snapped, like in 0.9.4
 * 2: SplatRulerSuperSnap -- Three-bar ruler, massive snap distance, long bars
 */
SplatRuler createSplatRuler()
{
    import file.option;
    switch (splatRulerDesign) {
        case 0: default: return new SplatRulerTwoBars;
        case 1: return new SplatRuler094;
        case 2: return new SplatRulerSuperSnap;
    }
}

interface SplatRuler {
    void determineSnap(in Phymap, in Point mouseOnLand);
    void drawBelowLand(Torbit tb) const; // draw to tb. We assume tb is target.
    void drawAboveLand(Torbit tb) const;
    void considerBackgroundColor(in Alcol);
}

private:

/*
 * A ruler designed by geoo, with only two bars.
 * Both the top and bottom can snap to terrain even far away from
 * the mouse cursor. If it doesn't snap, it's centered around the mouse
 * cursor, even though neither bar is here.
 */
class SplatRulerTwoBars : SplatRuler {
private:
    Point _snapTarget; // location of ruler's center, no bar is here

    enum half = Faller.pixelsSafeToFall / 2; // half of the ruler's height

public:
    void determineSnap(in Phymap phy, in Point mouseOnLand)
    {
        enum maxSnap = 10; // maximal snap distance near either end
        _snapTarget = max(Snap(true, int.max, mouseOnLand),
            findSnapNear(phy, mouseOnLand, Point(0, half), maxSnap),
            findSnapNear(phy, mouseOnLand, Point(0, -half), maxSnap)).snapTo;
    }

    void drawAboveLand(Torbit tb) const
    {
        drawVerticalLine(tb, _snapTarget - Point(0, half),
            Faller.pixelsSafeToFall);
        enum wh = 40; // wh = half of the line's x-length
        immutable Point lower = _snapTarget + Point(-wh, half);
        immutable Point upper = _snapTarget + Point(-wh, -half);
        drawColoredBar(tb, upper, 2*wh, Alcol(0, 0.8f, 0, 1), InvertBar.no);
        drawColoredBar(tb, lower, 2*wh, Alcol(0, 0.8f, 0, 1), InvertBar.yes);
    }

    void drawBelowLand(Torbit) const { }
    void considerBackgroundColor(in Alcol) { }
}

/*
 * A splat ruler like in Lix 0.9.4.
 * It has 3 bars. The center bar snaps to terrain near the mouse.
 * The top bar is usually blue; it is black when the level's bg is blue.
 */
class SplatRuler094 : SplatRulerThreeBars {
public:
    void drawBelowLand(Torbit tb) const { draw(tb); }
    void drawAboveLand(Torbit) const { }

protected:
    override @property int barXl() const { return 80; }
    override @property int maxSnap() const { return 64; }
}

/*
 * Simon's preferred splat ruler: Gigantic snap distance, never draw when
 * it doesn't snap. This is an even more glaring variant of the
 * 0.9.5-to-0.9.10 ruler.
 */
class SplatRulerSuperSnap : SplatRulerThreeBars {
public:
    void drawBelowLand(Torbit) const { }
    void drawAboveLand(Torbit tb) const { draw(tb); }

protected:
    override @property int barXl() const { return 120; }
    override @property int maxSnap() const { return 200; }

    override void onDraw(Torbit tb, Point snapTarget) const
    {
        drawVerticalLine(tb, snapTarget - Point(0, Faller.pixelsSafeToFall),
            2 * Faller.pixelsSafeToFall);
    }
}

abstract class SplatRulerThreeBars : SplatRuler {
private:
    bool _snapAtAll;
    Point _snapTarget; // location of green line, the measuring point
    bool _topBarIsBlack;

public:
    void determineSnap(in Phymap phy, in Point mouseOnLand)
    {
        Snap snap = findSnapNear(phy, mouseOnLand, Point(0, 0), maxSnap);
        _snapAtAll = snap.atAll;
        _snapTarget = snap.snapTo;
    }

    void considerBackgroundColor(in Alcol levelBg)
    {
        float _;
        float blue;
        al_unmap_rgb_f(levelBg, &_, &_, &blue);
        _topBarIsBlack = blue > 0.6f;
    }

protected:
    abstract @property int barXl() const;
    abstract @property int maxSnap() const;
    void onDraw(Torbit tb, Point snapTarget) const { }

    final void draw(Torbit tb) const
    {
        if (! _snapAtAll)
            return;
        onDraw(tb, _snapTarget);

        immutable Point ledge = _snapTarget + Point(-barXl() / 2, 0);
        immutable Point upper = ledge - Point(0, Faller.pixelsSafeToFall);
        immutable Point lower = ledge + Point(0, Faller.pixelsSafeToFall);
        drawColoredBar(tb, upper, barXl, _topBarIsBlack
            ? Alcol(0, 0, 0) : Alcol(0.2f, 0.4f, 1), InvertBar.no);
        drawColoredBar(tb, ledge, barXl, Alcol(0, 0.8f, 0), InvertBar.no);
        drawColoredBar(tb, lower, barXl, Alcol(1, 0.2f, 0.2f), InvertBar.no);
    }
}

struct Snap {
    bool atAll;
    int badness;
    Point snapTo;

    // Returns > 0 if we're better (= less worse) than rhs, < 0 if rhs better
    int opCmp(ref const Snap rhs) const
    {
        return atAll != rhs.atAll ? (atAll ? 1 : -1)
            : rhs.badness - badness;
    }
}

Snap findSnapNear(
    in Phymap phy, // the physics map to ask whether points are solid
    in Point mouse, // report found snap locations relative to this point
    in Point searchOffset, // where, relative to mouse, to search for snaps
    in int maxSnap, // maximal search distance near mouse+searchOffset
) {
    // plusY iterates over: 0, 1, -1, 2, -2, ..., maxSnap, -maxSnap.
    // badness iterates:    0, 1,  2, 3,  4, ..., 2*maxSnap-1, 2*maxSnap.
    foreach (int badness, int plusY;
        iota(-maxSnap, maxSnap + 1).radial.enumerate!int
    ) {
        immutable Point p = mouse + searchOffset + Point(0, plusY);
        if (phy.getSolidEven(p) && ! phy.getSolidEven(p - Point(0, 1)))
            return Snap(true, badness, p - searchOffset);
    }
    return Snap(false);
}

void drawVerticalLine(Torbit tb, in Point topMiddle, in int height)
{
    foreach (int plusX; -1 .. 2) {
        float shade = plusX == -1 ? 0.3f : plusX == 0 ? 0.4f : 0.15f;
        tb.drawFilledRectangle(Rect(topMiddle + Point(plusX, 0),
            1, height), Alcol(shade, shade, shade, shade));
    }
}

enum InvertBar : bool { no = false, yes = true }

void drawColoredBar(
    Torbit tb,
    in Point topLeft, // Point((left of bar's start), (interesting y-location))
    in int width, // full width (x-length) of all stripes
    in Alcol col, // color of the lightest stripe, we'll ignore its alpha
    InvertBar invert, // draw above the beginning instead of on-and-below
) {
    float red, green, blue;
    al_unmap_rgb_f(col, &red, &green, &blue);
    foreach (int stripe; 0 .. 5) {
        immutable float shade = (1 - 0.2f * stripe);
        tb.drawFilledRectangle(
            Rect(topLeft + Point(0, invert ? -1 - stripe : stripe), width, 1),
            Alcol(red * shade, green * shade, blue * shade, 0.8f * shade));
    }
}
