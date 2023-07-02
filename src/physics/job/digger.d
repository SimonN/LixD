module physics.job.digger;

import physics.job;
import physics.terchang;

class Digger : Job {
private:
    bool _upstrokeDone; // Takes out terrain on first swing above normal mask

public:
    enum tunnelWidth = 18;

    override PhyuOrder updateOrder() const { return PhyuOrder.remover; }

    // If true, return from caller immediately
    private bool hitEnoughSteel()
    {
        enum midLoRes = 5; // stop if steel in the middle N of 9 lo-res pixels
        immutable bool enoughSteel
            = lixxie.countSteel(1 - midLoRes, 2, midLoRes, 2) > 0;
        if (enoughSteel) {
            lixxie.outsideWorld.effect.addDigHammer(
                lixxie.outsideWorld.state.age,
                lixxie.outsideWorld.passport, lixxie.foot, lixxie.dir);
            lixxie.become(Ac.walker);
        }
        return enoughSteel;
    }

    private bool shouldWeFallHere() const
    {
        return ! lixxie.isSolid(-2, 2)
            && ! lixxie.isSolid(0, 2)
            && ! lixxie.isSolid(2, 2);
    }

    override void perform()
    {
        if (lixxie.isLastFrame) {
            frame = 4;
        }
        else {
            lixxie.advanceFrame();
        }

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
                lixxie.moveDown(1);
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
            lixxie.become(Ac.faller);
    }

    private void removeRowsYInterval(in int y, in int yl)
    {
        TerrainDeletion tc;
        tc.update = lixxie.outsideWorld.state.age;
        tc.type   = TerrainDeletion.Type.dig;
        tc.x      = lixxie.ex - 8;
        tc.y      = lixxie.ey + y;
        tc.digYl  = yl;
        lixxie.outsideWorld.physicsDrawer.add(tc);
    }
}
// end class Digger
