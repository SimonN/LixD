module lix.skill.digger;

import game.physdraw;
import game.terchang;
import lix;

class Digger : Job {

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

    override PhyuOrder updateOrder() const { return PhyuOrder.remover; }

    // If true, return from caller immediately
    private bool hitEnoughSteel()
    {
        enum midLoRes = 5; // stop if steel in the middle N of 9 lo-res pixels
        immutable bool enoughSteel = countSteel(1-midLoRes, 2, midLoRes, 2) >0;
        if (enoughSteel) {
            if (outsideWorld.effect)
                outsideWorld.effect.addDigHammer(outsideWorld.state.update,
                    style, outsideWorld.lixID, ex, ey, dir);
            become(Ac.walker);
        }
        return enoughSteel;
    }

    private bool fallHere()
    {
        bool fall = ! isSolid(-2, 2) && ! isSolid(0, 2) && ! isSolid(2, 2);
        if (fall)
            become(Ac.faller);
        return fall;
    }

    override void perform()
    {
        advanceFrame();

        if (frame != 12) {
            if (fallHere)
                return;
        }
        else {
            int rowsToDig;
            while (rowsToDig < 4) {
                if (hitEnoughSteel)
                    break;
                ++rowsToDig;
                moveDown(1);
                if (fallHere)
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
        TerrainDeletion tc;
        tc.update = outsideWorld.state.update;
        tc.type   = TerrainDeletion.Type.dig;
        tc.x      = ex - 8;
        tc.y      = ey + y;
        tc.digYl  = yl;
        outsideWorld.physicsDrawer.add(tc);
    }
}
// end class Digger
