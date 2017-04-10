module lix.skill.exploder;

import std.math; // sqrt

import basics.help; // roundInt
import basics.globals;
import basics.rect;
import game.mask;
import game.terchang;
import graphic.internal;
import lix;

void drawFuse(in Lixxie lixxie)
{
    assert (lixxie.ploderTimer > 0);
    version (tharsisprofiling) {
        import hardware.tharsis;
        import std.string;
        auto zo = Zone(profiler, "lix fuse=%d".format(lixxie.ploderTimer));
    }
    const fuse = getInternal(fileImageFuseFlame);
    // DTODO: Examine the skillsheet for where the eye is.
    const head = Point(lixxie.ex, lixxie.ey - 14);
    const tip = head - Point(0, (Ploder.ploderDelay - lixxie.ploderTimer) / 4);
    fuse.draw(tip - fuse.len/2, lixxie.ploderTimer % fuse.xfs, 0);
}

abstract class Ploder : Job {

    enum ploderDelay = 75;

    override @property bool blockable()                 const { return false; }
    override @property bool callBecomeAfterAssignment() const { return false; }
    override PhyuOrder    updateOrder() const { return PhyuOrder.flinger; }

    static void handlePloderTimer(Lixxie li, OutsideWorld* ow)
    {
        assert (ow);
        assert (li.ac != Ac.imploder);
        assert (li.ac != Ac.exploder);

        if (li.ploderTimer == 0)
            return;

        if (li.healthy) {
            // multiplayer has ploder countdown, singleplayer is instant
            if (ow.state.tribes.length <= 1 || li.ploderTimer == ploderDelay)
                li.becomePloder(ow);
            else
                li.ploderTimer = li.ploderTimer + 1;
                // 0 -> 1 -> 2 happens in the same frame, therefore don't
                // trigger explosion immediately after reaching ploderDelay
        }
        else {
            if (li.ploderTimer > ploderDelay)
                li.ploderTimer = 0;
            else
                li.ploderTimer = li.ploderTimer + li.frame + 1;
        }
    }

    final override void onManualAssignment()
    {
        assert (lixxie.ploderTimer == 0);
        lixxie.ploderTimer = lixxie.ploderTimer + 1;
        lixxie.ploderIsExploder = (ac == Ac.exploder);
    }

    // onBecome(): Do nothing, instead wait until we do perform(),
    // which is called immediately after this in the game loop.
    // During onBecome(), we lack outsideWorld; Ploders are special herefore.
    final override void onBecome() { }

    final override void perform()
    {
        changeTerrain();
        flingOtherLix();
        makeEffect();
        lixxie.become(Ac.nothing);
    }

protected:
             void flingOtherLix() { }
    abstract void makeEffect();

private:
    final void changeTerrain()
    {
        assert (ac == Ac.imploder || ac == Ac.exploder);
        TerrainDeletion tc;
        tc.update = lixxie.outsideWorld.state.update;
        tc.type   = (ac == Ac.exploder) ? TerrainDeletion.Type.explode
                                        : TerrainDeletion.Type.implode;
        tc.x      = - masks[tc.type].offsetX + lixxie.ex;
        tc.y      = - masks[tc.type].offsetY + lixxie.ey;
        lixxie.outsideWorld.physicsDrawer.add(tc);
    }
}



class Imploder : Ploder {

    mixin(CloneByCopyFrom!"Imploder");

protected:
    override void makeEffect()
    {
        outsideWorld.effect.addImplosion(outsideWorld.state.update, style,
                                         outsideWorld.lixID, ex, ey);
    }
}



class Exploder : Ploder {

    mixin(CloneByCopyFrom!"Exploder");

protected:
    override void makeEffect()
    {
        outsideWorld.effect.addExplosion(outsideWorld.state.update, style,
                                         outsideWorld.lixID, ex, ey);
    }

    override void flingOtherLix()
    {
        foreach (targetTribe; outsideWorld.state.tribes)
            foreach (target; targetTribe.lixvec)
                if (target.healthy)
                    flingOtherLix(target, targetTribe.style == this.style);
    }

private:
    void flingOtherLix(Lixxie target, in bool targetTribeIsOurTribe)
    {
        immutable dx = env.distanceX(ex,     target.ex);
        immutable dy = env.distanceY(ey + 4, target.ey);
        // +4 moves makes dy positive if target.ey == this.ey,
        // it's desirable to fling such targets up a little

        immutable double distSquared  = dx*dx + dy*dy;
        enum      double rangeSquared = (23 * 2.5 + 0.5)^^2;
        // 23 was the radius in C++ of the flingploder's terrain removal.
        // Look up the terrain mask in game.mask for further detail.

        if (distSquared <= rangeSquared) {
            double sx = 0;
            double sy = 0;
            if (distSquared > 0) {
                enum strengthX   = 350;
                enum strengthY   = 330;
                enum centerConst =  20;
                // DTODOSKILLS: Find a formula that doesn't need the square
                // root and gives a different, but also OK-looking result
                immutable dist = distSquared.sqrt;
                sx = strengthX * dx / (dist * (dist + centerConst));
                sy = strengthY * dy / (dist * (dist + centerConst));
            }
            // the upcoming -5 are for even more jolly flying upwards!
            // don't splat too easily from flinging, degrade this bonus softly
            if      (sy > -10) sy += -5;
            else if (sy > -20) sy += (-20 - sy) / 2;
            target.addFling(sx.roundInt, sy.roundInt, targetTribeIsOurTribe);
        }
    }
}
