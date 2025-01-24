module game.debris.derived;

import std.algorithm;
import std.conv;
import std.math;
import std.random;

import basics.rect;
import game.debris.base;
import graphic.color;
import graphic.cutbit;
import graphic.internal;
import net.ac;
import net.style;
import physics.mask; // exploder offset

package:

class Arrow : TimedLifeDebris {
private:
    Style style;
    int xf;

public:
    enum arrowTimeToLive = 50;

    this(in Point aFoot, in Style aStyle, in Ac ac)
    {
        super(aFoot, arrowTimeToLive);
        xf = ac.acToSkillIconXf;
        style = aStyle;
    }

protected:
    final override void onOnCalc()
    {
        auto a = arrowTimeToLive - timeToLive - 3;
        assert (a >= -2, "already deducted 1 from TTL in DebrisBase.calc()");
        foot -= Point(0,
              a == -2 ? 8
            : a == -1 ? 4
            : a ==  0 ? 2
            : a ==  1 || a == 2 || a == 4 || a == 8 || a == 16 ? 1
            : 0);
    }

    final override void onDraw()
    {
        auto cbA = InternalImage.gameArrow.toCutbit;
        auto cbI = Spritesheet.skillsInPanel.toCutbitFor(style);
        cbA.draw(foot - Point(cbA.xl/2, cbA.yl));
        cbI.draw(foot - Point(cbI.xl/2, cbA.yl*15/16), xf);
    }
}

class PlosionCenter : TimedLifeDebris {
protected:
    abstract const(Cutbit) cb() const;

public:
    // If bonusTtl > 0, then we show the first frame for longer than normal.
    this(in Point aFoot, in int bonusTtl) { super(aFoot, cb.xfs + bonusTtl); }

protected:
    override void onDraw()
    {
        cb.draw(foot - Point(cb.xl/2, cb.yl/2 + explodeMaskOffsetY),
            clamp(cb.xfs - timeToLive, 0, cb.xfs - 1));
    }
}

final class ImplosionCenter : PlosionCenter {
protected:
    override const(Cutbit) cb() const
    {
        return InternalImage.implosion.toCutbit;
    }

public:
    this(in Point aFoot) { super(aFoot, 0); }
}

class ImplosionParticle : TimedLifeDebris {
private:
    float angle; // measured in radians: Adding/subtracting tau is nop.
    immutable int yf;

    enum maxTtl = 60;

public:
    enum float tau = to!float(2*PI);

    this(in Point aFoot, in float aAngle)
    {
        super(aFoot, uniform(maxTtl/2, maxTtl));
        angle = aAngle;
        yf = uniform(8, 10); // either 8 or 9
    }

protected:
    override void onOnCalc()
    {
        angle += 0.12f;
    }

    override void onDraw()
    {
        const(Cutbit) cb = InternalImage.debris.toCutbit;
        cb.draw(drawAt - Point(cb.xl/2, cb.yl/2),
            clamp(cb.xfs - timeToLive/2, 0, cb.xfs - 1),
            yf);
    }

private:
    float distanceFromCenter() const
    {
        return 0.05f * timeToLive * (timeToLive - maxTtl);
    }

    Point drawAt() const
    {
        return Point(
            foot.x + to!int(cos(angle) * distanceFromCenter),
            foot.y + to!int(sin(angle) * distanceFromCenter));
    }
}




final class ExplosionCenter : PlosionCenter {
protected:
    override const(Cutbit) cb() const
    {
        return InternalImage.explosion.toCutbit;
    }

public:
    this(in Point aFoot) { super(aFoot, 2); }
}



class FlyingTool : GravityDebris {
private:
    int yf;
    float rotCw; // clockwise rotational position 0 <= x < 4. Not speed.

public:
    /*
     * The values of these enums are exactly the y frame numbers in debris.png.
     * E.g., shovel = 4 means that this piece of debris is in the 5th row.
     */
    enum Type {
        pickaxe = 0,
        jackhammerFoot = 1,
        jackhammerHandle = 2,
        jackhammerEngine = 3,
        shovel = 4,
    }

    static const(Cutbit) cb()
    {
        return InternalImage.debris.toCutbit;
    }

    this(in Point foot, in int dir, in Type whichTool)
    {
        immutable forward = Point(dir, 1);
        super(foot + forward * initialOffsetFromFootFor(whichTool),
            uniform(40, 90));
        speed = forward * initialSpeedFor(whichTool);
        yf = whichTool;
        rotCw = initialRotCwFor(dir, whichTool);
    }

protected:
    final override void on3Calc()
    {
        if (speed.x > 0) {
            rotCw += 0.05f + speed.x * 0.02f;
        }
        else {
            rotCw += 4f - 0.05f + speed.x * 0.02f;
        }
        if (rotCw >= 4f) {
            rotCw -= 4f;
        }
    }

    final override void onDraw()
    {
        cb.draw(foot - Point(cb.xl/2, cb.yl/2),
                clamp(cb.xfs - timeToLive/4, 0, cb.xfs - 1),
                yf, false, rotCw);
    }

private:
    static float initialRotCwFor(in int dir, in Type tool
    ) pure nothrow @safe @nogc
    {
        final switch (tool) {
            // Left-facing pickaxe starts with nonzero rotation: 1f.
            // Right-facing pickaxe starts in its default rotation: 0f.
            case Type.pickaxe: return dir < 0;
            case Type.jackhammerFoot: return 0;
            case Type.jackhammerHandle: return 0;
            case Type.jackhammerEngine: return 0;
            case Type.shovel:
                /*
                 * Start the shovel rotated diagonally backward. This makes
                 * sense: The basher holds it over her back before throwing it.
                 *                      .                .
                 * 0f = -->       2.5f = \       3.5f = /
                 *       from right-facing       from right-facing
                 */
                return 2.6f + 0.8f * (dir < 0);
        }
    }

    static Point initialOffsetFromFootFor(in Type tool
    ) pure nothrow @safe @nogc
    {
        final switch (tool) {
            case Type.pickaxe: return Point(10, 0);
            case Type.jackhammerFoot: return Point(0, 0);
            case Type.jackhammerHandle: return Point(0, -10);
            case Type.jackhammerEngine: return Point(0, -5);
            case Type.shovel: return Point(0, -20);
        }
    }

    static Point initialSpeedFor(in Type tool) @safe
    {
        final switch (tool) {
            case Type.pickaxe:
                return Point(uniform(2, 6), uniform(-11, -7));
            case Type.jackhammerFoot:
                return Point(uniform(4, 6), uniform(-6, -4));
            case Type.jackhammerHandle:
                return Point(uniform(-6, -2), uniform(-9, -6));
            case Type.jackhammerEngine:
                return Point(uniform(1, 3), uniform(-8, -5));
            case Type.shovel:
                return Point(uniform(1, 3), uniform(-8, -6));
        }
    }
}
