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
            if (li.updatesSinceBomb == updatesForBomb)
                li.become(li.exploderKnockback ? Ac.exploder2 : Ac.exploder);
            else
                ++li.updatesSinceBomb;
                // 0 -> 1 -> 2 happens in the same frame, therefore don't
                // trigger explosion immediately after reaching updatesForBomb
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

    final override void onBecome()
    {
        makeTerrainChange();
        makeEffect();
        lixxie.become(Ac.nothing);
    }

    final override void performActivity()
    {
        assert (false, "lix is killed on become");
    }

protected:

    abstract void makeTerrainChange();
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

    override void makeTerrainChange()
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

    override void makeTerrainChange()
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

}
