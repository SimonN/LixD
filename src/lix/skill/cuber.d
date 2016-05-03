module lix.skill.cuber;

import game.physdraw;
import game.terchang;
import lix;

class Cuber : Leaver {

    enum cubeSize = 16;

    mixin(CloneByCopyFrom!"Cuber");

    override UpdateOrder updateOrder() const { return UpdateOrder.adder; }

    override void onBecomeLeaver()
    {
        if (facingLeft) {
            turn();      // moveAhead() makes the two directions balanced,
            moveAhead(); // just as the hatch spawn positions' moveAhead()
        }
    }

    override void perform()
    {
        if (frame >= 2) {
            TerrainAddition tc;
            tc.update = outsideWorld.state.update;
            tc.type   = TerrainAddition.Type.cube;
            tc.style  = style;
            tc.x      = ex - cubeSize/2;

            assert (isLastFrame == (frame == 5),
                "the following ?: is written assuming frame 5 is last");
            tc.cubeYl = isLastFrame ? cubeSize : 2*frame - 2;
            assert (tc.cubeYl > 0);

            tc.y = ey - tc.cubeYl + 2;
            outsideWorld.physicsDrawer.add(tc);
        }
        super.advanceFrameAndLeave();
    }

}
