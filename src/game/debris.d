module game.debris;

/* Debris can be an arrow to show assignments during replays/network games,
 * but it can also be a flying tool, an explosion, or explosion particles.
 * Sound is not handled via debris.
 *
 * The EffectManager remembers, by a list of Effect, whether new Debris has to
 * be produced for past events, or not. Debris is supervised by EffectManager,
 * too, and means the actual flying pieces.
 *
 * x, y, speed are measured in map coordinates, not screen coordinates.
 * Stuff moves 2x as fast over the screen if map zoom is 2x.
 */

import std.algorithm;
import std.conv;
import std.math; // fmod, to rotate pickaxes
import std.random;

import basics.globals;
import file.filename;
import game.mask; // exploder offset
import graphic.color;
import graphic.internal;
import graphic.torbit;
import lix.enums;

// not a class, I'd like to avoid GC for many flying pixels
struct Debris {
    const(Type) type;
    int timeToLive;
    int x, y;
    int speedX, speedY;
    int frame; // yf for flying tools, xf for the Ac on arrows
    union {
        Style style; // for arrows
        AlCol col;   // for particles
        float rotCw; // for flying tools
    }

    enum Type {
        arrow,
        flyingTool,
        implosion,
        explosion,
        particle,
    }

    enum arrowTimeToLive = 50;

    static int debrisTimeToLive()
    {
        return uniform(40, 90);
    }

    static auto newArrow(in int ex, in int ey, in Style style, in int xf)
    {
        auto ret = typeof(this)(Type.arrow, arrowTimeToLive, ex, ey);
        ret.timeToLive = arrowTimeToLive;
        ret.style = style;
        ret.frame = xf;
        return ret;
    }

    static auto newImplosion(in int ex, in int ey)
    {
        auto cb = getInternal(fileImageImplosion);
        return typeof(this)(Type.implosion, cb.xfs, ex, ey);
    }

    static auto newExplosion(in int ex, in int ey)
    {
        auto cb = getInternal(fileImageExplosion);
        return typeof(this)(Type.explosion, cb.xfs + 2, ex, ey);
    }

    static auto newFlyingTool(in int ex, in int ey, in int dir,
                              in int toolFrame
    ) {
        auto cb = getInternal(fileImageDebris);
        auto ret = typeof(this)(Type.flyingTool, debrisTimeToLive,
            ex + 10 * dir, ey,
            uniform(1, 6) * dir, uniform(-11, -7),
            toolFrame);
        // Left-facing pickaxe starts with rotation, digging equipment doesn't.
        // toolFrame 0 is the pickaxe.
        ret.rotCw = (dir < 0 && toolFrame == 0) ? 1f : 0f;
        return ret;
    }

    void calc()
    {
        --timeToLive;
        final switch (type) {
            case Type.arrow:      calcArrow();      break;
            case Type.implosion:  break;
            case Type.explosion:  break;
            case Type.particle:   calcParticle();   break;
            case Type.flyingTool: calcFlyingTool(); break;
        }
    }

    void draw(Torbit tb)
    {
        final switch (type) {
            case Type.arrow:      drawArrow(tb);      break;
            case Type.flyingTool: drawFlyingTool(tb); break;
            case Type.implosion:  drawPlosion(tb, fileImageImplosion); break;
            case Type.explosion:  drawPlosion(tb, fileImageExplosion); break;
            case Type.particle:   drawParticle(tb);   break;
        }
    }

private:

    void moveThenAccelerateByGravity()
    {
        x += speedX;
        y += speedY;
        if (timeToLive % 2 == 0)
            speedY += 1;
    }

    void calcArrow()
    {
        // doesn't use speedY at all
        auto a = arrowTimeToLive - timeToLive - 3;
        assert (a >= -2, "already deducted 1 from TTL in Debris.calc()");
        y -=  a == -2 ? 8
            : a == -1 ? 4
            : a ==  0 ? 2
            : a ==  1 || a == 2 || a == 4 || a == 8 || a == 16 ? 1
            : 0;
    }

    void calcFlyingTool()
    {
        moveThenAccelerateByGravity();
        // The first 4 + is to produce positive values even with negative speed
        rotCw = fmod(4 + rotCw + speedX * 0.03125f, 4);
    }

    void calcParticle()
    {
        moveThenAccelerateByGravity();
    }

    void drawArrow(Torbit ground)
    {
        auto cbA = getInternal(fileImageGameArrow);
        auto cbI = getSkillButtonIcon(style);
        // x and y are the bottom tip of the arrow
        cbA.draw(ground, Point(x - cbA.xl/2, y - cbA.yl));
        cbI.draw(ground, Point(x - cbI.xl/2, y - cbA.yl*15/16), frame);
    }

    void drawFlyingTool(Torbit ground)
    {
        auto cb = getInternal(fileImageDebris);
        cb.draw(ground, Point(x - cb.xl/2, y - cb.yl/2),
                clamp(cb.xfs - timeToLive/4, 0, cb.xfs - 1),
                frame, false, rotCw);
    }

    void drawPlosion(Torbit ground, in Filename fn)
    {
        auto cb = getInternal(fn);
        cb.draw(ground, Point(x - cb.xl/2,
                              y - cb.yl/2 + game.mask.explodeMaskOffsetY),
                clamp(cb.xfs - timeToLive, 0, cb.xfs - 1));
    }

    void drawParticle(Torbit ground) { }
}
// end struct Debris
