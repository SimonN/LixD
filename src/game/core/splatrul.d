module game.core.splatrul;

import std.algorithm;
import std.range;

import basics.alleg5;
import basics.rect;
import opt = file.option.allopts;
import game.core.game;
import graphic.torbit;
import physics.job.faller; // pixelsSafeToFall
import tile.phymap;

package:

SplatRuler createSplatRuler()
{
    switch (opt.splatRulerDesign.value) {
        case 0: default: return new SplatRulerTwoBars;
        case 1: return new SplatRuler094;
        case 2: return new SplatRulerHuge;
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
        // (snap) is the maximal snap distance near either end.
        immutable snap = maxSnapByOption(opt.splatRulerSnapPixels.value);
        _snapTarget = max(
            findSnapNear(phy, mouseOnLand, Point(0, half), snap),
            findSnapNear(phy, mouseOnLand, Point(0, -half), snap)).snapTo;
    }

    void drawAboveLand(Torbit tb) const
    {
        drawVerticalLine(tb, _snapTarget - Point(0, half),
            Faller.pixelsSafeToFall);
        enum wh = 40; // wh = half of the line's x-length
        immutable Point lower = _snapTarget + Point(-wh, half);
        immutable Point upper = _snapTarget + Point(-wh, -half);
        immutable col = al_map_rgb_f(0, 0.8f, 0);
        drawColoredBar(tb, upper, 2*wh, col, InvertBar.no);
        drawColoredBar(tb, lower, 2*wh, col, InvertBar.yes);
    }

    void drawBelowLand(Torbit) const { }
    void considerBackgroundColor(in Alcol) { }

private:
    static int maxSnapByOption(in int valueFromOption) pure nothrow @safe @nogc
    {
        /*
         * Allow disabling the ruler: 0 maps to 0. Allow the default to
         * produce the behavior of Lix <= 0.10.27: 126 maps to 10.
         * www.lemmingsforums.net/index.php?topic=6968.msg105028#msg105028
         */
        return valueFromOption < 126 ? valueFromOption / 12
            : valueFromOption - 116;
    }
}

unittest {
    assert (SplatRulerTwoBars.maxSnapByOption(0) == 0);
    assert (SplatRulerTwoBars.maxSnapByOption(126/2) == 10/2);
    assert (SplatRulerTwoBars.maxSnapByOption(124) == 10);
    assert (SplatRulerTwoBars.maxSnapByOption(126) == 10);
    assert (SplatRulerTwoBars.maxSnapByOption(128) == 12);
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
    override int barXl() const { return 80; }

    override bool canDrawWhenNotSnapped() const nothrow @safe @nogc
    {
        return opt.splatRulerSnapPixels.value == 0;
    }
}

/*
 * Simon's preferred splat ruler: Huge, wide, lots of default snap distance.
 */
class SplatRulerHuge : SplatRulerThreeBars {
public:
    void drawBelowLand(Torbit) const { }
    void drawAboveLand(Torbit tb) const { draw(tb); }

protected:
    override int barXl() const { return 120; }

    override bool canDrawWhenNotSnapped() const nothrow @safe @nogc
    {
        return true;
    }

    override void onDraw(Torbit tb, Point snapTarget) const
    {
        drawVerticalLine(tb, snapTarget - Point(0, Faller.pixelsSafeToFall),
            2 * Faller.pixelsSafeToFall);
    }
}

abstract class SplatRulerThreeBars : SplatRuler {
private:
    Snap _snap;
    bool _topBarIsBlack;

public:
    void determineSnap(in Phymap phy, in Point mouseOnLand)
    {
        _snap = findSnapNear(phy, mouseOnLand, Point(0, 0), maxSnap);
    }

    void considerBackgroundColor(in Alcol levelBg)
    {
        float _;
        float blue;
        al_unmap_rgb_f(levelBg, &_, &_, &blue);
        _topBarIsBlack = blue > 0.6f;
    }

protected:
    abstract int barXl() const;
    abstract bool canDrawWhenNotSnapped() const nothrow @safe @nogc;
    void onDraw(Torbit tb, Point snapTarget) const { }

    final void draw(Torbit tb) const
    {
        if (! _snap.atAll && ! canDrawWhenNotSnapped) {
            return;
        }
        onDraw(tb, _snap.snapTo);

        immutable Point ledge = _snap.snapTo + Point(-barXl() / 2, 0);
        immutable Point upper = ledge - Point(0, Faller.pixelsSafeToFall);
        immutable Point lower = ledge + Point(0, Faller.pixelsSafeToFall);
        drawColoredBar(tb, upper, barXl, _topBarIsBlack
            ? al_map_rgb_f(0, 0, 0)
            : al_map_rgb_f(0.2f, 0.4f, 1), InvertBar.no);
        drawColoredBar(tb, ledge, barXl,
            al_map_rgb_f(0, 0.8f, 0), InvertBar.no);
        drawColoredBar(tb, lower, barXl,
            al_map_rgb_f(1, 0.2f, 0.2f), InvertBar.no);
    }

private:
    static int maxSnap() nothrow @safe @nogc
    {
        return opt.splatRulerSnapPixels.value;
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
        immutable Point e = p - Point(p.x % 2, 0); // getSolidEven needs even x
        if (phy.getSolidEven(e) && ! phy.getSolidEven(e - Point(0, 1)))
            return Snap(true, badness, p - searchOffset);
    }
    return Snap(false, int.max, mouse);
}

void drawVerticalLine(Torbit tb, in Point topMiddle, in int height)
{
    foreach (int plusX; -1 .. 2) {
        float shade = plusX == -1 ? 0.3f : plusX == 0 ? 0.4f : 0.15f;
        tb.drawFilledRectangle(Rect(topMiddle + Point(plusX, 0),
            1, height), al_map_rgba_f(shade, shade, shade, shade));
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
            al_map_rgba_f(red * shade, green * shade, blue * shade,
                0.8f * shade));
    }
}
