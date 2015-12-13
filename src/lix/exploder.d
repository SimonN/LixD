module lix.exploder;

import game.mask;
import game.terchang;
import lix;

abstract class Ploder : PerformedActivity {

    enum updatesForBomb = 75;

    override @property bool blockable()                 const { return false; }
    override @property bool callBecomeAfterAssignment() const { return false; }
    override UpdateOrder    updateOrder() const { return UpdateOrder.flinger; }

    static void handleUpdatesSinceBomb(Lixxie li)
    {
        assert (li.ac != Ac.exploder);
        assert (li.ac != Ac.exploder2);

        if (li.updatesSinceBomb == 0)
            return;

        if (li.healthy) {
            if (li.outsideWorld.state.tribes.length == 1
                || li.updatesSinceBomb == updatesForBomb
            ) {
                li.become(li.exploderKnockback ? Ac.exploder2 : Ac.exploder);
            }
            else {
                ++li.updatesSinceBomb;
                // 0 -> 1 -> 2 happens in the same frame, therefore don't
                // trigger explosion immediately after reaching updatesForBomb
            }
        }
        else {
            if (li.updatesSinceBomb > updatesForBomb)
                li.updatesSinceBomb = 0;
            else
                li.updatesSinceBomb = li.updatesSinceBomb + li.frame + 1;
        }
    }

    final override void onManualAssignment()
    {
        assert (lixxie.updatesSinceBomb == 0);
        ++lixxie.updatesSinceBomb;
        lixxie.exploderKnockback = (ac == Ac.exploder2);
    }

    // onBecome(): Do nothing, instead wait until we do performActivity(),
    // which is called immediately after this in the game loop.
    // During onBecome(), we lack outsideWorld; Ploders are special herefore.
    final override void onBecome() { }

    final override void performActivity()
    {
        changeTerrain();
        flingOtherLix();
        makeEffect();
        lixxie.become(Ac.nothing);
    }

protected:

    abstract void changeTerrain();
             void flingOtherLix() { }
    abstract void makeEffect();

    final void defaultTerrainChange(
        in TerrainChange.Type type, in int tcx, in int tcy
    ) {
        TerrainChange tc;
        tc.update = lixxie.outsideWorld.state.update;
        tc.type   = TerrainChange.Type.implode;
        tc.x      = tcx;
        tc.y      = tcy;
        lixxie.outsideWorld.physicsDrawer.add(tc);
    }

}



class Imploder : Ploder {

    enum offsetX = game.mask.masks[TerrainChange.Type.implode].offsetX;
    enum offsetY = game.mask.masks[TerrainChange.Type.implode].offsetY;

    mixin(CloneByCopyFrom!"Imploder");

protected:

    override void changeTerrain()
    {
        defaultTerrainChange(TerrainChange.Type.implode, offsetX, offsetY);
    }

    override void makeEffect()
    {
        outsideWorld.effect.addImplosion(
            outsideWorld.state.update,
            outsideWorld.tribeID,
            outsideWorld.lixID, ex, ey);
    }

}



class Exploder : Ploder {

    enum offsetX = game.mask.masks[TerrainChange.Type.explode].offsetX;
    enum offsetY = game.mask.masks[TerrainChange.Type.explode].offsetY;

    mixin(CloneByCopyFrom!"Exploder");

protected:

    override void changeTerrain()
    {
        defaultTerrainChange(TerrainChange.Type.explode, offsetX, offsetY);
    }

    override void makeEffect()
    {
        outsideWorld.effect.addExplosion(
            outsideWorld.state.update,
            outsideWorld.tribeID,
            outsideWorld.lixID, ex, ey);
    }

    override void flingOtherLix()
    {
    // x = ex, y = ey - 6 was the center of the removed disc
    /+
    // Knockback
    // Fuer komische Werte siehe alle Kommentare zum lustigen Hochfliegen.
    const double range      = radius * 2.5 + 0.5;
    for (Tribe::It titr = cs.tribes.begin(); titr != cs.tribes.end(); ++titr)
     for (LixIt i = titr->lixvec.begin(); i != titr->lixvec.end(); ++i) {
        // Ausnahme:
        if (i->get_leaving()) continue;
        // Mehr lustiges Hochfliegen durch die 10 tiefere Explosion!
        const int dx = map.distance_x(x,      i->get_ex());
        const int dy = map.distance_y(y + 10, i->get_ey());
        const double distancesquare = map.hypotsquare(dx, dy, 0, 0);
        if (distancesquare <= range * range) {
            const double dist = std::sqrt(distancesquare);
            int sx = 0;
            int sy = 0;
            if (dist > 0) {
                const double strength_x   = 350;
                const double strength_y   = 330;
                const int    center_const =  20;
                sx = (int) (strength_x * dx / (dist * (dist + center_const)) );
                sy = (int) (strength_y * dy / (dist * (dist + center_const)) );
            }
            const bool same_tribe = (&t == &*titr);
            // the upcoming -5 are for even more jolly flying upwards!
            // don't splat too easily from flinging, degrade this bonus softly
            if      (sy > -10) sy += -5;
            else if (sy > -20) sy += (-20 - sy) / 2;
            i->add_fling(sx, sy, same_tribe);
        }
    }
    +/
    }

}
