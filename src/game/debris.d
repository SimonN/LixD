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

import basics.globals;
import file.filename;
import graphic.color;
import graphic.gralib;
import graphic.torbit;
import lix.enums;

// not a class, I'd like to avoid GC for many flying pixels
struct Debris {

    enum Type {
        arrow,
        flyingTool,
        implosion,
        explosion,
        particle,
    }

    enum arrowTimeToLive = 50;

    const(Type) type;
    int timeToLive;
    int x, y;
    int speedX, speedY;
    int frame; // yf for flying tools, xf for the Ac on arrows
    union {
        Style style; // for arrows
        AlCol col;   // for particles
    }

    static auto newArrow(in int ex, in int ey, in Style style, in int xf)
    {
        auto ret = typeof(this)(Type.arrow);
        ret.timeToLive = arrowTimeToLive;
        ret.style = style;
        ret.frame = xf;
        auto cb = getInternal(fileImageGameArrow);
        ret.x = ex - cb.xl / 2;
        ret.y = ey - cb.yl;
        return ret;
    }

    static auto newImplosion(in int ex, in int ey) { return Debris(); }
    static auto newExplosion(in int ex, in int ey) { return Debris(); }

    void calc()
    {
        --timeToLive;
        final switch (type) {
            case Type.arrow:      calcArrow();      break;
            case Type.flyingTool: calcFlyingTool(); break;
            case Type.implosion:  calcPlosion();    break;
            case Type.explosion:  calcPlosion();    break;
            case Type.particle:   calcParticle();   break;
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

    void moveThenAccelerateBy(in int accelY)
    {
        x += speedX;
        y += speedY;
        speedY += accelY;
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

    void calcFlyingTool() { }
    void calcPlosion()    { }
    void calcParticle()   { }

    void drawArrow(Torbit ground)
    {
        auto cbA = getInternal(fileImageGameArrow);
        auto cbI = getSkillButtonIcon(style);
        cbA.draw(ground, x, y);
        cbI.draw(ground, x + cbA.xl/2 - cbI.xl/2,
                         y + cbA.yl/8 - cbI.yl/8, frame);
    }

    void drawFlyingTool(Torbit ground) { }
    void drawPlosion(Torbit ground, in Filename) { }
    void drawParticle(Torbit ground) { }
}
// end struct Debris
