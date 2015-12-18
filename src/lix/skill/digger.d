module lix.skill.digger;

import game.physdraw;
import game.terchang;
import lix;

class Digger : PerformedActivity {

    enum tunnelWidth = 18;

    // The upstroke takes out extra terrain above the normal digging mask
    // on the first swing.
    bool upstrokeDone;

    mixin(CloneByCopyFrom!"Digger");
    protected void copyFromAndBindToLix(in Digger rhs, Lixxie lixToBindTo)
    {
        super.copyFromAndBindToLix(rhs, lixToBindTo);
        upstrokeDone = rhs.upstrokeDone;
    }

    override UpdateOrder updateOrder() const { return UpdateOrder.remover; }



    // If true, return from caller immediately
    private bool hitEnoughSteel()
    {
        // Stop digging at steel both left and right, or in the 3 double pixels
        // of the center (overlap of left and right here).
        immutable int  steelLeft   = countSteel(-8, 2, 3, 2);
        immutable int  steelRight  = countSteel(-2, 2, 9, 2);
        immutable bool enoughSteel = steelLeft > 0 && steelRight > 0;
        if (enoughSteel) {
            outsideWorld.effect.addDigHammer(
                outsideWorld.state.update,
                outsideWorld.tribeID,
                outsideWorld.lixID, ex, ey);
            become(Ac.walker);
        }
        return enoughSteel;
    }

    private bool shouldFall()
    {
        bool fall = ! isSolid(-2, 2) && ! isSolid(0, 2) && ! isSolid(2, 2);
        if (fall)
            become(Ac.faller);
        return fall;
    }



    override void performActivity()
    {
        advanceFrame();

        if (frame != 12) {
            if (shouldFall)
                return;
        }
        else {
            int rowsToDig;
            while (rowsToDig < 4) {
                if (hitEnoughSteel)
                    break;
                ++rowsToDig;
                moveDown(1);
                if (shouldFall)
                    break;
            }
            if (rowsToDig > 0) {
                immutable int plusUpstroke = (upstrokeDone ? 0 : 4);
                // we have already moved down by rowsToDig through this earth
                removeRowsYInterval(2 - rowsToDig - plusUpstroke,
                                        rowsToDig + plusUpstroke);
            }
            upstrokeDone = true;
        }
    }

    private void removeRowsYInterval(in int y, in int yl)
    {
        TerrainChange tc;
        tc.update = outsideWorld.state.update;
        tc.type   = TerrainChange.Type.dig;
        tc.x      = ex - 8;
        tc.y      = ey + y;
        tc.yl     = yl;
        outsideWorld.physicsDrawer.add(tc);
    }

}
// end class Digger
