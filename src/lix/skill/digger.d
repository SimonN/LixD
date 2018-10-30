module lix.skill.digger;

import lix;
import physics;

class Digger : Job {
private:
    bool _upstrokeDone; // Takes out terrain on first swing above normal mask

public:
    mixin JobChild;

    enum tunnelWidth = 18;

    override PhyuOrder updateOrder() const { return PhyuOrder.remover; }

    // If true, return from caller immediately
    private bool hitEnoughSteel()
    {
        enum midLoRes = 5; // stop if steel in the middle N of 9 lo-res pixels
        immutable bool enoughSteel = countSteel(1-midLoRes, 2, midLoRes, 2) >0;
        if (enoughSteel) {
            outsideWorld.effect.addDigHammer(
                outsideWorld.state.update, outsideWorld.passport, foot, dir);
            become(Ac.walker);
        }
        return enoughSteel;
    }

    private bool shouldWeFallHere() const
    {
        return ! isSolid(-2, 2) && ! isSolid(0, 2) && ! isSolid(2, 2);
    }

    override void perform()
    {
        if (isLastFrame)
            frame = 4;
        else
            advanceFrame();

        bool weWillFall = false;
        if (frame != 16) {
            // All non-digging frames
            weWillFall = shouldWeFallHere();
        }
        else {
            int rowsToDig = 0;
            while (rowsToDig < 4) {
                if (hitEnoughSteel)
                    break;
                ++rowsToDig;
                moveDown(1);
                weWillFall = shouldWeFallHere();
                if (weWillFall)
                    break;
            }
            if (rowsToDig > 0) {
                immutable int plusUpstroke = (_upstrokeDone ? 0 : 4);
                // we have already moved down by rowsToDig through this earth
                removeRowsYInterval(2 - rowsToDig - plusUpstroke,
                                        rowsToDig + plusUpstroke);
            }
            _upstrokeDone = true;
        }
        if (weWillFall)
            become(Ac.faller);
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
