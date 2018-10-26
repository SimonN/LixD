module lix.fuse;

import std.math;

import basics.alleg5;
import basics.globals;
import basics.matrix;
import basics.help;
import basics.rect;
import graphic.color;
import graphic.internal;
import lix;

void handlePloderTimer(Lixxie li, OutsideWorld* ow)
{
    assert (ow);
    assert (li.ac != Ac.imploder);
    assert (li.ac != Ac.exploder);

    if (li.ploderTimer == 0)
        return;

    if (li.healthy) {
        // multiplayer has ploder countdown, singleplayer is instant
        if (ow.state.numTribes <= 1 || li.ploderTimer == Lixxie.ploderDelay)
            li.becomePloder(ow);
        else
            li.ploderTimer = li.ploderTimer + 1;
            // 0 -> 1 -> 2 happens in the same frame, therefore don't
            // trigger explosion immediately after reaching ploderDelay
    }
    else {
        // This is purely cosmetics. If we're drowning, we should still
        // show a fuse, but never explode anymore.
        li.ploderTimer = li.ploderTimer + li.frame + 2;
        if (li.ploderTimer > Lixxie.ploderDelay)
            li.ploderTimer = 0;
    }
}

void drawFuse (in Lixxie lixxie) { drawFuseOrFlame!false(lixxie); }
void drawFlame(in Lixxie lixxie) { drawFuseOrFlame!true (lixxie); }

void drawAbilities(in Lixxie lixxie, bool highlit = false) { with (lixxie)
{
    if (! healthy || ploderTimer > 0
        || ! (abilityToRun || abilityToClimb || abilityToFloat))
        return;

    const cb = getInternal(fileImageAbility);
    Point topLeft = Point(
        lixxie.eyeOnMap.x - (cb.xl + 1) / 2 + 1 * facingLeft,
        locCutbit.y - cb.yl/3);
    void printIf(in bool condition, in int frame)
    {
        if (! condition)
            return;
        cb.draw(topLeft, frame + facingLeft * cb.xfs / 2, highlit);
        topLeft.y -= cb.yl + 1;
    }
    printIf(lixxie.abilityToFloat, 2);
    printIf(lixxie.abilityToRun, 0);
    printIf(lixxie.abilityToClimb, 1);
}}

// ############################################################################

private:

Point eyeOnMap(in Lixxie lixxie)
{
    Point eyeOnSprite = eyesOnSpritesheet.get(lixxie.xf, lixxie.yf);
    if (lixxie.facingLeft)
        eyeOnSprite.x = lixxie.cutbit.xl - eyeOnSprite.x;
    return eyeOnSprite + lixxie.locCutbit;
}

void drawFuseOrFlame(bool fuseIfFalseFlameIfTrue)(in Lixxie lixxie)
{
    if (lixxie.ploderTimer == 0)
        return;
    version (tharsisprofiling)
        static if (! fuseIfFalseFlameIfTrue) {
            import hardware.tharsis;
            import std.string;
            auto zo = Zone(profiler, "fuse %d".format(lixxie.ploderTimer/10));
        }
    const eye = eyeOnMap(lixxie);
    const tip = eye.y - 18 + roundInt(18 * (1.0 * lixxie.ploderTimer
                                                / Lixxie.ploderDelay)^^2);
    version (assert) {
        immutable a = roundInt(18 * (1.0 * lixxie.ploderTimer
                                         / Lixxie.ploderDelay)^^2);
        import std.format;
        string msg() {
            return "ploder timer out of range, a=%d".format(a)
            ~ " ploderTimer=%d".format(lixxie.ploderTimer)
            ~ " activity=%s".format(lixxie.ac);
        }
        assert (a >= 0, msg);
        assert (a <= 18, msg);
        assert (lixxie.ploderTimer > 0, msg);
        assert (lixxie.ploderTimer <= lixxie.ploderDelay, msg);
    }
    Point wiggle(int y)
    {
        assert (y >= tip);
        assert (y <= eye.y);
        return Point(eye.x + roundInt(
            sin(lixxie.ploderTimer * 0.6f) * 0.02 * (y - eye.y)^^2), y);
    }
    static if (! fuseIfFalseFlameIfTrue) {
        // Draw the fuse element bitmap many times to create a fuse
        const fuse = getInternal(fileImageFuse);
        al_hold_bitmap_drawing(true);
        for (int y = eye.y - 1; y >= tip; --y)
            fuse.draw(wiggle(y) - Point(1, 0));
        al_hold_bitmap_drawing(false);
    }
    else static if (fuseIfFalseFlameIfTrue) {
        const flame = getInternal(fileImageFuseFlame);
        flame.draw(wiggle(tip) - flame.len/2,
                   lixxie.ploderTimer % flame.xfs, 0);
    }
}
