module lix.skill.exploder;

/* This is about the assignment of exploders and imploders, and about
 * their final explosion.
 *
 * This is _not_ about handling the timer and drawing the fuse during
 * the countdown. See module lixxie.fuse for that.
 */

import std.math; // sqrt

import basics.help; // roundInt
import lix;
import physics.mask;
import physics.terchang;

abstract class Ploder : Leaver {
    mixin JobChild;

    override PhyuOrder updateOrder() const { return PhyuOrder.flinger; }
    override @property bool blockable() const { return false; }

    final override AfterAssignment onManualAssignment(Job old)
    {
        assert (lixxie.ploderTimer == 0);
        lixxie.ploderTimer = lixxie.ploderTimer + 1;
        lixxie.ploderIsExploder = (ac == Ac.exploder);
        return AfterAssignment.doNotBecome; // instead, game checks ploderTimer
    }

    // onBecome(): Do nothing except Leaver things. Wait until we do perform(),
    // which is called immediately after this in the game loop.
    final override void onBecomeLeaver(in Job) { }

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
    mixin JobChild;

protected:
    override void makeEffect()
    {
        outsideWorld.effect.dispatch.addImplosion(
            outsideWorld.state.update, outsideWorld.passport, foot);
    }
}



class Exploder : Ploder {
    mixin JobChild;

protected:
    override void makeEffect()
    {
        outsideWorld.effect.dispatch.addExplosion(
            outsideWorld.state.update, outsideWorld.passport, foot);
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
