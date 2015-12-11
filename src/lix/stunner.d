module lix.stunner;

import hardware.sound;
import lix;

class Stunner : PerformedActivity {

    int stayedInFrame8;

    mixin(CloneByCopyFrom!"Stunner");
    protected void copyFromAndBindToLix(in Stunner rhs, Lixxie lixToBindTo)
    {
        super.copyFromAndBindToLix(rhs, lixToBindTo);
        stayedInFrame8 = rhs.stayedInFrame8;
    }

    override void onBecome()
    {
        if (cast (BallisticFlyer) lixxie.performedActivity)
            playSound(Sound.OUCH);
    }



    override void performActivity()
    {
        // remain in frame 8 for several frames, to match L2 stunner duration
        bool considerBecomingWalker = false;
        if (frame == 8) {
            ++stayedInFrame8;
            if (stayedInFrame8 == 17)
                advanceFrame();
        }
        else if (isLastFrame)
            considerBecomingWalker = true;
        else
            advanceFrame();

        int moveDownBy = 0;
        enum maxDown = 4; // digger shall not cause eternal stunning
        for (int i = 2; i < 2 + maxDown; ++i) {
            if (! isSolid(0, -i)) ++moveDownBy;
            else                  break;
        }
        if (moveDownBy == maxDown && ! isSolid(0, 2 + moveDownBy)) {
            moveDown(1);
            become(Ac.tumbler);
            Tumbler tumbling = cast (Tumbler) lixxie.performedActivity;
            assert (tumbling !is null);
            tumbling.speedX = 0;
            tumbling.speedY = 2;
        }
        else if (moveDownBy > 0) {
            moveDown(moveDownBy);
        }

        if (this is lixxie.performedActivity && considerBecomingWalker)
            become(Ac.walker);
    }

}
