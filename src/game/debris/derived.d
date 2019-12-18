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
        auto cbI = getSkillButtonIcon(style);
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



abstract class FlyingTool : GravityDebris {
private:
    int yf;
    float rotCw; // clockwise rotational position 0 <= x < 4. Not speed.

protected:
    enum framePickaxe = 0;

public:
    static const(Cutbit) cb()
    {
        return InternalImage.debris.toCutbit;
    }

    this(in Point foot, in int dir, in int toolFrame)
    {
        super(foot + Point(10 * dir, 0), uniform(40, 90));
        speed = Point(uniform(1, 6) * dir, uniform(-11, -7));
        yf = toolFrame;
        // Left-facing pickaxe starts with nonzero rotation.
        // Right-facing pickaxe starts in its default rotation 0.
        rotCw = (dir < 0 && toolFrame == framePickaxe) ? 1f : 0f;
    }

protected:
    final override void on3Calc()
    {
        // The first 4 + is to produce positive values even with negative speed
        rotCw = fmod(4 + rotCw + speed.x * 0.03125f, 4);
    }

    final override void onDraw()
    {
        cb.draw(foot - Point(cb.xl/2, cb.yl/2),
                clamp(cb.xfs - timeToLive/4, 0, cb.xfs - 1),
                frame, false, rotCw);
    }
}

final class Pickaxe : FlyingTool {
public:
    this(in Point foot, in int dir) {
        super(foot, dir, super.framePickaxe);
    }
}
