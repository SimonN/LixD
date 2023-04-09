module lix.skill.cuber;

import lix;
import physics;

class Cuber : Leaver {
public:
    enum cubeSize = 16;

    override PhyuOrder updateOrder() const { return PhyuOrder.adder; }

    override void onBecomeLeaver(in Job old)
    {
        if (lixxie.facingLeft) {
            lixxie.turn(); // moveAhead() makes the two directions balanced,
            lixxie.moveAhead(); // like hatch spawn positions' moveAhead().
        }
    }

    override void perform()
    {
        if (frame >= 2) {
            TerrainAddition tc;
            tc.update = lixxie.outsideWorld.state.age;
            tc.type   = TerrainAddition.Type.cube;
            tc.style  = lixxie.style;
            tc.x      = lixxie.ex - cubeSize/2;

            assert (lixxie.isLastFrame == (frame == 5),
                "the following ?: is written assuming frame 5 is last");
            tc.cubeYl = lixxie.isLastFrame ? cubeSize : 2 * lixxie.frame - 2;
            assert (tc.cubeYl > 0);

            tc.y = lixxie.ey - tc.cubeYl + 2;
            lixxie.outsideWorld.physicsDrawer.add(tc);
        }
        super.advanceFrameAndLeave();
    }
}
