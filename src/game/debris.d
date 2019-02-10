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

import basics.rect;
import file.filename;
import graphic.color;
import graphic.internal;
import graphic.torbit;
import net.ac;
import net.style;
import physics.mask; // exploder offset

// not a class, I'd like to avoid GC for many flying pixels
struct Debris {
    const(Type) type;
    int timeToLive;
    Point foot; // Not top-left of the debris sprite! Instead relative to foot.
    Point speed; // speed vector to be added to foot per frame
    int frame; // yf for flying tools, xf for the Ac on arrows
    union {
        Style style; // for arrows
        Alcol col;   // for particles
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
    enum framePickaxe = 0;

    static int debrisTimeToLive()
    {
        return uniform(40, 90);
    }

    static auto newArrow(in Point foot, in Style style, in Ac ac)
    {
        auto ret = typeof(this)(Type.arrow, arrowTimeToLive, foot);
        ret.timeToLive = arrowTimeToLive;
        ret.style = style;
        ret.frame = ac.acToSkillIconXf;
        return ret;
    }

    static auto newImplosion(in Point foot)
    {
        auto cb = InternalImage.implosion.toCutbit;
        return typeof(this)(Type.implosion, cb.xfs, foot);
    }

    static auto newExplosion(in Point foot)
    {
        auto cb = InternalImage.explosion.toCutbit;
        return typeof(this)(Type.explosion, cb.xfs + 2, foot);
    }

    static auto newFlyingTool(in Point foot, in int dir, in int toolFrame
    ) {
        auto cb = InternalImage.debris.toCutbit;
        auto ret = typeof(this)(Type.flyingTool, debrisTimeToLive,
            foot + Point(10 * dir, 0),
            Point(uniform(1, 6) * dir, uniform(-11, -7)),
            toolFrame);
        // Left-facing pickaxe starts with nonzero rotation.
        // Right-facing pickaxe starts in its default rotation 0.
        ret.rotCw = (dir < 0 && toolFrame == framePickaxe) ? 1f : 0f;
        return ret;
    }

    void calc()
    {
        --timeToLive;
        final switch (type) {
            case Type.arrow: calcArrow(); break;
            case Type.implosion: break;
            case Type.explosion: break;
            case Type.particle: calcParticle(); break;
            case Type.flyingTool: calcFlyingTool(); break;
        }
    }

    void draw()
    {
        final switch (type) {
            case Type.arrow: drawArrow(); break;
            case Type.flyingTool: drawFlyingTool(); break;
            case Type.implosion: drawPlosion(InternalImage.implosion); break;
            case Type.explosion: drawPlosion(InternalImage.explosion); break;
            case Type.particle: drawParticle(); break;
        }
    }

private:

    void moveThenAccelerateByGravity()
    {
        foot += speed;
        if (timeToLive % 2 == 0)
            speed += Point(0, 1);
    }

    void calcArrow()
    {
        // doesn't use speedY at all
        auto a = arrowTimeToLive - timeToLive - 3;
        assert (a >= -2, "already deducted 1 from TTL in Debris.calc()");
        foot -= Point(0,
              a == -2 ? 8
            : a == -1 ? 4
            : a ==  0 ? 2
            : a ==  1 || a == 2 || a == 4 || a == 8 || a == 16 ? 1
            : 0);
    }

    void calcFlyingTool()
    {
        moveThenAccelerateByGravity();
        // The first 4 + is to produce positive values even with negative speed
        rotCw = fmod(4 + rotCw + speed.x * 0.03125f, 4);
    }

    void calcParticle()
    {
        moveThenAccelerateByGravity();
    }

    void drawArrow()
    {
        auto cbA = InternalImage.gameArrow.toCutbit;
        auto cbI = getSkillButtonIcon(style);
        cbA.draw(foot - Point(cbA.xl/2, cbA.yl));
        cbI.draw(foot - Point(cbI.xl/2, cbA.yl*15/16), frame);
    }

    void drawFlyingTool()
    {
        auto cb = InternalImage.debris.toCutbit;
        cb.draw(foot - Point(cb.xl/2, cb.yl/2),
                clamp(cb.xfs - timeToLive/4, 0, cb.xfs - 1),
                frame, false, rotCw);
    }

    void drawPlosion(in InternalImage id)
    {
        auto cb = id.toCutbit;
        cb.draw(foot - Point(cb.xl/2, cb.yl/2 + explodeMaskOffsetY),
                clamp(cb.xfs - timeToLive, 0, cb.xfs - 1));
    }

    void drawParticle() { }
}
// end struct Debris
